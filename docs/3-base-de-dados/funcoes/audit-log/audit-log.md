# Guia de Implementação: Sistema de Auditoria (Supabase + WeWeb)

**Autor:** Marcus Silva, Arquiteto de Software Sênior
**Versão:** 2.8 (Política de Inserção Robusta)
**Data:** 26 de Setembro de 2025

## Objetivo

Fornecer um guia técnico passo a passo para a implementação completa do sistema de auditoria, conforme definido no Plano de Arquitetura.

## Introdução

Este documento detalha a implementação completa da lógica de trilha de auditoria do sistema. O objetivo é criar um registro abrangente das atividades para garantir segurança, conformidade e rastreabilidade. A coleta de dados é dividida em três pontos estratégicos:

*   **Alterações no Banco de Dados:** Captura automática de todas as modificações (criação, atualização e exclusão) realizadas em tabelas críticas previamente mapeadas.
*   **Ações no Frontend (WeWeb):** Registro de interações importantes executadas pelos usuários na interface, como visualização de páginas, buscas, exportações e outras ações de negócio relevantes.
*   **Eventos de Autenticação:** Monitoramento completo do ciclo de vida do usuário, incluindo login, logout, tentativas de login falhas, cadastro e recuperação de senha.

Cada passo deste guia foi projetado para ser executado em sequência. Abaixo, seguem todas as fases que explicam em detalhe como essa estrutura de auditoria funciona. Recomenda-se executar todos os scripts SQL através do Editor SQL no painel do seu projeto Supabase.

---

## Fase 1: Fundação do Banco de Dados (Estrutura de Armazenamento)

Nesta primeira fase, criaremos as tabelas que servirão como repositório seguro e performático para todos os nossos logs.

### Passo 1.1: Criar o Tipo de Evento de Sessão

Primeiro, definimos um tipo customizado (`ENUM`) para classificar os eventos de sessão. Isso garante consistência nos dados.

```sql
-- DESCRIÇÃO: Cria um tipo ENUM para garantir que os eventos de sessão sejam padronizados.
-- EXECUÇÃO: Execute este script uma única vez.
CREATE TYPE public.session_event_type AS ENUM ('LOGIN_SUCCESS', 'LOGOUT', 'LOGIN_FAILURE');
```

### Passo 1.2: Criar a Tabela `audit_sessions`

Esta tabela é um pilar fundamental da segurança e monitoramento do sistema. Ela funciona como um diário de bordo para o ciclo de vida de cada sessão de usuário, registrando eventos cruciais como logins bem-sucedidos (`LOGIN_SUCCESS`), logouts (`LOGOUT`) e, de forma muito importante, tentativas de login que falharam (`LOGIN_FAILURE`). Manter um registro detalhado desses eventos nos permite não só entender quando e como os usuários acessam o sistema, mas também identificar atividades suspeitas, como tentativas de acesso não autorizado, fornecendo uma camada essencial para a segurança da aplicação.

```sql
create table public.audit_sessions (
  id uuid not null default gen_random_uuid (),
  session_id uuid null,
  company_id uuid null,
  user_id uuid null,
  event_type public.session_event_type not null,
  ip_address inet null,
  user_agent text null,
  payload jsonb null,
  created_at timestamp with time zone not null default now(),
  severity public.severity null,
  constraint audit_sessions_pkey primary key (id),
  constraint audit_sessions_company_id_fkey foreign KEY (company_id) references companies (id) on delete CASCADE,
  constraint audit_sessions_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_audit_sessions_company_id on public.audit_sessions using btree (company_id) TABLESPACE pg_default;
create index IF not exists idx_audit_sessions_user_id on public.audit_sessions using btree (user_id) TABLESPACE pg_default;
create index IF not exists idx_audit_sessions_session_id on public.audit_sessions using btree (session_id) TABLESPACE pg_default;
create index IF not exists idx_audit_sessions_created_at on public.audit_sessions using btree (created_at) TABLESPACE pg_default;

COMMENT ON COLUMN public.audit_sessions.session_id IS 'ID da sessão de auth.sessions, para correlação direta';
COMMENT ON COLUMN public.audit_sessions.payload IS 'Para detalhes extras, como motivo da falha de login';
```

### Passo 1.3: Criar a Tabela `audit_logs`

Enquanto a tabela `audit_sessions` foca nos eventos de entrada e saída (login/logout), a `audit_logs` é o coração do nosso sistema de auditoria detalhada. É aqui que cada ação específica – desde a criação de um novo departamento até a atualização de um perfil de usuário – será registrada. Esta tabela nos dará uma visão granular de "quem", "o quê" e "quando" para todas as operações críticas do sistema, servindo como a fonte principal de verdade para qualquer investigação ou análise de atividade.

```sql
-- DESCRIÇÃO: Tabela principal para todos os logs de ações detalhadas.
-- EXECUÇÃO: Execute este script uma única vez.
create table public.audit_logs (
  id bigserial not null,
  company_id uuid not null,
  user_id uuid null,
  session_id uuid null,
  action text not null,
  target_entity text null,
  target_id text null,
  payload jsonb null,
  created_at timestamp with time zone not null default now(),
  constraint audit_logs_pkey primary key (id),
  constraint audit_logs_company_id_fkey foreign KEY (company_id) references companies (id) on delete CASCADE,
  constraint audit_logs_user_id_fkey foreign KEY (user_id) references auth.users (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_audit_logs_company_id_created_at on public.audit_logs using btree (company_id, created_at desc) TABLESPACE pg_default;
create index IF not exists idx_audit_logs_user_id on public.audit_logs using btree (user_id) TABLESPACE pg_default;
create index IF not exists idx_audit_logs_session_id on public.audit_logs using btree (session_id) TABLESPACE pg_default;
create index IF not exists idx_audit_logs_action on public.audit_logs using btree (action) TABLESPACE pg_default;
create index IF not exists idx_audit_logs_payload_gin on public.audit_logs using gin (payload) TABLESPACE pg_default;

COMMENT ON COLUMN public.audit_logs.action IS 'Ação normalizada, ex: ''product.create'', ''profile.update''';
COMMENT ON COLUMN public.audit_logs.target_entity IS 'Nome da tabela ou entidade de negócio afetada, ex: ''departments''';
COMMENT ON COLUMN public.audit_logs.target_id IS 'ID (UUID, INT, etc.) do registro afetado, como texto';
```

---

## Fase 2: Lógica de Auditoria no Backend (Inteligência Central)

Nesta fase, construiremos a inteligência central do nosso sistema de auditoria. O foco aqui é o **ponto 1** da nossa estratégia: a captura automática de alterações realizadas diretamente no banco de dados. Vamos criar as funções e os gatilhos (triggers) que monitoram tabelas específicas e registram cada modificação, garantindo que nenhuma alteração passe despercebida.

### Passo 2.1: Criar a Função de Auditoria `log_audit_trail()`

Esta é a função central do nosso sistema de auditoria. Pense nela como uma "câmera de segurança" inteligente para o banco de dados. Toda vez que um registro é inserido, atualizado ou excluído em uma tabela monitorada, esta função é acionada automaticamente para capturar todos os detalhes relevantes: quem fez a alteração, quando, o que foi alterado (o valor antigo e o novo) e em qual contexto de empresa. Em seguida, ela formata esses dados e os insere na tabela `audit_logs`, criando um registro imutável da ação.

```sql
-- DESCRIÇÃO: Função central que formata e insere o log de auditoria.
-- É 'SECURITY DEFINER' para ter permissão de escrita e ler a tabela auth.sessions.
-- EXECUÇÃO: Execute este script para substituir todas as versões anteriores da função.
CREATE OR REPLACE FUNCTION public.log_audit_trail()
RETURNS TRIGGER AS $$
DECLARE
    audit_payload jsonb;
    target_id_text text;
    record_user_id UUID;
    current_session_id UUID;
    action_text text;
    current_company_id UUID;
BEGIN
    BEGIN
        -- Estratégia Definitiva para Session ID: Consultar auth.sessions
        -- Como a função é SECURITY DEFINER, ela tem permissão para ler a tabela auth.sessions.
        SELECT id INTO current_session_id
        FROM auth.sessions
        WHERE user_id = auth.uid()
        ORDER BY created_at DESC
        LIMIT 1;

        -- Estratégia 1: Tenta obter o company_id diretamente da linha modificada.
        IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
            current_company_id := (to_jsonb(NEW) ->> 'company_id')::UUID;
        ELSE -- DELETE
            current_company_id := (to_jsonb(OLD) ->> 'company_id')::UUID;
        END IF;

        -- Estratégia 2: Se não encontrou, busca o company_id via 'memberships'.
        IF current_company_id IS NULL THEN
            BEGIN
                SELECT company_id INTO current_company_id
                FROM public.memberships
                WHERE user_id = auth.uid()
                LIMIT 1;
            EXCEPTION WHEN NO_DATA_FOUND THEN
                current_company_id := NULL;
            END;
        END IF;

        -- Validação final: Se ainda não há company_id, a auditoria não pode prosseguir.
        IF current_company_id IS NULL THEN
            RAISE WARNING 'Auditoria Ignorada: company_id não encontrado para a operação na tabela %', TG_TABLE_NAME;
            RETURN COALESCE(NEW, OLD);
        END IF;

        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
            target_id_text := NEW.id::text;
        ELSE
            target_id_text := OLD.id::text;
        END IF;

        audit_payload := jsonb_build_object(
            'before', CASE WHEN TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE null END,
            'after',  CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) ELSE null END,
            'metadata', jsonb_build_object(
                'source', 'trigger',
                'trigger_op', TG_OP,
                'table', TG_TABLE_NAME
            )
        );

        action_text := LOWER(TG_TABLE_NAME || '.' || TG_OP);

        -- Evita logar ações realizadas pelo 'service_role' (operações do sistema)
        IF auth.role() <> 'service_role' THEN
            INSERT INTO public.audit_logs (company_id, user_id, session_id, action, target_entity, target_id, payload)
            VALUES (
                current_company_id,
                auth.uid(),
                current_session_id,
                action_text,
                TG_TABLE_NAME,
                target_id_text,
                audit_payload
            );
        END IF;

    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[AUDIT FAIL] Erro na auditoria para tabela %: %', TG_TABLE_NAME, SQLERRM;
    END;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Passo 2.2: Conceder Permissões para a Função

```sql
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION public.log_audit_trail() TO authenticated;
```

### Passo 2.3: Criar a Função Auxiliar `apply_audit_trigger()`

Para evitar a repetição manual de código, criamos esta função auxiliar. Pense nela como uma ferramenta que automatiza a instalação da nossa "câmera de segurança" (o gatilho que chama `log_audit_trail`). Em vez de escrever o mesmo código de criação de gatilho para cada tabela que queremos monitorar, nós simplesmente chamamos esta função e passamos o nome da tabela. Ela cuida de todo o processo de forma padronizada, garantindo que a auditoria seja aplicada de maneira consistente e livre de erros.

```sql
-- DESCRIÇÃO: Função auxiliar para aplicar ou recriar o trigger de auditoria em uma tabela.
-- Torna o processo de auditar novas tabelas mais simples e menos propenso a erros.
-- EXECUÇÃO: Execute este script uma única vez.
CREATE OR REPLACE FUNCTION public.apply_audit_trigger(table_name TEXT)
RETURNS TEXT AS $$
BEGIN
    EXECUTE format(
        -- Remove o trigger antigo se ele existir, para garantir a idempotência.
        'DROP TRIGGER IF EXISTS %I_audit_trigger ON public.%I; ' ||

        -- Cria o novo trigger.
        'CREATE TRIGGER %I_audit_trigger ' ||
        'AFTER INSERT OR UPDATE OR DELETE ON public.%I ' ||
        'FOR EACH ROW EXECUTE FUNCTION public.log_audit_trail();',

        table_name, table_name, table_name, table_name
    );
    RETURN 'Trigger de auditoria aplicado com sucesso na tabela: ' || table_name;
END;
$$ LANGUAGE plpgsql;
```

---

## Fase 3: Ativação da Auditoria

### Passo 3.1: Aplicar os Triggers

Agora que temos a função de automação (`apply_audit_trigger`), vamos usá-la para "ligar" a auditoria nas tabelas que são cruciais para a nossa aplicação. Cada um dos comandos abaixo instrui o banco de dados a começar a monitorar a tabela especificada. A partir deste momento, qualquer inserção, atualização ou exclusão de dados nessas tabelas será automaticamente capturada e registrada em `audit_logs`.

```sql
SELECT public.apply_audit_trigger('departments');
SELECT public.apply_audit_trigger('roles');
SELECT public.apply_audit_trigger('memberships');
SELECT public.apply_audit_trigger('profiles');
```

---

## Fase 4: Configuração da Segurança Granular (RLS)

Agora que temos um sistema robusto que captura todas as ações importantes, precisamos garantir que esses dados sensíveis só possam ser acessados pelas pessoas certas. Nesta fase, implementaremos a Segurança em Nível de Linha (Row-Level Security - RLS) do Supabase. Pense no RLS como um porteiro inteligente para nossas tabelas de auditoria. Ele examina cada solicitação de leitura de dados e decide, linha por linha, se o usuário que fez a solicitação tem permissão para vê-la. Isso nos permite criar regras muito específicas, como "usuários normais só podem ver seus próprios logs", enquanto "administradores podem ver todos os logs da empresa", garantindo segurança e privacidade.

### Passo 4.1: Definir Políticas de Acesso de Leitura (SELECT)

```sql
CREATE POLICY "Permitir leitura granular de logs de sessão"
ON public.audit_sessions FOR SELECT
USING (
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read.total'))
    OR
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read') AND user_id = auth.uid())
);

CREATE POLICY "Permitir leitura granular de logs de auditoria"
ON public.audit_logs FOR SELECT
USING (
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read.total'))
    OR
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read') AND user_id = auth.uid())
);
```

### Passo 4.2: Definir Política de Criação de Logs (INSERT)

```sql
CREATE POLICY "Users can insert audit logs for their company"
ON public.audit_logs FOR INSERT TO authenticated
WITH CHECK ( company_id = (SELECT get_my_active_company_id()) );
```

### Conclusão: Funcionamento Prático das Políticas de RLS

As políticas acima criam um sistema de acesso seguro e hierárquico. Vamos ver como elas funcionam na prática com exemplos:

#### 1. Quem pode LER o quê? (Políticas de `SELECT`)

A política de leitura é dividida em duas condições principais, funcionando como um sistema de "OU": o usuário precisa atender à primeira OU à segunda condição para ver os dados.

**Cenário A: O Administrador da Empresa**
*   **Quem:** Um usuário com a permissão `audit.read.total`.
*   **O que pode ver:** Ele pode ver todos os logs de auditoria de todos os usuários da sua própria empresa.
*   **Exemplo:** Um gerente de TI precisa investigar uma alteração suspeita feita em um departamento. Ele consegue visualizar a lista completa de logs da empresa e filtrar pelas ações do usuário em questão.

**Cenário B: O Usuário Comum**
*   **Quem:** Um usuário com a permissão `audit.read`, mas sem a `audit.read.total`.
*   **O que pode ver:** Ele pode ver apenas os seus próprios logs de auditoria.
*   **Exemplo:** Ana, uma colaboradora, quer verificar quando ela atualizou seu perfil pela última vez. Ela pode acessar a tela de auditoria e verá apenas as ações que ela mesma realizou. Ela não consegue, de forma alguma, ver os logs de Beto, seu colega.

#### 2. Quem pode CRIAR o quê? (Política de `INSERT`)

A política de inserção é mais simples e funciona como uma barreira de segurança.

*   **Quem:** Qualquer usuário autenticado no sistema.
*   **O que pode criar:** Um novo registro na tabela `audit_logs`.
*   **A Regra (`WITH CHECK`):** A política impõe uma verificação crucial: o `company_id` do novo log que está sendo inserido deve ser igual ao `company_id` ativo do usuário que está realizando a ação.
*   **Exemplo Prático:** Quando um usuário do WeWeb clica em um botão que chama a nossa Edge Function para registrar um log, esta política garante que ele só pode criar logs para a empresa à qual ele pertence e está logado. Isso impede que um usuário da "Empresa X" consiga, acidentalmente ou maliciosamente, inserir um registro de log no espaço da "Empresa Y".

Em resumo, essas regras garantem que os dados de auditoria sejam tanto **privados** (usuários só veem o que lhes é permitido) quanto **íntegros** (os logs são sempre associados à empresa correta).

---

## Fase 5: Captura de Eventos do Frontend (WeWeb + Edge Function)

Nesta fase, avançamos para o **ponto 2** da nossa estratégia de auditoria: o registro de ações importantes executadas pelo usuário diretamente na interface do WeWeb. Diferente das alterações no banco de dados, que são capturadas automaticamente por gatilhos, as ações no frontend, como a visualização de uma página ou a aplicação de um filtro, precisam ser enviadas ativamente para o nosso sistema.

Para lidar com essa tarefa, optamos por utilizar uma Edge Function do Supabase como intermediária. A escolha por essa abordagem, em vez de inserir logs diretamente do WeWeb, foi estratégica por vários motivos:

*   **Segurança Reforçada:** A Edge Function atua como um endpoint seguro. O frontend se comunica com a função, e a função, que executa em um ambiente controlado no servidor, é quem tem a permissão para escrever no banco de dados. Isso evita expor chaves de acesso sensíveis ou criar políticas de segurança (RLS) complexas para inserção de dados.
*   **Centralização e Manutenção:** Toda a lógica para validar, enriquecer e formatar os logs do frontend fica centralizada em um único lugar. Se precisarmos adicionar mais informações a cada log (como o endereço IP do usuário) ou alterar o padrão, modificamos apenas a função, sem precisar alterar múltiplos workflows no WeWeb.
*   **Desempenho e Flexibilidade:** Edge Functions são rápidas e podem ser distribuídas globalmente, garantindo que o envio de logs tenha um impacto mínimo na experiência do usuário. Elas também nos permitem realizar pré-processamentos nos dados antes que cheguem ao banco, garantindo a integridade e a consistência dos registros.

### Passo 5.1: Criar Funções RPC Auxiliares

Para que nossa Edge Function consiga contextualizar corretamente cada log, ela precisa de duas informações cruciais que só existem no ambiente do banco de dados no momento da requisição: o `company_id` ativo do usuário e o `session_id` atual. Estas funções RPC (Remote Procedure Call) servem como pontes seguras, permitindo que a Edge Function "pergunte" ao banco de dados por essas informações de forma performática e segura, utilizando o contexto do usuário que fez a chamada.

```sql
CREATE OR REPLACE FUNCTION public.get_my_active_company_id()
RETURNS UUID AS $$
DECLARE
    company_id_text text;
BEGIN
    company_id_text := auth.jwt() -> 'app_metadata' ->> 'active_company_id';
    IF company_id_text ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        RETURN company_id_text::UUID;
    ELSE
        RETURN NULL;
    END IF;
EXCEPTION
  WHEN others THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE FUNCTION public.get_my_session_id()
RETURNS UUID AS $$
DECLARE
    session_id_result UUID;
BEGIN
    SELECT id INTO session_id_result
    FROM auth.sessions
    WHERE user_id = auth.uid()
    ORDER BY created_at DESC
    LIMIT 1;
    RETURN session_id_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Passo 5.2: Criar a Edge Function `log-event`

Este é o coração da nossa captura de eventos do frontend. A Edge Function `log-event` é um pequeno servidor que executa uma lógica específica sempre que é chamado. Pense nela como um porteiro digital seguro e eficiente. O fluxo de funcionamento é o seguinte:

1.  **Recebimento da Chamada:** O WeWeb envia uma requisição do tipo `POST` para o endpoint desta função, contendo os detalhes do evento (ação, payload, etc.) no corpo da requisição e o token de autenticação do usuário no cabeçalho.
2.  **Validação de Segurança:** A primeira coisa que a função faz é verificar o token de autenticação para garantir que a requisição vem de um usuário logado e válido. Se o token for inválido, a requisição é imediatamente rejeitada.
3.  **Validação dos Dados:** Em seguida, ela inspeciona os dados recebidos para garantir que estão no formato esperado (por exemplo, se o campo `action` existe e é uma string).
4.  **Enriquecimento dos Dados:** A função chama as funções RPC que criamos (`get_my_active_company_id` e `get_my_session_id`) para obter o contexto do usuário (ID da empresa e da sessão). Ela também adiciona informações que só o servidor pode fornecer com segurança, como o endereço IP e o User-Agent do navegador.
5.  **Construção do Log:** Com todos os dados validados e enriquecidos, ela monta o objeto final do log, pronto para ser inserido no banco de dados.
6.  **Inserção Segura:** Utilizando o cliente Supabase com as credenciais do usuário, a função insere o novo registro na tabela `audit_logs`. É crucial notar que esta inserção respeita a política de RLS que definimos, garantindo que o usuário só possa criar logs para sua própria empresa.
7.  **Resposta:** Finalmente, a função retorna uma resposta ao WeWeb, confirmando que o log foi criado com sucesso ou informando sobre qualquer erro que tenha ocorrido no processo.

O código abaixo implementa exatamente este fluxo, com tratamento de erros robusto e validações para garantir a integridade dos dados.

```typescript
// supabase/functions/log-event/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Headers CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};

// Função utilitária para criar respostas de erro
function createErrorResponse(message, status = 400, details) {
  const errorBody = { error: message };
  if (details) {
    errorBody.details = details;
  }
  return new Response(JSON.stringify(errorBody), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Função utilitária para criar respostas de sucesso
function createSuccessResponse(data) {
  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
}

// Função para validar os dados de entrada
function validateEventData(data) {
  if (!data || typeof data !== 'object') return false;
  if (!data.action || typeof data.action !== 'string' || data.action.trim().length === 0) return false;
  if (data.target_entity && typeof data.target_entity !== 'string') return false;
  if (data.target_id && typeof data.target_id !== 'string') return false;
  if (data.payload && typeof data.payload !== 'object') return false;
  return true;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (req.method !== 'POST') {
    return createErrorResponse('Method not allowed', 405);
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return createErrorResponse('Missing or invalid Authorization header', 401);
    }

    let eventData;
    try {
      const rawData = await req.json();
      if (!validateEventData(rawData)) {
        return createErrorResponse('Invalid request body. Required: action (string)', 400);
      }
      eventData = rawData;
    } catch (parseError) {
      return createErrorResponse('Invalid JSON in request body', 400, parseError.message);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    if (!supabaseUrl || !supabaseAnonKey) {
      console.error('Missing required environment variables');
      return createErrorResponse('Server configuration error', 500);
    }

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await supabaseClient.auth.getUser();
    if (authError) {
      console.error('Authentication error:', authError);
      return createErrorResponse('Authentication failed', 401, authError.message);
    }
    if (!user) {
      return createErrorResponse('Invalid or expired token', 401);
    }

    // Buscar company_id (obrigatório)
    const companyResult = await supabaseClient.rpc('get_my_active_company_id');

    // Buscar session_id (opcional, pode falhar)
    let sessionResult;
    try {
      sessionResult = await supabaseClient.rpc('get_my_session_id');
    } catch (error) {
      console.warn('Could not get session_id:', error);
      sessionResult = { data: null, error: null };
    }

    if (companyResult.error) {
      console.error('Failed to get company_id:', companyResult.error);
      return createErrorResponse('Could not resolve user company', 403, companyResult.error.message);
    }
    if (!companyResult.data) {
      return createErrorResponse('User company context not found in token', 403);
    }

    const logEntry = {
      company_id: companyResult.data,
      user_id: user.id,
      session_id: sessionResult.data || null,
      action: eventData.action.trim(),
      target_entity: eventData.target_entity?.trim() || null,
      target_id: eventData.target_id?.trim() || null,
      payload: {
        ...eventData.payload,
        metadata: {
          source: 'frontend',
          timestamp: new Date().toISOString(),
          user_agent: req.headers.get('User-Agent') || 'unknown',
          ip_address: req.headers.get('CF-Connecting-IP') || req.headers.get('X-Forwarded-For') || 'unknown'
        }
      }
    };

    const { data: insertData, error: insertError } = await supabaseClient.from('audit_logs').insert(logEntry).select('id').single();
    if (insertError) {
      console.error('Error inserting audit log:', insertError);
      return createErrorResponse('Failed to create audit log', 500, insertError.message);
    }

    return createSuccessResponse({ success: true, log_id: insertData?.id });
  } catch (error) {
    console.error('Unexpected error in log-event function:', error);
    const isDevelopment = Deno.env.get('DENO_ENV') === 'development';
    const errorMessage = isDevelopment ? error.message : 'Internal server error';
    return createErrorResponse(errorMessage, 500);
  }
});
```

### Passo 5.3: Configurar o Workflow no WeWeb

Criaremos um workflow global no WeWeb para chamar nossa Edge Function. Isso torna o processo de logging reutilizável e padronizado em toda a aplicação.

1.  **Crie uma Nova Ação (`Data > Actions`):**
    *   No editor do WeWeb, navegue até o painel `Data` e selecione a aba `Actions`.
    *   Clique em `New action`.
    *   **Nome:** `Invoke Log Event Function`
    *   **Tipo:** `REST API Request`
    *   **URL:** Cole a URL da sua Edge Function que você obteve após o deploy.
    *   **Método:** `POST`
    *   **Headers:** Adicione as três chaves a seguir:
        *   `apikey`: Vincule ao valor da sua `SUPABASE_ANON_KEY` (pode ser uma variável global no WeWeb).
        *   `Authorization`: Use a fórmula `Bearer ` + `[user.token]`. Isso passa dinamicamente o token JWT do usuário logado.
        *   `Content-Type`: `application/json` (valor estático).
    *   **Corpo da Requisição (Body):**
        *   Clique em "Add parameter" para criar as variáveis que esta ação aceitará: `action` (Tipo: Text), `target_entity` (Tipo: Text), e `payload` (Tipo: Object).
        *   No editor de corpo (body), use a sintaxe de fórmula para montar o JSON:
            ```json
            {
              "action": [action],
              "target_entity": [target_entity],
              "payload": [payload]
            }
            ```

2.  **Crie um Workflow Global (`Workflows > Global Workflows`):**
    *   No editor do WeWeb, navegue até `Workflows` e selecione `Global Workflows`.
    *   Clique em `New workflow`.
    *   **Nome:** `Log Frontend Action`
    *   **Parâmetros (Parameters):** Adicione os mesmos três parâmetros: `action` (Tipo: String), `target_entity` (Tipo: String, marque como opcional), `payload` (Tipo: Object, marque como opcional).
    *   **Lógica do Workflow:**
        *   Adicione a ação `Invoke Log Event Function` que você acabou de criar.
        *   Mapeie os parâmetros do workflow para os parâmetros da ação (ex: o `action` do workflow será passado para o `action` da ação).

3.  **Exemplo de Uso Prático:**
    *   Selecione um elemento, como um botão de busca.
    *   Vá para a aba de `Workflows` do elemento e adicione um evento `On Click`.
    *   Adicione a ação `Run Global Workflow` e selecione `Log Frontend Action`.
    *   Preencha os parâmetros conforme o modelo definido no passo seguinte.

### Passo 5.4: Modelo de Payload Padrão para Eventos

Para garantir a consistência e a qualidade dos dados de auditoria, siga os padrões abaixo ao enviar eventos do frontend para a Edge Function.

**Convenção de Nomenclatura para Ações:** `entidade.ação` (ex: `products.search`, `page.view`).

#### Visualização de Página

*   **Ação:** `page.view`
*   **Chamada no WeWeb:**
    ```json
    {
      "action": "page.view",
      "target_entity": "dashboard",
      "payload": { "path": "/app/dashboard", "title": "Painel Principal" }
    }
    ```

#### Execução de Busca ou Filtro

*   **Ação:** `[entidade].search`
*   **Chamada no WeWeb:**
    ```json
    {
      "action": "invoices.search",
      "target_entity": "invoices",
      "payload": {
        "filters": { "status": "paid", "date_range": "last_30_days" },
        "searchTerm": "acme corp",
        "results_count": 15
      }
    }
    ```

#### Exportação de Dados

*   **Ação:** `[entidade].export`
*   **Chamada no WeWeb:**
    ```json
    {
      "action": "users.export",
      "target_entity": "users",
      "payload": { "format": "csv", "record_count": 250 }
    }
    ```

### Conclusão da Fase 5

Com a implementação da Edge Function `log-event` e a sua integração com o WeWeb através de um workflow global, concluímos com sucesso o segundo pilar da nossa estratégia de auditoria. Agora, o sistema é capaz não apenas de rastrear alterações estruturais no banco de dados, mas também de capturar as interações e eventos de negócio que ocorrem na interface do usuário.

Essa abordagem nos proporciona uma trilha de auditoria muito mais completa e contextualizada, registrando a jornada do usuário de ponta a ponta. A padronização dos payloads e a centralização da lógica garantem que os dados coletados sejam consistentes, seguros e fáceis de analisar, fortalecendo significativamente a segurança e a rastreabilidade da aplicação.

---

## Fase 6: Monitoramento de Eventos de Autenticação

Nesta fase final, implementaremos o terceiro e último pilar da nossa estratégia de auditoria: o monitoramento completo do ciclo de vida do usuário. Vamos criar os mecanismos necessários para capturar todos os eventos cruciais de autenticação, como login bem-sucedido, logout, tentativas de login que falharam, novos cadastros e processos de recuperação de senha.

Essa camada de monitoramento é vital para a segurança, pois nos dá visibilidade total sobre quem está tentando acessar o sistema, quando e como. Ao registrar esses eventos na tabela `audit_sessions`, criamos uma trilha de auditoria robusta que não só cumpre requisitos de conformidade, mas também nos permite identificar e responder a atividades suspeitas em tempo real.

### Passo 6.1: Criar a Edge Function `audit-auth-events`

Para capturar os eventos de `LOGIN_SUCCESS`, `LOGOUT` e `LOGIN_FAILED` de forma segura e centralizada, criaremos uma Edge Function específica chamada `audit-auth-events`. Esta função é chamada pelo frontend (WeWeb) em pontos estratégicos do fluxo de autenticação. Por exemplo, após um logout, o frontend invoca esta função passando o corpo da requisição como `{"event_type": "LOGOUT"}`.

Seu funcionamento é o seguinte:

1.  **Recebe o Evento:** O WeWeb envia os detalhes do evento (`LOGIN_SUCCESS`, `LOGOUT` ou `LOGIN_FAILED`) para esta função.
2.  **Diferencia o Tratamento:**
    *   Para `LOGIN_SUCCESS` e `LOGOUT`, a função extrai o token do usuário para obter seu `user_id`, `company_id` e `session_id`, garantindo um registro completo e contextualizado.
    *   Para `LOGIN_FAILED`, como não há um usuário autenticado, a função foca em registrar a tentativa de acesso, o endereço IP (de forma anonimizada para privacidade) e o agente do usuário (navegador).
3.  **Grava o Log:** Após processar a informação, ela insere um novo registro na tabela `audit_sessions`, classificando o evento e sua severidade (`INFO` para sucesso, `WARNING` para falha).

Essa abordagem desacopla a lógica de auditoria do fluxo principal de autenticação, tornando o sistema mais robusto e seguro.

```typescript
// supabase/functions/audit-auth-events/index.ts
// Edge Function com session_id dinâmico para LOGIN_SUCCESS/LOGOUT e null para LOGIN_FAILED
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS'
};
const VALID_EVENT_TYPES = [
  'LOGIN_SUCCESS',
  'LOGIN_FAILED',
  'LOGOUT',
  'CHANGE_PASSWORD',
  'FORGOT_PASSWORD'
];
// Função para decodificar JWT
function decodeJWT(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) throw new Error('Invalid JWT format');
    return JSON.parse(atob(parts[1]));
  } catch  {
    return null;
  }
}
// Função para capturar session_id
async function getSessionId(token, userId, supabase) {
  try {
    const payload = decodeJWT(token);
    if (payload?.session_id) return payload.session_id;
  } catch  {}
  try {
    const { data } = await supabase.from('sessions').select('id').eq('user_id', userId).order('created_at', {
      ascending: false
    }).limit(1);
    if (data?.length) return data[0].id;
  } catch  {}
  try {
    const jwtPayload = decodeJWT(token);
    if (jwtPayload?.sub && jwtPayload?.iat) {
      const sessionId = btoa(`${jwtPayload.sub}_${jwtPayload.iat}`).replace(/[^a-zA-Z0-9]/g, '').substring(0, 32);
      return sessionId;
    }
  } catch  {}
  return null;
}
// Função para anonimizar IP
function anonymizeIP(ip) {
  if (!ip) return null;
  if (ip.includes('.')) return ip.split('.').slice(0, 3).join('.') + '.0';
  if (ip.includes(':')) return ip.split(':').slice(0, 4).join(':') + '::';
  return ip;
}
// Função para obter geolocalização
async function getGeolocation(req, fullIP) {
  try {
    // Tenta primeiro com headers do Cloudflare (mais rápido)
    const cfCountry = req.headers.get('cf-ipcountry');
    const cfCity = req.headers.get('cf-ipcity');
    const cfRegion = req.headers.get('cf-region');
    const cfTimezone = req.headers.get('cf-timezone');
    const cfLatitude = req.headers.get('cf-latitude');
    const cfLongitude = req.headers.get('cf-longitude');
    // Se tiver dados do Cloudflare, usa eles
    if (cfCountry && cfCountry !== 'XX') {
      return {
        country: cfCountry,
        country_name: null,
        city: cfCity || null,
        region: cfRegion || null,
        latitude: cfLatitude ? parseFloat(cfLatitude) : null,
        longitude: cfLongitude ? parseFloat(cfLongitude) : null,
        timezone: cfTimezone || null,
        source: 'cloudflare'
      };
    }
    // Fallback: usa API externa se não tiver headers do Cloudflare
    if (!fullIP) return null;
    const response = await fetch(`http://ip-api.com/json/${fullIP}?fields=status,country,countryCode,region,regionName,city,lat,lon,timezone`, {
      signal: AbortSignal.timeout(3000) // Timeout de 3 segundos
    });
    if (!response.ok) return null;
    const data = await response.json();
    if (data.status !== 'success') return null;
    return {
      country: data.countryCode,
      country_name: data.country,
      city: data.city || null,
      region: data.regionName || null,
      latitude: data.lat || null,
      longitude: data.lon || null,
      timezone: data.timezone || null,
      source: 'ip-api'
    };
  } catch (error) {
    // Se falhar, retorna null (não bloqueia o registro do log)
    console.error('Erro ao obter geolocalização:', error);
    return null;
  }
}
// Handler principal
Deno.serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({
      error: 'Método não permitido'
    }), {
      status: 405,
      headers: corsHeaders
    });
  }
  try {
    const payload = await req.json();
    const eventType = payload.event_type;
    if (!VALID_EVENT_TYPES.includes(eventType)) {
      return new Response(JSON.stringify({
        error: 'Tipo de evento inválido'
      }), {
        status: 400,
        headers: corsHeaders
      });
    }
    const supabase = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    let sessionId = null;
    let userId = null;
    let companyId = null;
    // Para LOGIN_SUCCESS, LOGOUT, CHANGE_PASSWORD e FORGOT_PASSWORD, precisamos autenticar e capturar dados da sessão
    if (eventType === 'LOGIN_SUCCESS' || eventType === 'LOGOUT' || eventType === 'CHANGE_PASSWORD' || eventType === 'FORGOT_PASSWORD') {
      const authHeader = req.headers.get('Authorization');
      if (!authHeader?.startsWith('Bearer ')) {
        return new Response(JSON.stringify({
          error: 'Token JWT ausente'
        }), {
          status: 401,
          headers: corsHeaders
        });
      }
      const token = authHeader.substring(7);
      const { data: { user }, error } = await supabase.auth.getUser(token);
      if (error || !user) {
        return new Response(JSON.stringify({
          error: 'Usuário não autenticado'
        }), {
          status: 403,
          headers: corsHeaders
        });
      }
      userId = user.id;
      companyId = user.app_metadata?.active_company_id || null;
      sessionId = await getSessionId(token, userId, supabase);
    }
    // Captura IP completo (antes de anonimizar) para geolocalização
    const fullIP = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || req.headers.get('cf-connecting-ip') || req.headers.get('x-real-ip') || null;
    const userAgent = req.headers.get('user-agent') || null;
    // Obtém geolocalização (não bloqueia se falhar)
    const geolocation = await getGeolocation(req, fullIP);
    const auditLog = {
      session_id: eventType === 'LOGIN_SUCCESS' || eventType === 'LOGOUT' || eventType === 'CHANGE_PASSWORD' || eventType === 'FORGOT_PASSWORD' ? sessionId : null,
      user_id: eventType === 'LOGIN_SUCCESS' || eventType === 'LOGOUT' || eventType === 'CHANGE_PASSWORD' || eventType === 'FORGOT_PASSWORD' ? userId : null,
      company_id: eventType === 'LOGIN_SUCCESS' || eventType === 'LOGOUT' || eventType === 'CHANGE_PASSWORD' || eventType === 'FORGOT_PASSWORD' ? companyId : null,
      event_type: eventType,
      ip_address: anonymizeIP(fullIP),
      user_agent: userAgent,
      geolocation: geolocation,
      payload: {
        raw: payload
      },
      severity: eventType === 'LOGIN_FAILED' ? 'WARNING' : 'INFO'
    };
    const { error: insertError } = await supabase.from('audit_sessions').insert(auditLog);
    if (insertError) throw insertError;
    return new Response(JSON.stringify({
      success: true,
      geolocation_captured: geolocation !== null
    }), {
      status: 200,
      headers: corsHeaders
    });
  } catch (err) {
    return new Response(JSON.stringify({
      error: 'Erro interno',
      details: err.message
    }), {
      status: 500,
      headers: corsHeaders
    });
  }
});

```

### Conclusão da Fase 6

Com a implementação da Edge Function `audit-auth-events` e sua integração aos fluxos de autenticação no WeWeb, finalizamos o terceiro e último pilar da nossa estratégia. O sistema de auditoria agora possui uma visão de 360 graus, capturando desde as alterações de baixo nível no banco de dados até as interações de alto nível do usuário na interface e, crucialmente, os pontos de entrada e saída do sistema.

Esta abordagem unificada nos proporciona um registro de auditoria completo, coeso e contextualizado. A capacidade de correlacionar eventos de autenticação, ações no frontend e modificações no backend através de identificadores comuns como `user_id` e `session_id` eleva significativamente a nossa capacidade de garantir a segurança, investigar incidentes e manter a conformidade.

---

## Conclusão Geral

Ao final deste guia, implementamos com sucesso uma arquitetura de auditoria abrangente e de três pilares. A combinação de gatilhos de banco de dados para alterações de dados, uma Edge Function para eventos de frontend e outra para monitoramento de autenticação nos fornece uma trilha de auditoria completa, segura e resiliente.

Esta estrutura não apenas atende aos requisitos de segurança e conformidade, mas também fornece uma base sólida para futuras expansões e análises de dados. A capacidade de rastrear cada ação significativa, desde a criação de um registro até a visualização de uma página, oferece uma visibilidade sem precedentes sobre o uso do sistema, fortalecendo a segurança e a governança de dados da aplicação.
