# 8. Operações e Testes

Este documento descreve as práticas operacionais, de monitoramento e a estratégia de testes para garantir a saúde e a qualidade contínua do sistema.

## 8.1. Observabilidade e Suporte

### 8.1.1. Logs Estruturados
-   **Padrão:** Todos os logs gerados por Edge Functions ou outros processos de backend DEVEM seguir um formato de log estruturado (JSON), contendo no mínimo `timestamp`, `level`, `message`, e `context`.
-   **Justificativa:** Logs estruturados permitem a busca, filtragem e análise eficientes em ferramentas de observabilidade.

### 8.1.2. Monitoramento e Alarmes
-   **Fluxos Críticos:** Os fluxos de negócio mais críticos (webhooks de pagamento, saga de cadastro) DEVEM ser monitorados ativamente.
-   **Alarmes:** Alarmes DEVEM ser configurados para taxas de erro anormais ou falhas de compensação na saga, notificando a equipa de desenvolvimento.

### 8.1.3. Runbook Operacional
-   **Definição:** Um runbook DEVE ser mantido para documentar os procedimentos operacionais padrão.
-   **Conteúdo Mínimo:**
    -   Procedimento para lidar com falhas em webhooks de pagamento.
    -   Procedimento para executar a [exclusão permanente de dados de um tenant](./05-non-functional-requirements.md#rnf-063-exclusãoanonimização-de-dados-hard-delete).
    -   Procedimento para testar a [restauração de backups](./05-non-functional-requirements.md#rnf-052-backup-e-restauração).

## 8.2. Estratégia de Testes

Para garantir a qualidade e prevenir regressões, a seguinte estratégia de testes deve ser adotada.

### 8.2.1. Testes de Unidade e Integração
-   **Foco:** Lógica de negócio em Edge Functions e Funções de Banco de Dados (RPC).
-   **Ferramentas:** Deno testing framework, pg_prove.

### 8.2.2. Cenários de Teste Críticos (End-to-End)
Os seguintes cenários DEVEM ser validados através de testes E2E. Cada cenário testa um [padrão de arquitetura](./01-system-architecture.md#15-padrões-de-arquitetura) fundamental.

-   **Teste de Políticas RLS:**
    -   **Cenário:** Verificar que um usuário da empresa A não consegue aceder a dados da empresa B.
    -   **Link para o Padrão:** [Arquitetura Híbrida RBAC + ABAC](./01-system-architecture.md#151-arquitetura-híbrida-rbac--abac).

-   **Teste de Idempotência:**
    -   **Cenário:** Disparar uma requisição crítica (e.g., pagamento) múltiplas vezes com a mesma chave de idempotência e verificar que a operação é executada apenas uma vez.
    -   **Link para o Padrão:** [Política de Idempotência](./01-system-architecture.md#153-política-de-idempotência).

-   **Teste de Quotas:**
    -   **Cenário:** Levar um tenant ao seu limite de recursos (e.g., usuários) e verificar que a próxima tentativa de criação é bloqueada.
    -   **Link para a Política:** [Política de Quotas e Limites de Uso](./07-api-contracts-and-policies.md#73-política-de-quotas-e-limites-de-uso).

-   **Teste de Concorrência:**
    -   **Cenário:** Simular duas atualizações concorrentes sobre o mesmo recurso e verificar que a política de concorrência otimista impede a sobreposição de dados.
    -   **Link para a Política:** [Confiabilidade e Resiliência](./05-non-functional-requirements.md#rnf-051-concorrência-otimista).

-   **Teste de Saga (Cadastro):**
    -   **Cenário:** Simular uma falha durante a saga de cadastro (e.g., falha ao criar o cliente no Stripe) e verificar que a compensação (e.g., apagar o usuário no Auth) é executada com sucesso.
    -   **Link para o Padrão:** [Orquestração de Registo (Padrão Saga)](./01-system-architecture.md#152-orquestração-de-registo-padrão-saga).
