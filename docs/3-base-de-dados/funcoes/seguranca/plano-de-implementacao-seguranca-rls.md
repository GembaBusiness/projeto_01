# Documento de Arquitetura: Plano de Implementação da Segurança Multi-Tenant com RLS

**Versão:** 2.5 (Final)

**Objetivo:** Detalhar a estratégia e a implementação da camada de segurança de dados no banco de dados Supabase (PostgreSQL), utilizando Funções Auxiliares (Helpers) e Políticas de Segurança em Nível de Linha (RLS) para garantir o isolamento total dos dados entre diferentes empresas (tenants) e a autorização granular de ações baseada em papéis (RBAC).

---

## Índice

- **Bloco 1: Introdução e Estratégia de Segurança**
  - 1.1. Objetivo da Fase
  - 1.2. A Arquitetura em Três Camadas
- **Bloco 2: Implementação das Funções Auxiliares (Helpers)**
  - 2.0. Passo Zero: Criação do Schema de Segurança
  - 2.1. Função 1: `custom_auth_helpers.current_company_id()`
  - 2.2. Função 2: `custom_auth_helpers.current_membership_attributes()`
  - 2.3. Função 3: `custom_auth_helpers.has_permission()`
- **Bloco 3: Ativação e Criação das Políticas de RLS**
  - 3.1. Estratégia de Aplicação Granular
  - 3.2. Exemplo Prático: Protegendo a Tabela `departments`
- **Conclusão e Próximos Passos**

---

## Bloco 1: Introdução e Estratégia de Segurança

### 1.1. Objetivo da Fase

O objetivo desta fase é traduzir nossa arquitetura de segurança completa em regras concretas no banco de dados. Ao final, o PostgreSQL irá, de forma automática, filtrar todas as consultas, garantindo que um usuário:

- **Isolamento de Tenant:** Só possa interagir com dados da sua empresa ativa.
- **Autorização RBAC:** Só possa executar as ações (SELECT, INSERT, UPDATE, DELETE) para as quais ele tem permissão explícita através de seus papéis (roles).

### 1.2. A Arquitetura em Três Camadas

Nossa implementação de segurança no banco de dados será dividida em três camadas lógicas e interdependentes:

1.  **Fonte de Verdade (JWT):** O token de autenticação do usuário nos fornece o contexto da sessão (`user_id` e `active_company_id`).
2.  **Funções Auxiliares (Helpers):** Funções SQL que extraem informações do JWT e consultam as tabelas de permissões para nos dar respostas claras como "qual a empresa ativa?" ou "o usuário tem a permissão X?".
3.  **Políticas de RLS (Regras):** As regras de segurança em si, que usam as funções auxiliares para definir as condições de acesso a cada linha de cada tabela.

---

## Bloco 2: Implementação das Funções Auxiliares (Helpers)

### 2.0. Passo Zero: Criação do Schema de Segurança

#### Introdução ao Código

Para evitar conflitos com os esquemas protegidos do Supabase (como `auth`), a melhor prática é criar nosso próprio esquema para armazenar as funções de segurança. O script abaixo cria um novo esquema chamado `custom_auth_helpers`, garantindo que nosso código permaneça organizado e seguro.

#### Código SQL

```sql
-- Cria o schema para nossas funções customizadas de segurança, se ele ainda não existir.
CREATE SCHEMA IF NOT EXISTS custom_auth_helpers;
```

#### Conclusão

Com nosso schema criado, agora temos um local seguro e dedicado para todas as nossas funções auxiliares, evitando problemas de permissão.

### 2.1. Função 1: `custom_auth_helpers.current_company_id()`

#### Introdução ao Código

O código a seguir cria a nossa primeira função auxiliar. Ela inspeciona o token de acesso (JWT) para encontrar o `active_company_id`. Adicionamos `SET search_path = '';` para mitigar um vetor de ataque, forçando a função a usar apenas objetos com esquemas explicitamente definidos ou funções do sistema, ignorando o `search_path` do usuário.

#### Código SQL

```sql
CREATE OR REPLACE FUNCTION custom_auth_helpers.current_company_id()
RETURNS UUID AS $$
DECLARE
    company_id_claim UUID;
BEGIN
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'active_company_id', '')::UUID
    INTO company_id_claim;
    RETURN company_id_claim;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

GRANT EXECUTE ON FUNCTION custom_auth_helpers.current_company_id() TO authenticated;
```

#### Conclusão

Com esta função criada, qualquer outra parte do nosso sistema de segurança pode agora perguntar: "Qual é a empresa ativa para o usuário atual?". A função está segura em nosso schema `custom_auth_helpers`.

### 2.2. Função 2: `custom_auth_helpers.current_membership_attributes()`

#### Introdução ao Código

Esta função busca os atributos do usuário (`department_id`, `has_company_wide_access`) na tabela `memberships`. Para garantir a segurança, fixamos o `search_path` para incluir apenas os esquemas necessários (`public` para as tabelas e `custom_auth_helpers` para a outra função auxiliar), prevenindo ataques de "Trojan Horse".

Essencialmente, a função é uma peça chave para a segurança porque ela responde a duas perguntas fundamentais sobre o usuário que está fazendo uma requisição:

1.  **"A qual departamento este usuário pertence?"**
    A função busca o `department_id` do usuário na tabela `memberships`. Isso permite que, mais tarde, as Políticas de Segurança (RLS) possam filtrar os dados e mostrar ao usuário apenas informações que pertencem ao seu próprio departamento.

2.  **"Este usuário tem permissão para ver dados de TODOS os departamentos?"**
    É aqui que entra o atributo `has_company_wide_access`. Ele funciona como um interruptor:
    - Se for `true`, significa que o usuário tem um papel de alto nível (como administrador ou diretor) e pode ver os dados de todos os departamentos da empresa.
    - Se for `false`, o acesso do usuário é restrito, e ele só poderá ver os dados associados ao seu `department_id`.

Em resumo, essa função coleta os "atributos de acesso" do usuário para que as regras de segurança possam decidir, de forma granular, se ele tem acesso total (a toda a empresa) ou restrito (apenas ao seu departamento).

#### Código SQL

```sql
CREATE TYPE public.membership_attributes AS (
    department_id UUID,
    has_company_wide_access BOOLEAN
);

CREATE OR REPLACE FUNCTION custom_auth_helpers.current_membership_attributes()
RETURNS public.membership_attributes AS $$
DECLARE
    attributes public.membership_attributes;
BEGIN
    SELECT m.department_id, m.has_company_wide_access
    INTO attributes
    FROM public.memberships AS m
    WHERE m.user_id = auth.uid() AND m.company_id = custom_auth_helpers.current_company_id()
    LIMIT 1;
    RETURN attributes;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public', 'custom_auth_helpers';

GRANT EXECUTE ON FUNCTION custom_auth_helpers.current_membership_attributes() TO authenticated;
```

#### Conclusão

Ao executar este script, criamos um tipo de dado customizado e a função que o retorna. Agora, nossas políticas de RLS podem tomar decisões baseadas nos atributos do usuário.

### 2.3. Função 3: `custom_auth_helpers.has_permission()`

#### Introdução ao Código

Esta função, `has_permission()`, é o cérebro do nosso sistema de autorização. Seu objetivo é responder a uma pergunta simples, mas crucial: "O usuário logado tem permissão para fazer X?"

De forma didática, o processo funciona assim:

1.  **A Pergunta:** Uma Política de Segurança (RLS) pergunta à função: "Este usuário tem a permissão `departments.read`?".
2.  **A Investigação:** A função identifica o usuário logado e sua empresa ativa. Em seguida, ela consulta o banco de dados para descobrir todos os papéis (roles) que esse usuário possui (por exemplo, "Admin", "Membro da Equipe").
3.  **O Veredito:** Com base nos papéis, ela verifica a lista de todas as permissões associadas a eles. Se `departments.read` estiver nessa lista, a função retorna `true` (sim); caso contrário, retorna `false` (não).

Para otimizar o desempenho, a função é inteligente: ela guarda o resultado da primeira consulta em um cache. Assim, nas próximas vezes que a mesma permissão for verificada na mesma sessão, a resposta é instantânea, sem precisar consultar o banco de dados novamente.

Finalmente, a segurança é reforçada ao fixar o `search_path`, garantindo que a consulta sempre use as tabelas corretas, protegendo o sistema contra manipulações.

#### Código SQL

```sql
-- Remove a função antiga se ela existir
--DROP FUNCTION IF EXISTS custom_auth_helpers.has_permission(text);

-- Cria a versão corrigida e otimizada da função
CREATE OR REPLACE FUNCTION custom_auth_helpers.has_permission(permission_name text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
-- ✅ CRÍTICO: Ordem correta do search_path (mais específico para menos específico)
-- Isso previne ataques de "Trojan Horse" onde alguém poderia criar objetos maliciosos
SET search_path = public, custom_auth_helpers, auth
AS $$
DECLARE
  user_id_value uuid;
  company_id_value uuid;
  cached_permissions_json jsonb;
  has_perm boolean;
BEGIN
  -- ✅ VALIDAÇÃO 1: Sanitiza a entrada para prevenir SQL injection
  -- Permite apenas letras, números, underscores e pontos (formato: "resource.action")
  IF permission_name IS NULL OR permission_name !~ '^[a-zA-Z0-9_\.]+$' THEN
    RAISE WARNING 'Invalid permission name format: %', permission_name;
    RETURN false;
  END IF;

  -- ✅ VALIDAÇÃO 2: Obtém e valida o user_id
  user_id_value := auth.uid();
  IF user_id_value IS NULL THEN
    RETURN false;  -- Usuário não autenticado
  END IF;

  -- ✅ VALIDAÇÃO 3: Obtém e valida o company_id
  company_id_value := custom_auth_helpers.current_company_id();
  IF company_id_value IS NULL THEN
    RETURN false;  -- Sem empresa ativa ou inválida
  END IF;

  -- 1. Tenta obter as permissões do cache da sessão
  BEGIN
    cached_permissions_json := current_setting('my_app.user_permissions', true)::jsonb;
  EXCEPTION
    WHEN OTHERS THEN
      cached_permissions_json := NULL;
  END;

  -- 2. Se o cache não existir, busca as permissões no banco de dados
  IF cached_permissions_json IS NULL THEN
    -- ✅ Usa schemas explícitos para máxima segurança
    SELECT jsonb_agg(p.name)
    INTO cached_permissions_json
    FROM public.memberships m
    -- Junta com a tabela de ligação 'membership_roles' para encontrar os papéis do membro
    INNER JOIN public.membership_roles mr ON mr.membership_id = m.id
    -- Junta com a tabela de ligação 'role_permissions' para encontrar as permissões dos papéis
    INNER JOIN public.role_permissions rp ON rp.role_id = mr.role_id
    -- Junta com a tabela 'permissions' para obter o nome da permissão
    INNER JOIN public.permissions p ON p.id = rp.permission_id
    -- ✅ CRÍTICO: Filtra pelo usuário E empresa para garantir isolamento multi-tenant
    WHERE m.user_id = user_id_value 
      AND m.company_id = company_id_value
      AND p.name IS NOT NULL;  -- Garante que não há permissões NULL

    -- Se o utilizador não tiver permissões, define como um array JSON vazio
    cached_permissions_json := COALESCE(cached_permissions_json, '[]'::jsonb);

    -- 3. Armazena as permissões no cache da sessão para futuras chamadas
    -- ✅ Usa bloco BEGIN/END para capturar erros de set_config
    BEGIN
      PERFORM set_config('my_app.user_permissions', cached_permissions_json::text, false);
    EXCEPTION
      WHEN OTHERS THEN
        -- Se falhar ao cachear, continua sem erro (degrada gracefully)
        NULL;
    END;
  END IF;

  -- 4. Verifica se a permissão desejada existe no cache
  has_perm := cached_permissions_json ? permission_name;

  RETURN COALESCE(has_perm, false);

EXCEPTION
  WHEN OTHERS THEN
    -- ✅ Em caso de erro inesperado, nega acesso (fail-safe)
    RAISE WARNING 'Error checking permission %: %', permission_name, SQLERRM;
    RETURN false;
END;
$$;

-- ✅ IMPORTANTE: Comentário de segurança para documentação
COMMENT ON FUNCTION custom_auth_helpers.has_permission(text) IS 
'Verifica se o usuário atual possui uma permissão específica.
SECURITY DEFINER: Executa com privilégios do dono para acessar todas as tabelas.
PROTEÇÕES: search_path fixo, validação de entrada, tratamento de erros.
CACHE: Armazena permissões na sessão para otimização.';

-- ✅ Segurança de acesso
REVOKE ALL ON FUNCTION custom_auth_helpers.has_permission(text) FROM public;
GRANT EXECUTE ON FUNCTION custom_auth_helpers.has_permission(text) TO authenticated;
```

#### Conclusão

Com esta versão final, nossa função de verificação de permissões está segura, performática e robusta. A complexidade do cache e das validações está encapsulada, mantendo as políticas de RLS simples.

---

## Bloco 3: Ativação e Criação das Políticas de RLS

### 3.1. Estratégia de Aplicação Granular

Com a função `custom_auth_helpers.has_permission()`, nossa estratégia de RLS se torna muito mais poderosa e granular. Criaremos políticas específicas para cada ação (SELECT, INSERT, UPDATE, DELETE).

### 3.2. Exemplo Prático: Protegendo a Tabela `departments`

#### Introdução ao Código

Agora que nossas funções auxiliares estão prontas, vamos colocá-las em prática. O código a seguir demonstra como proteger a tabela `departments`, aplicando políticas de RLS granulares e usando nossas novas funções.

#### Código SQL

```sql
-- 1. Ativa a RLS na tabela 'departments'
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments FORCE ROW LEVEL SECURITY;

-- Remove políticas antigas para garantir um estado limpo
DROP POLICY IF EXISTS "Usuários podem ver departamentos" ON public.departments;
DROP POLICY IF EXISTS "Usuários podem criar departamentos" ON public.departments;
DROP POLICY IF EXISTS "Usuários podem atualizar departamentos" ON public.departments;
DROP POLICY IF EXISTS "Usuários podem apagar departamentos" ON public.departments;

-- 2. Cria políticas granulares baseadas em permissões

-- Política de LEITURA (SELECT)
CREATE POLICY "Usuários podem ver departamentos"
ON public.departments FOR SELECT
TO authenticated
USING (
    company_id = custom_auth_helpers.current_company_id() AND
    custom_auth_helpers.has_permission('departments.read')
);

-- Política de CRIAÇÃO (INSERT)
CREATE POLICY "Usuários podem criar departamentos"
ON public.departments FOR INSERT
TO authenticated
WITH CHECK (
    company_id = custom_auth_helpers.current_company_id() AND
    custom_auth_helpers.has_permission('departments.create')
);

-- Política de ATUALIZAÇÃO (UPDATE)
CREATE POLICY "Usuários podem atualizar departamentos"
ON public.departments FOR UPDATE
TO authenticated
USING (
    company_id = custom_auth_helpers.current_company_id() AND
    custom_auth_helpers.has_permission('departments.update')
);

-- Política de EXCLUSÃO (DELETE)
CREATE POLICY "Usuários podem apagar departamentos"
ON public.departments FOR DELETE
TO authenticated
USING (
    company_id = custom_auth_helpers.current_company_id() AND
    custom_auth_helpers.has_permission('departments.delete')
);
```

#### Conclusão

Ao final da execução deste script, a tabela `departments` estará completamente protegida. Este modelo deve ser replicado para todas as outras tabelas que necessitam de proteção.

---

## Conclusão e Próximos Passos

Ao executar os scripts deste documento, teremos implementado uma fundação de segurança de dados robusta e escalável.

**Próximos Passos:**

1.  **Executar os Scripts SQL:** Aplique os códigos dos Blocos 2 e 3 no SQL Editor do seu projeto Supabase, na ordem apresentada.
2.  **Replicar as Políticas:** Use o exemplo da tabela `departments` como um modelo para criar as quatro políticas de RLS para as outras tabelas que contêm dados de empresas.
3.  **Testes:** Realize testes completos para validar o isolamento de dados e a autorização de ações baseada nos papéis dos usuários.
