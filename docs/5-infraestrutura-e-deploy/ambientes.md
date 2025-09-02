# Ambientes

Para garantir um processo de desenvolvimento e deploy estável e seguro, utilizamos múltiplos ambientes. Cada ambiente tem um propósito específico e está isolado dos outros.

## 1. Ambiente de Desenvolvimento (Local)

- **Propósito**: Usado por cada desenvolvedor na sua própria máquina para desenvolver novas funcionalidades, corrigir bugs e experimentar.
- **Infraestrutura**:
  - **Frontend**: Servidor de desenvolvimento local (`npm run dev`).
  - **Backend**: Instância do Supabase a correr localmente via Docker (`supabase start`).
- **Base de Dados**: A base de dados é local e pode ser reiniciada a qualquer momento (`supabase db reset`). Os dados são tipicamente de teste (seeds).
- **Deploy**: Não aplicável. O código é executado diretamente na máquina do desenvolvedor.

---

## 2. Ambiente de Staging (Pré-produção)

- **Propósito**: Um espelho do ambiente de produção. Usado para testar as funcionalidades de forma integrada antes de as lançar para os utilizadores finais. É aqui que a equipa de QA (Quality Assurance) e os stakeholders podem rever as alterações.
- **URL**: `staging.nome-do-projeto.com`
- **Infraestrutura**:
  - **Frontend**: Deployado na [Vercel/Netlify] ligado à branch `develop` ou `main`.
  - **Backend**: Um projeto Supabase Cloud dedicado para Staging.
- **Base de Dados**: A base de dados de Staging é separada da de produção. Periodicamente, pode ser restaurada a partir de um backup da produção para garantir que os dados são realistas (com anonimização de dados sensíveis).
- **Deploy**: O deploy para Staging é automático. Cada `push` ou `merge` para a branch `develop` (ou `main`) aciona um workflow de CI/CD que faz o deploy para este ambiente.

---

## 3. Ambiente de Produção (Production)

- **Propósito**: O ambiente "ao vivo" que os nossos utilizadores finais utilizam.
- **URL**: `app.nome-do-projeto.com` ou `www.nome-do-projeto.com`
- **Infraestrutura**:
  - **Frontend**: Deployado na [Vercel/Netlify] a partir de uma branch protegida (`main` ou `master`).
  - **Backend**: O projeto principal do Supabase Cloud.
- **Base de Dados**: A base de dados de produção. O acesso direto é estritamente limitado. Todas as alterações ao schema devem ser feitas através de migrações e do processo de CI/CD.
- **Deploy**: O deploy para produção é um processo manual ou semi-automático. Normalmente, é acionado após a criação de uma `tag` de release (e.g., `v1.2.0`) na branch principal. Isto garante que apenas código testado e aprovado chegue à produção.
