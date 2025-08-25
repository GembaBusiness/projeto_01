# 1. Arquitetura do Sistema

Este documento descreve a arquitetura geral do sistema, as decisões tecnológicas e os principais fluxos de dados.

## 1.1. Justificativa da Stack Tecnológica

A escolha da stack foi baseada na busca por agilidade no desenvolvimento, baixo custo de manutenção e escalabilidade.

-   **Frontend (Low-Code): WeWeb**
    -   **Justificativa:** Permite a construção de interfaces de usuário complexas de forma visual e rápida, sem sacrificar a flexibilidade para adicionar lógica customizada. Ideal para acelerar o time-to-market.

-   **Backend (BaaS): Supabase**
    -   **Justificativa:** Oferece uma solução backend completa com autenticação, banco de dados PostgreSQL e APIs auto-geradas. A integração nativa com o PostgreSQL e o suporte a Row Level Security (RLS) são cruciais para a nossa arquitetura multi-tenant.

## 1.2. Arquitetura Multi-Tenant

A segurança e o isolamento dos dados entre as diferentes empresas (tenants) são a principal prioridade desta arquitetura.

-   **Isolamento de Dados:** Implementado diretamente no banco de dados PostgreSQL através de **Row Level Security (RLS)**.
-   **Chave de Tenant (`company_id`):** Todas as tabelas que contêm dados específicos de um tenant possuem uma coluna `company_id`.
-   **Políticas de RLS:** Políticas de segurança são aplicadas a cada tabela para garantir que as queries (SELECT, INSERT, UPDATE, DELETE) de um usuário autenticado só possam acessar os dados que pertencem à sua `company_id`. O `company_id` do usuário é obtido a partir do seu token JWT durante a sessão.

## 1.3. Fluxos de Dados Principais

### 1.3.1. Fluxo de Cadastro (Sign-up)

*Placeholder para diagrama de fluxo de cadastro.*
1.  O usuário preenche o formulário de cadastro com nome, email, senha e nome da empresa.
2.  Uma nova empresa é criada na tabela `companies`.
3.  Um novo usuário é criado no `auth.users` do Supabase.
4.  Um perfil correspondente é criado na tabela `profiles`, associado ao `user.id` e à `company_id` recém-criada.
5.  Ao primeiro usuário da empresa é atribuído o papel de `Admin`.

### 1.3.2. Fluxo de Autenticação (Login)

*Placeholder para diagrama de fluxo de autenticação.*
1.  O usuário insere email e senha.
2.  O WeWeb envia as credenciais para o endpoint de autenticação do Supabase.
3.  O Supabase valida as credenciais e retorna um **JWT (JSON Web Token)**.
4.  O JWT contém o `user.id` e outras informações, que são usadas para identificar o usuário e a sua `company_id` em requisições subsequentes.
5.  O WeWeb armazena o JWT de forma segura e o envia no cabeçalho de cada requisição à API.

## 1.4. Diagrama de Componentes

A arquitetura é composta pelos seguintes componentes principais:

-   **Frontend (WeWeb):** A interface do usuário (UI) construída na plataforma low-code WeWeb. É responsável por toda a apresentação visual, captura de entradas do usuário e interação com o backend via API.

-   **Backend (Supabase):** A plataforma Backend-as-a-Service que fornece os principais serviços de backend.
    -   **Supabase Auth:** Gerencia a identidade dos usuários, incluindo cadastro, login, MFA e emissão de JWTs.
    -   **Supabase Database (PostgreSQL):** O banco de dados relacional que armazena todos os dados da aplicação. É o núcleo da nossa política de segurança com RLS.
    -   **Supabase Storage:** Armazena arquivos e documentos de forma segura, com políticas de acesso para garantir que cada tenant só acesse seus próprios arquivos.
    -   **Supabase Edge Functions:** Funções serverless (Deno) usadas para executar lógica de negócio complexa, como orquestração de processos e integrações com serviços de terceiros (e.g., webhooks).

-   **Gateway de Pagamentos (Ex: Stripe):** Um serviço externo responsável por processar pagamentos, gerenciar assinaturas e enviar notificações de eventos (webhooks).
    -   **Interação:** O frontend interage com o gateway via SDK para iniciar o checkout. O backend (via Edge Functions) recebe webhooks do gateway para sincronizar o estado das assinaturas, atualizar faturas e gerenciar o acesso dos clientes às funcionalidades pagas.

## 1.5. Padrões de Arquitetura

Para garantir a robustez, escalabilidade e segurança do sistema, adotamos os seguintes padrões de arquitetura:

### 1.5.1. Arquitetura Híbrida RBAC + ABAC

Nosso sistema de controle de acesso combina dois modelos para máxima flexibilidade e segurança:
-   **RBAC (Role-Based Access Control):** Define "o que" um usuário pode fazer. Os papéis (e.g., `admin`, `member`) são atribuídos aos usuários e lhes concedem um conjunto de permissões para realizar ações específicas (e.g., convidar usuários, criar relatórios).
-   **ABAC (Attribute-Based Access Control):** Define "sobre quais dados" uma ação pode ser executada. Este controle é implementado via **Row Level Security (RLS)** no PostgreSQL. As políticas de RLS atuam como regras baseadas em atributos (e.g., `company_id` do usuário, `status` do documento) para filtrar os dados que podem ser acessados ou modificados.

A combinação significa que o RBAC governa o acesso às APIs e funcionalidades, enquanto o ABAC (RLS) garante o isolamento e a segurança dos dados no nível do banco de dados.

### 1.5.2. Orquestração de Registo (Padrão Saga)

Operações complexas que envolvem múltiplos passos, como o cadastro de um novo usuário com criação de assinatura, são tratadas como uma "Saga".
-   **Orquestrador:** Uma Edge Function atua como o orquestrador do fluxo. Ela invoca sub-rotinas (e.g., criar usuário no Auth, inserir perfil no DB, criar cliente no Stripe).
-   **Compensação (Rollback Lógico):** Se qualquer passo da saga falhar, o orquestrador é responsável por executar ações de compensação para reverter os passos já concluídos. Por exemplo, se a criação do cliente no Stripe falhar, o usuário criado no Supabase Auth é removido. Isso garante a consistência dos dados.

### 1.5.3. Política de Idempotência

Para operações críticas e sensíveis (especialmente aquelas que envolvem pagamentos ou criação de recursos), o sistema impõe uma política de idempotência para prevenir a execução duplicada de requisições.
-   **Geração de Chave no Cliente:** O cliente (frontend) gera uma chave de idempotência única (e.g., UUID) para cada transação.
-   **Time-to-Live (TTL):** A chave é armazenada temporariamente no backend (e.g., em uma tabela com TTL) para rastrear requisições recentes.
-   **Validação de Payload:** O backend verifica se a chave já foi processada. Se sim, em vez de re-executar a operação, ele retorna a resposta original que foi salva. Isso evita, por exemplo, que um cliente seja cobrado duas vezes por um duplo-clique.

### 1.5.4. Governança de Papéis

O sistema distingue entre dois tipos de papéis para uma governança clara:
-   **Papéis de Sistema:** São papéis globais, definidos e mantidos pela equipe de desenvolvimento. Eles não estão associados a um tenant específico (`company_id` é `NULL`). Exemplos incluem `super_admin` ou `support_agent`.
-   **Papéis Personalizados:** São papéis específicos de um tenant, que podem ser criados e gerenciados pelos administradores desse tenant. Eles sempre estão associados a uma `company_id` e permitem que as empresas customizem as permissões de seus próprios usuários.
