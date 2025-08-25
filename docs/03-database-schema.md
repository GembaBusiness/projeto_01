# 3. Esquema da Base de Dados

Este documento detalha o esquema do banco de dados PostgreSQL no Supabase, incluindo a descrição das tabelas e seus relacionamentos.

## 3.1. Diagrama de Entidade-Relacionamento (DER)

*Placeholder para o Diagrama de Entidade-Relacionamento (DER). O diagrama deve incluir as tabelas principais como `companies`, `profiles`, `roles`, e também as tabelas de monetização (`plans`, `features`, `plan_features`, `subscriptions`) e compliance (`consent_types`, `user_consents`). Recomenda-se usar uma ferramenta como o dbdiagram.io ou similar para gerar e incorporar a imagem aqui.*

## 3.2. Descrição das Tabelas

### `companies`
Armazena as informações sobre as empresas (tenants) que utilizam o sistema.
-   `id` (uuid, chave primária): Identificador único da empresa.
-   `name` (text): Nome da empresa.
-   `created_at` (timestampz): Data e hora de criação.
-   ... (outros campos relevantes para a empresa)

### `profiles`
Estende a tabela `auth.users` do Supabase com informações de perfil específicas da aplicação, incluindo a associação a uma empresa.
-   `id` (uuid, chave primária, FK para `auth.users.id`): Identificador único do usuário.
-   `company_id` (uuid, FK para `companies.id`): Associa o usuário a uma empresa. **Crucial para o RLS.**
-   `role_id` (uuid, FK para `roles.id`): Define o papel do usuário dentro da empresa.
-   `full_name` (text): Nome completo do usuário.
-   `avatar_url` (text): URL para a foto de perfil.
-   ... (outros campos de perfil)

### `roles`
Define os papéis (ex: Admin, Member) que um usuário pode ter dentro de uma empresa.
-   `id` (uuid, chave primária): Identificador único do papel.
-   `name` (text): Nome do papel (ex: 'Administrator', 'Standard User').
-   `description` (text): Descrição das responsabilidades do papel.

### `permissions`
Define as permissões granulares que podem ser associadas a papéis.
-   `id` (uuid, chave primária): Identificador único da permissão.
-   `name` (text, único): Nome da permissão (ex: 'users:create', 'invoices:read').
-   `description` (text): Descrição do que a permissão concede.

### `role_permissions` (Tabela de Junção)
Associa papéis a permissões (relação muitos-para-muitos).
-   `role_id` (uuid, FK para `roles.id`)
-   `permission_id` (uuid, FK para `permissions.id`)

### `navigation_items`
Controla os itens de menu que são visíveis na interface do usuário, com base nas permissões.
-   `id` (uuid, chave primária): Identificador único do item de menu.
-   `label` (text): O texto que aparece no menu (ex: 'Dashboard').
-   `path` (text): O caminho/rota no frontend (ex: '/dashboard').
-   `icon` (text): Nome do ícone a ser exibido.
-   `required_permission` (text, FK para `permissions.name`): A permissão necessária para ver este item.

## 3.3. Tabelas de Monetização e Assinaturas

Estas tabelas formam o núcleo do sistema de monetização, permitindo a criação de diferentes planos e o gerenciamento de assinaturas de clientes.

### `plans`
Define os planos de assinatura que podem ser oferecidos aos clientes.
-   `id` (uuid, chave primária): Identificador único do plano.
-   `name` (text): Nome do plano (e.g., "Básico", "Profissional").
-   `description` (text): Descrição do que o plano inclui.
-   `price` (numeric): Preço mensal do plano.
-   `stripe_price_id` (text, único): O ID do preço correspondente no Stripe, para integração com o checkout.

### `features`
Define as funcionalidades individuais que podem ser incluídas em um plano.
-   `id` (uuid, chave primária): Identificador único da funcionalidade.
-   `name` (text): Nome da funcionalidade (e.g., "Usuários Ilimitados", "Relatórios Avançados").
-   `description` (text): Detalhes sobre o que a funcionalidade faz.

### `plan_features` (Tabela de Junção)
Associa funcionalidades a planos (relação muitos-para-muitos).
-   `plan_id` (uuid, FK para `plans.id`)
-   `feature_id` (uuid, FK para `features.id`)

### `subscriptions`
Armazena o estado da assinatura de cada tenant.
-   `id` (uuid, chave primária): Identificador único da assinatura.
-   `company_id` (uuid, FK para `companies.id`): O tenant que possui a assinatura.
-   `plan_id` (uuid, FK para `plans.id`): O plano assinado.
-   `status` (enum): O estado atual da assinatura (e.g., `trialing`, `active`, `past_due`, `canceled`).
-   `trial_ends_at` (timestampz): Data de término do período de trial.
-   `current_period_ends_at` (timestampz): Data de término do ciclo de faturamento atual.
-   `stripe_subscription_id` (text, único): O ID da assinatura no Stripe, para sincronização via webhooks.

## 3.4. Tabelas de Privacidade e Compliance

Estas tabelas são essenciais para o cumprimento de regulamentações de privacidade como LGPD e GDPR.

### `consent_types`
Define os tipos de consentimento que um usuário pode dar (e.g., "Termos de Serviço", "Política de Cookies").
-   `id` (uuid, chave primária): Identificador único do tipo de consentimento.
-   `name` (text, único): Nome curto do consentimento (e.g., `terms_of_service_v1`).
-   `description` (text): Texto explicando o que o consentimento implica.
-   `version` (integer): Versão do consentimento, para rastrear atualizações.

### `user_consents`
Registra o consentimento dado por cada usuário, criando uma trilha de auditoria.
-   `id` (uuid, chave primária): Identificador único do registro de consentimento.
-   `user_id` (uuid, FK para `profiles.id`): O usuário que deu o consentimento.
-   `consent_type_id` (uuid, FK para `consent_types.id`): O tipo de consentimento que foi aceito.
-   `granted_at` (timestampz): Data e hora em que o consentimento foi dado.
