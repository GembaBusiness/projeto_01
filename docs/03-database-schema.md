# 3. Esquema da Base de Dados

Este documento detalha o esquema do banco de dados PostgreSQL no Supabase, incluindo a descrição das tabelas e seus relacionamentos.

## 3.1. Diagrama de Entidade-Relacionamento (DER)

*Placeholder para o Diagrama de Entidade-Relacionamento (DER). Recomenda-se usar uma ferramenta como o dbdiagram.io ou similar para gerar e incorporar a imagem aqui.*

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
