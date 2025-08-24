# Template de Software B2B - WeWeb + Supabase

## Descrição
Este repositório contém um template de software reutilizável para a criação de sistemas web B2B multi-tenant. O objetivo é fornecer uma base sólida e bem documentada, acelerando o desenvolvimento de novos projetos que sigam este modelo de negócio.

A stack tecnológica foi escolhida para maximizar a agilidade e minimizar a necessidade de código complexo, focando na lógica de negócio.

## Funcionalidades Principais
-   **Arquitetura Multi-Tenant:** Isolamento de dados seguro entre empresas (tenants) usando Row Level Security (RLS) do PostgreSQL.
-   **Autenticação Completa:** Fluxos de cadastro, login e recuperação de senha prontos para uso.
-   **Controle de Acesso Baseado em Papéis (RBAC):** Sistema de papéis e permissões para controlar o que cada usuário pode ver e fazer.
-   **Gestão de Empresa:** Funcionalidades para administradores convidarem e gerenciarem usuários.
-   **Menu de Navegação Dinâmico:** O menu se adapta de acordo com as permissões do usuário.

## Stack Tecnológica
-   **Frontend:** [WeWeb](https://weweb.io/) (Plataforma Low-Code)
-   **Backend:** [Supabase](https://supabase.com/) (Backend-as-a-Service com PostgreSQL)

## Começando
Para configurar o seu ambiente de desenvolvimento e começar a usar este template, por favor, siga o nosso guia de configuração.
-   **[Guia de Configuração do Ambiente](./docs/02-environment-setup.md)**

## Documentação
Toda a documentação do projeto, incluindo arquitetura, modelo de dados e requisitos, está centralizada no diretório `docs/`.
-   **[Acessar a Documentação](./docs/)**

## Como Contribuir
Estamos abertos a contribuições da comunidade! Se você deseja contribuir, por favor, leia nosso guia de contribuição.
-   **[Guia de Contribuição](./CONTRIBUTING.md)**

## Licença
Este projeto é distribuído sob a Licença MIT. Veja o ficheiro `LICENSE` para mais detalhes.
-   **[Ver Licença](./LICENSE)**
