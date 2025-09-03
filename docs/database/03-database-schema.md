# Módulo de Fundação: Modelagem da Base de Dados

**Versão:** 1.1
**Data:** 31 de Agosto de 2025

---

## 1. Objetivo Geral da Seção

Esta seção detalha o esquema completo da base de dados no Supabase (PostgreSQL). O objetivo é estabelecer a fundação sobre a qual toda a lógica de negócio, segurança e funcionalidades serão construídas, garantindo integridade, escalabilidade e alinhamento com os requisitos de um sistema SaaS B-to-B multi-tenant.

---

## 2. Modelo de Dados

### 2.1. Domínio: Identidade e Multi-Tenancy

[Ver detalhes do domínio](./tabelas/1-identidade-e-multi-tenancy/README.md)

#### 2.1.1. Tabela `companies`
[Ver detalhes da tabela `companies`](./tabelas/1-identidade-e-multi-tenancy/table_companies.md)

---

#### 2.1.2. Tabela `profiles`
[Ver detalhes da tabela `profiles`](./tabelas/1-identidade-e-multi-tenancy/table_profiles.md)

---

#### 2.1.3. Tabela `memberships`
[Ver detalhes da tabela `memberships`](./tabelas/1-identidade-e-multi-tenancy/table_memberships.md)

---

#### 2.1.4. Tabela `departments`
[Ver detalhes da tabela `departments`](./tabelas/1-identidade-e-multi-tenancy/table_departments.md)

---

### 2.2. Domínio: Autorização e Permissões

[Ver detalhes do domínio](./tabelas/2-autorizacao-e-permissoes/README.md)

#### 2.2.1. Tabela `roles`
[Ver detalhes da tabela `roles`](./tabelas/2-autorizacao-e-permissoes/table_roles.md)

---

#### 2.2.2. Tabela `permissions`
[Ver detalhes da tabela `permissions`](./tabelas/2-autorizacao-e-permissoes/table_permissions.md)

---

#### 2.2.3. Tabela `role_permissions`
[Ver detalhes da tabela `role_permissions`](./tabelas/2-autorizacao-e-permissoes/table_role_permissions.md)

---

#### 2.2.4. Tabela `membership_roles`
[Ver detalhes da tabela `membership_roles`](./tabelas/2-autorizacao-e-permissoes/table_membership_roles.md)

---

### 2.3. Domínio: Planos e Monetização

[Ver detalhes do domínio](./tabelas/3-planos-e-monetizacao/README.md)

#### 2.3.1. Tabela `features`
[Ver detalhes da tabela `features`](./tabelas/3-planos-e-monetizacao/table_features.md)

---

#### 2.3.2. Tabela `plans`
[Ver detalhes da tabela `plans`](./tabelas/3-planos-e-monetizacao/table_plans.md)

---

#### 2.3.3. Tabela `prices`
[Ver detalhes da tabela `prices`](./tabelas/3-planos-e-monetizacao/table_prices.md)

---

#### 2.3.4. Tabela `subscriptions`
[Ver detalhes da tabela `subscriptions`](./tabelas/3-planos-e-monetizacao/table_subscriptions.md)

---

#### 2.3.5. Tabela `subscription_history`
[Ver detalhes da tabela `subscription_history`](./tabelas/3-planos-e-monetizacao/table_subscription_history.md)

---

#### 2.3.6. Tabela `plan_features`
[Ver detalhes da tabela `plan_features`](./tabelas/3-planos-e-monetizacao/table_plan_features.md)

---

## 3. Domínio: Interface e Navegação

[Ver detalhes do domínio](./tabelas/4-interface-e-navegacao/README.md)

### 3.1. Tabela `navigation_items`
[Ver detalhes da tabela `navigation_items`](./tabelas/4-interface-e-navegacao/table_navigation_items.md)

---

### 3.2. Tabela `nav_item_permissions`
[Ver detalhes da tabela `nav_item_permissions`](./tabelas/4-interface-e-navegacao/table_nav_item_permissions.md)

---

## 4. Domínio: Conformidade e Auditoria

[Ver detalhes do domínio](./tabelas/5-conformidade-e-auditoria/README.md)

### 4.1. Tabela `consent_types`
[Ver detalhes da tabela `consent_types`](./tabelas/5-conformidade-e-auditoria/table_consent_types.md)

---

### 4.2. Tabela `user_consents`
[Ver detalhes da tabela `user_consents`](./tabelas/5-conformidade-e-auditoria/table_user_consents.md)

---

## 5. Conclusão

O esquema da base de dados aqui detalhado estabelece uma fundação robusta e coesa para um sistema SaaS B-to-B. Através da separação lógica em domínios distintos — Identidade, Autorização, Monetização, Interface e Conformidade — criamos um modelo que é ao mesmo tempo seguro, escalável e de fácil manutenção.

As principais características desta arquitetura são:
-   **Segurança Multi-Tenant:** O isolamento de dados por `company_id` é o pilar central, garantindo que os dados de um cliente nunca sejam expostos a outro.
-   **Autorização Flexível:** A abordagem híbrida de ABAC e RBAC oferece um controle de acesso poderoso, combinando a simplicidade dos papéis com a granularidade do acesso baseado em atributos, tudo reforçado por RLS no nível do banco de dados.
-   **Modelo de Negócio Adaptável:** A estrutura de planos, preços e features permite que a oferta comercial do produto evolua sem a necessidade de alterações complexas no código.
-   **Governança e Auditoria:** As tabelas de consentimento e históricos fornecem as trilhas de auditoria necessárias para conformidade e análise de negócio.

Em suma, este modelo de dados não é apenas uma estrutura para armazenar informações, mas sim o alicerce estratégico sobre o qual toda a lógica de negócio, experiência do usuário e segurança da aplicação serão construídas.
