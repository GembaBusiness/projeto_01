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
