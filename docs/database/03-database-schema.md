# Módulo de Fundação: Modelagem da Base de Dados

**Versão:** 1.1
**Data:** 31 de Agosto de 2025

---

## 1. Objetivo Geral da Seção

Esta seção detalha o esquema completo da base de dados no Supabase (PostgreSQL). O objetivo é estabelecer a fundação sobre a qual toda a lógica de negócio, segurança e funcionalidades serão construídas, garantindo integridade, escalabilidade e alinhamento com os requisitos de um sistema SaaS B-to-B multi-tenant.

---

## 2. Modelo de Dados

### 2.1. Domínio: Identidade e Multi-Tenancy

Este é o núcleo do sistema, responsável por gerir as empresas (tenants), os utilizadores e a relação entre eles.

#### 2.1.1. Tabela `companies`
[Ver detalhes da tabela `companies`](../3-base-de-dados/tabelas/companies.md)

---

#### 2.1.2. Tabela `profiles`
[Ver detalhes da tabela `profiles`](../3-base-de-dados/tabelas/profiles.md)

---

#### 2.1.3. Tabela `memberships`
[Ver detalhes da tabela `memberships`](../3-base-de-dados/tabelas/memberships.md)

---

#### 2.1.4. Tabela `departments`
[Ver detalhes da tabela `departments`](../3-base-de-dados/tabelas/departments.md)

---

### 2.2. Domínio: Autorização e Permissões (Abordagem Híbrida ABAC + RBAC)

Este domínio define o que um utilizador pode fazer dentro de uma empresa, utilizando uma abordagem híbrida que combina o melhor do ABAC (Attribute-Based Access Control) e do RBAC (Role-Based Access Control) para criar um sistema de autorização seguro, flexível e escalável.

**A Camada de Contexto: ABAC (Attribute-Based Access Control)**
O ABAC concede acesso com base em atributos (características). A permissão é decidida dinamicamente com base no contexto: quem é o usuário, o que ele está tentando acessar e em que condições?

No nosso projeto, o ABAC é a fundação da segurança e do multi-tenancy:
-   **Exemplo Real (Multi-Tenancy):** A regra mais fundamental do sistema é um exemplo clássico de ABAC: "um usuário só pode acessar os dados que pertencem à sua `company_id`". Aqui, a `company_id` é o atributo que governa o acesso, garantindo o isolamento total dos dados entre os tenants.
-   **Exemplo Real (Departamentos):** Expandindo a ideia, um usuário do departamento 'Financeiro' (atributo do usuário) só poderia visualizar relatórios marcados como 'Financeiro' (atributo do recurso). No entanto, se esse mesmo usuário possuir um atributo específico, como uma flag `has_company_wide_access` (atributo do usuário na tabela "memberships"), ele teria acesso a todos os departamentos, funcionando como um acesso privilegiado dentro da própria empresa, mesmo que seu papel seja o mesmo.

**A Estrutura de Cargos: RBAC (Role-Based Access Control)**
O RBAC concede acesso com base em "cargos" (Roles) atribuídos aos usuários. Ele define de forma estática o que um usuário pode fazer dentro do sistema (as ações que ele pode executar).

No nosso modelo, a estrutura do RBAC é definida pela seguinte cadeia de relacionamentos:
1.  Um usuário pertence a uma empresa, criando um vínculo (`memberships`).
2.  A esse vínculo (`membership_id`) é atribuído um ou mais papéis (`membership_roles`).
3.  Cada papel (`role_id`) é um agrupamento de permissões (`role_permissions`).
4.  Cada permissão (`permission_id`) é uma ação granular no sistema (ex: `projects.create`).

Dessa forma, um usuário será vinculado a uma permissão através dessa conexão e terá acesso somente aos itens e ações para os quais seu papel concede permissão explicitamente.

**Implementação e Por Que Usar uma Abordagem Híbrida**
Toda essa lógica de autorização é garantida em múltiplos níveis para criar uma defesa em profundidade:
-   **No Banco de Dados (Segurança Máxima):** As regras, principalmente as de ABAC (como o isolamento por `company_id`), serão implementadas diretamente no PostgreSQL utilizando RLS (Row-Level Security). Isso garante que, mesmo que ocorra uma falha na aplicação, um usuário jamais conseguirá acessar dados de outra empresa.
-   **No Front-End (Experiência do Usuário):** Adotamos uma abordagem híbrida para o controle de acesso. Enquanto o RLS atua como a camada final de segurança no banco de dados, o RBAC será utilizado no front-end para controlar a interface. Tabelas de apoio (como `navigation_items` e `nav_item_permissions`) definirão quais itens de menu, páginas e botões um usuário pode ver com base nos seus papéis, criando uma experiência de usuário limpa e relevante, sempre respaldada pela segurança do RLS.

**Motivos da Escolha:**
-   **O Melhor dos Dois Mundos:** Ganhamos a simplicidade e previsibilidade do RBAC para as permissões do dia a dia e a flexibilidade contextual e poderosa do ABAC para regras de negócio dinâmicas.
-   **Segurança em Profundidade:** A combinação de RLS (ABAC) no banco e controle de UI (RBAC) no front-end cria uma defesa robusta em camadas.
-   **Escalabilidade e Manutenibilidade:** É fácil adicionar novas regras baseadas em atributos (ex: um novo plano de assinatura que libera features) sem precisar criar uma infinidade de novos papéis, mantendo o sistema organizado e fácil de evoluir.

---

#### 2.2.1. Tabela `roles`
[Ver detalhes da tabela `roles`](../3-base-de-dados/tabelas/roles.md)

---

#### 2.2.2. Tabela `permissions`
[Ver detalhes da tabela `permissions`](../3-base-de-dados/tabelas/permissions.md)

---

#### 2.2.3. Tabela `role_permissions`
[Ver detalhes da tabela `role_permissions`](../3-base-de-dados/tabelas/role_permissions.md)

---

#### 2.2.4. Tabela `membership_roles`
[Ver detalhes da tabela `membership_roles`](../3-base-de-dados/tabelas/membership_roles.md)

---

### 2.3. Domínio: Planos e Monetização

Este domínio controla o acesso a funcionalidades com base no plano comercial subscrito.

#### 2.3.1. Tabela `features`
[Ver detalhes da tabela `features`](../3-base-de-dados/tabelas/features.md)

---

#### 2.3.2. Tabela `plans`
[Ver detalhes da tabela `plans`](../3-base-de-dados/tabelas/plans.md)

---

#### 2.3.3. Tabela `prices`
[Ver detalhes da tabela `prices`](../3-base-de-dados/tabelas/prices.md)

---

#### 2.3.4. Tabela `subscriptions`
[Ver detalhes da tabela `subscriptions`](../3-base-de-dados/tabelas/subscriptions.md)

---

#### 2.3.5. Tabela `subscription_history`
[Ver detalhes da tabela `subscription_history`](../3-base-de-dados/tabelas/subscription_history.md)

---

#### 2.3.6. Tabela `plan_features`
[Ver detalhes da tabela `plan_features`](../3-base-de-dados/tabelas/plan_features.md)

---

## 3. Domínio: Interface e Navegação

Este domínio define a estrutura e o controle de acesso aos elementos visuais da interface, como menus de navegação. Ele materializa a camada de "Experiência do Usuário" mencionada na nossa abordagem de autorização, permitindo que a UI se adapte dinamicamente às permissões do usuário.

### 3.1. Tabela `navigation_items`
[Ver detalhes da tabela `navigation_items`](../3-base-de-dados/tabelas/navigation_items.md)

---

### 3.2. Tabela `nav_item_permissions`
[Ver detalhes da tabela `nav_item_permissions`](../3-base-de-dados/tabelas/nav_item_permissions.md)

---

## 4. Domínio: Conformidade e Auditoria

Este domínio gerencia o consentimento do usuário para documentos legais, como Termos de Serviço e Políticas de Privacidade. É essencial para garantir a conformidade com regulamentações de proteção de dados e para manter uma trilha de auditoria clara sobre quais termos cada usuário aceitou e quando.

### 4.1. Tabela `consent_types`
[Ver detalhes da tabela `consent_types`](../3-base-de-dados/tabelas/consent_types.md)

---

### 4.2. Tabela `user_consents`
[Ver detalhes da tabela `user_consents`](../3-base-de-dados/tabelas/user_consents.md)

---

## 5. Conclusão

O esquema da base de dados aqui detalhado estabelece uma fundação robusta e coesa para um sistema SaaS B-to-B. Através da separação lógica em domínios distintos — Identidade, Autorização, Monetização, Interface e Conformidade — criamos um modelo que é ao mesmo tempo seguro, escalável e de fácil manutenção.

As principais características desta arquitetura são:
-   **Segurança Multi-Tenant:** O isolamento de dados por `company_id` é o pilar central, garantindo que os dados de um cliente nunca sejam expostos a outro.
-   **Autorização Flexível:** A abordagem híbrida de ABAC e RBAC oferece um controle de acesso poderoso, combinando a simplicidade dos papéis com a granularidade do acesso baseado em atributos, tudo reforçado por RLS no nível do banco de dados.
-   **Modelo de Negócio Adaptável:** A estrutura de planos, preços e features permite que a oferta comercial do produto evolua sem a necessidade de alterações complexas no código.
-   **Governança e Auditoria:** As tabelas de consentimento e históricos fornecem as trilhas de auditoria necessárias para conformidade e análise de negócio.

Em suma, este modelo de dados não é apenas uma estrutura para armazenar informações, mas sim o alicerce estratégico sobre o qual toda a lógica de negócio, experiência do usuário e segurança da aplicação serão construídas.
