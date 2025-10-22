# API e Função: Consulta de Perfil de Utilizador

Este documento detalha a arquitetura recomendada para consultar dados de perfil de um utilizador num contexto de empresa específico, utilizando uma função de banco de dados (RPC) e uma API RESTful.

## Consulta de Dados de Perfil por Utilizador e Empresa

Para buscar os dados combinados de um perfil a partir de um utilizador e empresa específicos, a abordagem ideal é criar uma função parametrizada no banco de dados.

### Passo 1: Criar Função SQL (RPC)

A função `get_profile_by_user_and_company` é criada no banco de dados para consolidar os dados necessários de várias tabelas. Ela une `memberships`, `profiles`, `auth.users`, `companies` e `departments` para retornar um objeto JSON completo.

**DDL (SQL):**
```sql
CREATE OR REPLACE FUNCTION get_profile_by_user_and_company(p_user_id uuid, p_company_id uuid)
RETURNS json
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT json_build_object(
    -- Dados do User (auth.users)
    'email', u.email,
    -- Dados do Profile (public.profiles)
    'id', p.id,
    'full_name', p.full_name,
    'avatar_url', p.avatar_url,
    'avatar_path', p.avatar_path,
    'job_title', p.job_title,
    'phone_number', p.phone_number,
    -- Dados da Membership (public.memberships)
    'membership_id', m.id,
    'membership_status', m.status,
    'has_company_wide_access', m.has_company_wide_access,
    -- Dados do Department (public.departments)
    'department_id', d.id,
    'department_name', d.name,
    -- Dados da Company (public.companies)
    'company_id', c.id,
    'company_name', c.name,
    'company_logo_url', c.logo_url,
    'company_status', c.status,
    -- Contagens de Auditoria
   'audit_sessions_count', (
  SELECT COUNT(*)
  FROM public.audit_sessions
  WHERE user_id = p_user_id
    AND company_id = p_company_id
    AND event_type = 'LOGIN_SUCCESS'
),
    'audit_logs_count', (
      SELECT COUNT(*)
      FROM public.audit_logs
      WHERE user_id = p_user_id AND company_id = p_company_id
    )
  )
  FROM
    public.memberships AS m
  JOIN
    public.profiles AS p ON m.user_id = p.id
  JOIN
    auth.users AS u ON p.id = u.id
  JOIN
    public.companies AS c ON m.company_id = c.id
  LEFT JOIN
    public.departments AS d ON m.department_id = d.id
  WHERE
    m.user_id = p_user_id AND m.company_id = p_company_id;
$$;
```

### Benefícios da Função RPC

A abordagem de criar uma função RPC no banco de dados é a mais segura e ideal por várias razões:

-   **Eficiência com Junções (JOIN):** A função consolida dados de cinco tabelas (`memberships`, `profiles`, `auth.users`, `companies`, `departments`) numa única operação, evitando múltiplas requisições entre o front-end e o banco de dados. O uso de `LEFT JOIN` para a tabela `departments` garante que a consulta funcione mesmo se um utilizador não estiver associado a um departamento.
-   **Segurança Controlada (SECURITY DEFINER):** A função é executada com as permissões do seu criador, permitindo o acesso controlado à tabela `auth.users` para buscar o e-mail. A segurança é mantida porque a cláusula `WHERE` limita estritamente a consulta aos `user_id` e `company_id` fornecidos.
-   **Abstração e Simplicidade:** A complexidade da consulta fica encapsulada no back-end. O front-end apenas precisa chamar uma função simples com dois parâmetros, tornando o código do cliente mais limpo e fácil de manter.
-   **Performance:** Executar a lógica de junção complexa diretamente no servidor de banco de dados é significativamente mais rápido do que buscar os dados de cada tabela separadamente e combiná-los no front-end.

## Passo 2: Lógica de Acesso no Front-end (API REST)

Para chamar a função SQL a partir do front-end, utilizamos a API REST nativa do Supabase.

O processo funciona da seguinte forma:

1.  **Obter Autenticação:** A sessão do utilizador logado é obtida para extrair o token de acesso (JWT).
2.  **Montar a Requisição:** É montada uma requisição `POST` para o endpoint da função no Supabase (ex: `/rest/v1/rpc/get_profile_by_user_and_company`).
3.  **Enviar Parâmetros:** Os parâmetros `user_id` e `company_id` são enviados no corpo (`body`) da requisição em formato JSON.
4.  **Incluir Cabeçalhos de Segurança:** A chave de API pública (`apikey`) e o token de acesso do utilizador (`Authorization: Bearer ...`) são incluídos nos cabeçalhos da requisição.
5.  **Receber a Resposta:** A aplicação aguarda a resposta do servidor. Se bem-sucedida, recebe o objeto JSON completo com os dados do perfil para popular a interface do utilizador.

## Lógica do Front-end para a Página de Perfil

Esta seção descreve como carregar dinamicamente os dados de um perfil com base nos parâmetros da URL.

### Fluxo de Carregamento da Página

1.  **Navegação:** O utilizador é direcionado para a página de perfil (ex: `https://seusite.com/profile?user_id=...&company_id=...`).
2.  **On Page Load:** Um script é executado assim que a página carrega.
3.  **Captura dos Parâmetros:** O script lê os valores de `user_id` e `company_id` da URL.
4.  **Chamada da Função:** O script chama a função `fetchProfileByUserAndCompany`, passando os parâmetros capturados.
5.  **Armazenamento dos Dados:** O resultado (o objeto JSON) é armazenado numa variável de estado ou local.
6.  **Renderização do Componente:** O componente reutilizável (`compProfile`) usa os dados armazenados para preencher os campos do formulário.
