# Template de Software B2B - WeWeb + Supabase

## Descrição
Este repositório contém um template de software reutilizável para a criação de sistemas web B2B multi-tenant. O objetivo é fornecer uma base sólida e bem documentada, acelerando o desenvolvimento de novos projetos que sigam este modelo de negócio.

A stack tecnológica foi escolhida para maximizar a agilidade e minimizar a necessidade de código complexo, focando na lógica de negócio.

## Funcionalidades Principais
-   **Arquitetura Híbrida RBAC + ABAC:** Controle de acesso robusto que combina papéis (o que um usuário pode fazer) com atributos (sobre quais dados pode atuar), implementado via RLS para garantir que os usuários só acessem os dados corretos.
-   **Monetização e Gestão de Assinaturas:** Lógica completa para gestão de planos, funcionalidades e assinaturas, integrada a um gateway de pagamentos para processar cobranças.
-   **Segurança de Ponta a Ponta (MFA, RLS):** Múltiplas camadas de segurança, incluindo autenticação multi-fator (MFA/TOTP), Row Level Security (RLS) para isolamento de dados, e políticas de sessão.
-   **Trilha de Auditoria para Compliance:** Registro detalhado de atividades críticas do sistema, essencial para auditoria e conformidade com regulamentações como LGPD e GDPR.
-   **Arquitetura Multi-Tenant:** Desenhado desde o início para servir múltiplas empresas (tenants) com total isolamento e segurança dos seus dados.
-   **Gestão de Usuários e Convites:** Ferramentas para administradores de tenants gerenciarem seus próprios usuários, incluindo um fluxo de convites.

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
