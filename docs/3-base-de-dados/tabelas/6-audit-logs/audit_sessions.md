
Tabela: audit_sessions
Finalidade e Justificativa: Esta tabela é um pilar fundamental da segurança e monitoramento do sistema. Ela funciona como um diário de bordo para o ciclo de vida de cada sessão de usuário, registrando eventos cruciais como logins bem-sucedidos (LOGIN_SUCCESS), logouts (LOGOUT) e, de forma muito importante, tentativas de login que falharam (LOGIN_FAILURE). Manter um registro detalhado desses eventos nos permite não só entender quando e como os usuários acessam o sistema, mas também identificar atividades suspeitas, como tentativas de acesso não autorizado, fornecendo uma camada essencial para a segurança da aplicação.

DDL (SQL):

-- DESCRIÇÃO: Cria um tipo ENUM para garantir que os eventos de sessão sejam padronizados.
-- EXECUÇÃO: Execute este script uma única vez.
CREATE TYPE public.session_event_type AS ENUM ('LOGIN_SUCCESS', 'LOGOUT', 'LOGIN_FAILURE');

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

Campos e Restrições:

id (UUID, PK): Chave primária da tabela.
session_id (UUID): ID da sessão de auth.sessions, para correlação direta.
company_id (UUID): ID da empresa à qual a sessão pertence.
user_id (UUID): ID do usuário associado à sessão.
event_type (ENUM): Tipo de evento de sessão (LOGIN_SUCCESS, LOGOUT, LOGIN_FAILURE).
ip_address (INET): Endereço IP de origem da solicitação.
user_agent (TEXT): User agent do cliente.
payload (JSONB): Dados adicionais sobre o evento (ex: motivo da falha de login).
created_at (TIMESTAMPZ): Data e hora da criação do registro.
severity (public.severity): Nível de severidade do evento.

Políticas de Row Level Security (RLS)
CREATE POLICY "Permitir leitura granular de logs de sessão"
ON public.audit_sessions FOR SELECT
USING (
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read.total'))
    OR
    ((company_id = custom_auth_helpers.current_company_id()) AND custom_auth_helpers.has_permission('audit.read') AND user_id = auth.uid())
);

Notas
Esta tabela é o diário de bordo do ciclo de vida de cada sessão de usuário.
A política de leitura é dividida em duas condições principais, funcionando como um sistema de "OU": o usuário precisa atender à primeira OU à segunda condição para ver os dados.
Cenário A: O Administrador da Empresa
Quem: Um usuário com a permissão audit.read.total.
O que pode ver: Ele pode ver todos os logs de sessão de todos os usuários da sua própria empresa.
Exemplo: Um administrador de segurança precisa investigar uma série de tentativas de login falhadas para uma conta de usuário. Ele consegue visualizar a lista completa de logs de sessão da empresa e filtrar pelos eventos de LOGIN_FAILURE.
Cenário B: O Usuário Comum
Quem: Um usuário com a permissão audit.read, mas sem a audit.read.total.
O que pode ver: Ele pode ver apenas os seus próprios logs de sessão.
Exemplo: Carlos, um usuário, quer verificar o histórico de seus logins recentes para garantir que sua conta não foi acessada indevidamente. Ele pode acessar a tela de auditoria e verá apenas os eventos de login e logout associados à sua própria conta. Ele não consegue ver os logs de sessão de outros usuários.
