# 3. Esquema da Base de Dados

Este documento detalha o esquema do banco de dados PostgreSQL, incluindo a finalidade de cada tabela, sua estrutura DDL, e os relacionamentos com os requisitos do sistema.

## 3.1. Diagrama Visual
Uma representação visual do relacionamento entre as entidades pode ser encontrada no [Diagrama de Entidade-Relacionamento](./01-system-architecture.md#141-diagrama-de-entidade-relacionamento-conceitual) na documentação de arquitetura.

---

## 3.2. Tabelas de Core e Gestão de Tenants

### `companies`
- **Finalidade e Justificativa:** Representa um tenant no sistema. É a tabela central que isola todos os outros recursos. Cada empresa é uma entidade de faturamento e um container para usuários e dados.
- **Link para Requisitos:** [FR-003-company-management.md](./04-functional-requirements/FR-003-company-management.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para armazenar as empresas (tenants)
  CREATE TABLE public.companies (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL,
      created_at timestamp with time zone DEFAULT now() NOT NULL
  );
  -- Ativar RLS
  ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
  ```
- **Campos e Restrições:**
  - `id` (uuid, PK): Identificador único da empresa.
  - `name` (text, NOT NULL): Nome público da empresa.

### `profiles`
- **Finalidade e Justificativa:** Estende a tabela `auth.users` do Supabase com informações específicas da aplicação, como a associação do usuário a uma `company` e a um `role`. É a ponte entre a autenticação e a lógica de negócio do tenant.
- **Link para Requisitos:** [FR-001-authentication.md](./04-functional-requirements/FR-001-authentication.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para estender os usuários do Supabase Auth
  CREATE TABLE public.profiles (
      id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
      company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
      role_id uuid NOT NULL REFERENCES public.roles(id),
      full_name text,
      avatar_url text,
      updated_at timestamp with time zone DEFAULT now()
  );
  -- Ativar RLS
  ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
  -- Índices para otimizar joins
  CREATE INDEX ix_profiles_company_id ON public.profiles USING btree (company_id);
  ```
- **Campos e Restrições:**
  - `id` (uuid, PK, FK->auth.users): Chave primária, ligada diretamente ao usuário no sistema de autenticação.
  - `company_id` (uuid, NOT NULL, FK->companies): Associa o perfil a uma empresa, crucial para as políticas de RLS.
  - `role_id` (uuid, NOT NULL, FK->roles): Define o papel do usuário no sistema.
  - `full_name` (text): Nome completo do usuário.

---

## 3.3. Tabelas de Controle de Acesso (RBAC)

### `roles`
- **Finalidade e Justificativa:** Define os papéis que um usuário pode ter (e.g., Admin, Member). Os papéis são a base do sistema RBAC, determinando o conjunto de permissões de um usuário.
- **Link para Requisitos:** [FR-002-rbac-and-permissions.md](./04-functional-requirements/FR-002-rbac-and-permissions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para os papéis de usuário
  CREATE TABLE public.roles (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL UNIQUE,
      description text,
      -- company_id é NULL para papéis de sistema (globais)
      company_id uuid NULL REFERENCES public.companies(id) ON DELETE CASCADE
  );
  -- Ativar RLS
  ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
  ```
- **Campos e Restrições:**
  - `id` (uuid, PK): Identificador único do papel.
  - `name` (text, UNIQUE): Nome do papel (e.g., 'Admin', 'Member').
  - `company_id` (uuid, NULL, FK->companies): Se nulo, é um papel de sistema. Se preenchido, é um papel customizado do tenant.

### `permissions`
- **Finalidade e Justificativa:** Define as permissões granulares do sistema (e.g., 'users:create', 'invoices:read'). Abstrai as ações para que possam ser agrupadas em papéis.
- **Link para Requisitos:** [FR-002-rbac-and-permissions.md](./04-functional-requirements/FR-002-rbac-and-permissions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para as permissões granulares
  CREATE TABLE public.permissions (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL UNIQUE,
      description text
  );
  -- RLS não costuma ser necessária aqui, pois é uma tabela de metadados
  ```
- **Campos e Restrições:**
  - `id` (uuid, PK): Identificador único da permissão.
  - `name` (text, UNIQUE): O nome da permissão, usado na lógica de negócio para verificação.

### `role_permissions`
- **Finalidade e Justificativa:** Tabela de junção (pivot) que associa `roles` a `permissions`, estabelecendo a relação muitos-para-muitos.
- **Link para Requisitos:** [FR-002-rbac-and-permissions.md](./04-functional-requirements/FR-002-rbac-and-permissions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela de junção para papéis e permissões
  CREATE TABLE public.role_permissions (
      role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
      permission_id uuid NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
      PRIMARY KEY (role_id, permission_id)
  );
  ```

---

## 3.4. Tabelas de Monetização e Assinaturas

### `plans`
- **Finalidade e Justificativa:** Define os planos de assinatura disponíveis. Centraliza as informações de preço e o ID do plano no gateway de pagamentos.
- **Link para Requisitos:** [FR-004-billing-and-subscriptions.md](./04-functional-requirements/FR-004-billing-and-subscriptions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para os planos de assinatura
  CREATE TABLE public.plans (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL,
      description text,
      price numeric(10, 2) NOT NULL,
      stripe_price_id text NOT NULL UNIQUE
  );
  ```

### `features`
- **Finalidade e Justificativa:** Define as funcionalidades individuais que podem ser ativadas por um plano (e.g., "Usuários Ilimitados").
- **Link para Requisitos:** [FR-004-billing-and-subscriptions.md](./04-functional-requirements/FR-004-billing-and-subscriptions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para as funcionalidades dos planos
  CREATE TABLE public.features (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL UNIQUE,
      description text
  );
  ```

### `plan_features`
- **Finalidade e Justificativa:** Tabela de junção que associa `plans` a `features`.
- **Link para Requisitos:** [FR-004-billing-and-subscriptions.md](./04-functional-requirements/FR-004-billing-and-subscriptions.md)
- **Definição (DDL):**
  ```sql
  CREATE TABLE public.plan_features (
      plan_id uuid NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
      feature_id uuid NOT NULL REFERENCES public.features(id) ON DELETE CASCADE,
      PRIMARY KEY (plan_id, feature_id)
  );
  ```

### `subscriptions`
- **Finalidade e Justificativa:** Armazena o estado da assinatura de cada tenant, incluindo o plano ativo e o status do ciclo de faturamento. É a fonte da verdade para a lógica de quotas e acesso a funcionalidades.
- **Link para Requisitos:** [FR-004-billing-and-subscriptions.md](./04-functional-requirements/FR-004-billing-and-subscriptions.md)
- **Definição (DDL):**
  ```sql
  -- Tabela para as assinaturas dos tenants
  CREATE TYPE subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
  CREATE TABLE public.subscriptions (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      company_id uuid NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
      plan_id uuid NOT NULL REFERENCES public.plans(id),
      status subscription_status NOT NULL,
      trial_ends_at timestamp with time zone,
      current_period_ends_at timestamp with time zone,
      stripe_subscription_id text UNIQUE
  );
  -- Ativar RLS
  ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
  ```

---

## 3.5. Tabelas de Privacidade e Compliance

### `consent_types`
- **Finalidade e Justificativa:** Define os tipos de consentimento auditáveis (e.g., "Termos de Serviço v1.2"). Essencial para compliance com LGPD/GDPR.
- **Link para Requisitos:** [Requisitos Não-Funcionais (Privacidade)](./05-non-functional-requirements.md#rnf-06-privacidade-e-compliance-lgpdgdpr)
- **Definição (DDL):**
  ```sql
  CREATE TABLE public.consent_types (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      name text NOT NULL UNIQUE,
      description text,
      version text NOT NULL
  );
  ```

### `user_consents`
- **Finalidade e Justificativa:** Registra quando um usuário específico (`user_id`) deu um consentimento específico (`consent_type_id`), criando uma trilha de auditoria imutável.
- **Link para Requisitos:** [Requisitos Não-Funcionais (Privacidade)](./05-non-functional-requirements.md#rnf-06-privacidade-e-compliance-lgpdgdpr)
- **Definição (DDL):**
  ```sql
  CREATE TABLE public.user_consents (
      id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
      user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
      consent_type_id uuid NOT NULL REFERENCES public.consent_types(id),
      granted_at timestamp with time zone DEFAULT now() NOT NULL,
      UNIQUE (user_id, consent_type_id)
  );
  -- Ativar RLS
  ALTER TABLE public.user_consents ENABLE ROW LEVEL SECURITY;
  ```
