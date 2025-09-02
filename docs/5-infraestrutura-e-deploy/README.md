# 5. Infraestrutura e Deploy

Esta seção documenta a nossa infraestrutura, os diferentes ambientes e o processo de integração e entrega contínua (CI/CD).

## Filosofia

A nossa abordagem de DevOps visa a automação, a consistência entre ambientes e a capacidade de fazer deploy de forma rápida e segura.

## Ferramentas Principais

- **Hosting da Aplicação**: [Vercel / Netlify / AWS Amplify]
- **Backend e Base de Dados**: [Supabase Cloud]
- **CI/CD**: [GitHub Actions]
- **Monitoring**: [Sentry / Datadog]

## Conteúdo

- **[Ambientes](./ambientes.md)**: Uma explicação sobre os nossos diferentes ambientes (Desenvolvimento, Staging, Produção) e como eles são usados.
- **[CI/CD](./ci-cd.md)**: Uma descrição detalhada de como o nosso pipeline de CI/CD funciona, desde o `push` para uma branch até ao deploy em produção.
