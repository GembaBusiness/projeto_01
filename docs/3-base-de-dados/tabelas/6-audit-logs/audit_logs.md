# Tabela: audit_logs

## Finalidade e Justificativa

Enquanto a tabela `audit_sessions` foca nos eventos de entrada e saída (login/logout), a `audit_logs` é o coração do nosso sistema de auditoria detalhada. É aqui que cada ação específica – desde a criação de um novo departamento até a atualização de um perfil de usuário – será registrada.

Esta tabela nos dará uma visão granular de "quem", "o quê" e "quando" para todas as operações críticas do sistema, servindo como a fonte principal de verdade para qualquer investigação ou análise de atividade.

## DDL (SQL)

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

## Campos e Restrições

*   **id (BIGSERIAL, PK):** Chave primária da tabela.
*   **company\_id (UUID):** ID da empresa à qual o log pertence.
*   **user\_id (UUID):** ID do usuário que realizou a ação.
*   **session\_id (UUID):** ID da sessão do usuário.
*   **action (TEXT):** Ação normalizada (ex: 'product.create', 'profile.update').
*   **target\_entity (TEXT):** Nome da tabela ou entidade de negócio afetada.
*   **target\_id (TEXT):** ID do registro afetado.
*   **payload (JSONB):** Dados adicionais sobre a ação.
*   **created\_at (TIMESTAMPZ):** Data e hora da criação do registro.

## Políticas de Row Level Security (RLS)

```sql
CREATE POLICY "Permitir leitura granular de logs de auditoria"
ON public.audit_logs FOR SELECT
USING (
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read.total'))
    OR
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read') AND user_id = auth.uid())
);

CREATE POLICY "Users can insert audit logs for their company"
ON public.audit_logs FOR INSERT TO authenticated
WITH CHECK ( company_id = (SELECT get_my_active_company_id()) );
```

## Notas

Esta tabela é o coração do nosso sistema de auditoria detalhada.

### 1. Quem pode LER o quê? (Políticas de SELECT)

A política de leitura é dividida em duas condições principais, funcionando como um sistema de "OU": o usuário precisa atender à primeira OU à segunda condição para ver os dados.

#### Cenário A: O Administrador da Empresa

*   **Quem:** Um usuário com a permissão `audit.read.total`.
*   **O que pode ver:** Ele pode ver todos os logs de auditoria de todos os usuários da sua própria empresa.
*   **Exemplo:** Um gerente de TI precisa investigar uma alteração suspeita feita em um departamento. Ele consegue visualizar a lista completa de logs da empresa e filtrar pelas ações do usuário em questão.

#### Cenário B: O Usuário Comum

*   **Quem:** Um usuário com a permissão `audit.read`, mas sem a `audit.read.total`.
*   **O que pode ver:** Ele pode ver apenas os seus próprios logs de auditoria.
*   **Exemplo:** Ana, uma colaboradora, quer verificar quando ela atualizou seu perfil pela última vez. Ela pode acessar a tela de auditoria e verá apenas as ações que ela mesma realizou. Ela não consegue, de forma alguma, ver os logs de Beto, seu colega.

### 2. Quem pode CRIAR o quê? (Política de INSERT)

A política de inserção é mais simples e funciona como uma barreira de segurança.

*   **Quem:** Qualquer usuário autenticado no sistema.
*   **O que pode criar:** Um novo registro na tabela `audit_logs`.
*   **A Regra (WITH CHECK):** A política impõe uma verificação crucial: o `company_id` do novo log que está sendo inserido deve ser igual ao `company_id` ativo do usuário que está realizando a ação.
*   **Exemplo Prático:** Quando um usuário do WeWeb clica em um botão que chama a nossa Edge Function para registrar um log, esta política garante que ele só pode criar logs para a empresa à qual ele pertence e está logado. Isso impede que um usuário da "Empresa X" consiga, acidentalmente ou maliciosamente, inserir um registro de log no espaço da "Empresa Y".

Em resumo, essas regras garantem que os dados de auditoria sejam tanto **privados** (usuários só veem o que lhes é permitido) quanto **íntegros** (os logs são sempre associados à empresa correta).
