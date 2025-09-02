# Pipeline de CI/CD

O nosso pipeline de Integração Contínua e Entrega Contínua (CI/CD) é gerido através de **GitHub Actions**. O ficheiro de configuração principal pode ser encontrado em `.github/workflows/deploy.yml`.

O objetivo do pipeline é automatizar os testes, a build e o deploy da nossa aplicação, garantindo que o código é entregue de forma rápida e fiável.

## Gatilhos do Pipeline (Triggers)

O pipeline é acionado pelos seguintes eventos:

1.  **Push para Pull Request**: Quando um desenvolvedor abre ou atualiza um Pull Request (PR) para a branch `main` ou `develop`.
2.  **Merge para `develop`**: Quando um PR é aprovado e o seu código é merged na branch `develop`.
3.  **Criação de Tag**: Quando uma nova tag de versão (e.g., `v1.2.0`) é criada na branch `main`.

---

## Estágios do Pipeline

### 1. Workflow de Pull Request (CI)

Este workflow corre em cada `push` para um PR. O seu objetivo é a **Integração Contínua**.

- **Linting**: Verifica se o código segue as nossas convenções de estilo.
  - `npm run lint`
- **Testes Unitários e de Integração**: Executa a suite de testes automatizados.
  - `npm test`
- **Build da Aplicação**: Compila o código do frontend para garantir que não existem erros de build.
  - `npm run build`

> Se algum destes passos falhar, o PR é bloqueado e não pode ser merged até que os problemas sejam corrigidos. Isto garante a qualidade do código na branch principal.

---

### 2. Workflow de Deploy para Staging

Este workflow corre quando o código é merged na branch `develop`.

- **Executa todos os passos do CI**: Garante que o código continua a passar em todos os testes.
- **Deploy para Staging**: Se todos os testes passarem, o workflow faz o deploy da aplicação para o nosso ambiente de Staging na [Vercel/Netlify].
  - Utiliza a CLI da Vercel para fazer o deploy.
- **Notificação**: Envia uma notificação para um canal do Slack a informar que uma nova versão foi deployada em Staging.

---

### 3. Workflow de Deploy para Produção

Este workflow é acionado **manualmente** (ou pela criação de uma tag) e faz o deploy para o ambiente de produção.

- **Executa todos os passos do CI**: Uma verificação final de segurança.
- **Deploy para Produção**: Faz o deploy da aplicação para o ambiente de produção na [Vercel/Netlify].
  - O deploy de produção na Vercel aponta o alias de produção para a nova build.
- **Migrações da Base de Dados (se aplicável)**: Se existirem novas migrações na pasta `supabase/migrations`, este passo teria de ser coordenado. (Atualmente, as migrações do Supabase são aplicadas manualmente ou através de um processo separado para maior segurança).
- **Notificação**: Envia uma notificação para o Slack a informar sobre o sucesso do deploy em produção, incluindo a tag da versão.
