# 8. Operações e Testes

Este documento descreve as práticas operacionais, de monitoramento e a estratégia de testes para garantir a saúde e a qualidade contínua do sistema.

## 8.1. Observabilidade e Suporte

### 8.1.1. Logs Estruturados
-   **Padrão:** Todos os logs gerados por Edge Functions ou outros processos de backend DEVEM seguir um formato de log estruturado (e.g., JSON).
-   **Conteúdo Mínimo:** Cada entrada de log DEVE incluir, no mínimo:
    -   `timestamp`: Hora do evento.
    -   `level`: Nível do log (e.g., `info`, `warn`, `error`).
    -   `message`: Mensagem descritiva.
    -   `context`: Um objeto contendo metadados relevantes (e.g., `function_name`, `user_id`, `company_id`, `correlation_id`).
-   **Justificativa:** Logs estruturados permitem a busca, filtragem e análise eficientes em ferramentas de observabilidade (e.g., Logflare, Datadog).

### 8.1.2. Monitoramento e Alarmes
-   **Fluxos Críticos:** Os fluxos de negócio mais críticos DEVEM ser monitorados ativamente.
-   **Alvos de Monitoramento:**
    1.  **Webhooks de Pagamento:** Monitorar a taxa de sucesso e falha dos webhooks recebidos do gateway de pagamentos. Um alarme DEVE ser disparado se a taxa de erro exceder um limiar definido.
    2.  **Fluxo de Cadastro (Saga):** Monitorar a taxa de sucesso e falha da saga de cadastro. Alarmes devem ser configurados para falhas na compensação.
    3.  **Performance da API:** Monitorar a latência e a taxa de erro dos endpoints mais importantes da API.
-   **Ferramentas:** Utilizar as ferramentas de monitoramento do Supabase e/ou integrar com serviços externos.

### 8.1.3. Runbook Operacional
-   **Definição:** Um runbook (ou playbook) DEVE ser mantido para documentar os procedimentos operacionais padrão.
-   **Conteúdo:** O runbook DEVE incluir, no mínimo, os procedimentos para:
    -   Lidar com um alarme de falha de webhook.
    -   Executar o procedimento de exclusão de dados de um tenant.
    -   Restaurar um backup do banco de dados.

## 8.2. Estratégia de Testes

Para garantir a qualidade e prevenir regressões, a seguinte estratégia de testes deve ser adotada.

### 8.2.1. Testes de Unidade e Integração
-   **Foco:** A lógica de negócio implementada em Edge Functions e Funções de Banco de Dados (RPC) DEVE ter cobertura de testes de unidade e integração.
-   **Ferramentas:** Utilizar o framework de testes do Deno para Edge Functions e o `pg_prove` ou similar para testes no banco de dados.

### 8.2.2. Cenários de Teste Críticos (End-to-End)
Os seguintes cenários DEVEM ser validados através de testes end-to-end (E2E) automatizados ou manuais antes de cada release em produção:

-   **Teste de Políticas RLS:**
    -   Verificar que um usuário `A` da empresa `A` não consegue ler, modificar ou apagar dados da empresa `B`.
    -   Verificar que um usuário sem o papel `admin` não consegue executar ações restritas a administradores.
-   **Teste de Idempotência:**
    -   Disparar a mesma requisição crítica (e.g., criação de recurso) múltiplas vezes com a mesma chave de idempotência e verificar que a operação é executada apenas uma vez.
-   **Teste de Quotas:**
    -   Levar um tenant ao seu limite de recursos (e.g., número de usuários).
    -   Verificar que a próxima tentativa de criar um recurso acima do limite é bloqueada com uma mensagem de erro apropriada.
-   **Teste de Concorrência:**
    -   Simular duas operações de atualização concorrentes sobre o mesmo recurso.
    -   Verificar que a política de concorrência otimista impede a sobreposição de dados e que uma das operações falha de forma controlada.
-   **Teste de Cache:**
    -   Verificar que, após uma atualização de dados, os caches relevantes (se houver) são invalidados e a UI reflete os dados atualizados.
