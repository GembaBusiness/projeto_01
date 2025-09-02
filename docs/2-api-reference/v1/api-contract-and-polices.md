# Contratos e Políticas da API

Este documento formaliza os contratos e as políticas que governam a interação com a API, garantindo consistência, performance e uso justo dos recursos.

## 7.1. Contrato de Consulta (Querying)

Para garantir uma experiência previsível e performática, todas as consultas a coleções de recursos DEVEM aderir ao seguinte contrato.

### 7.1.1. Paginação
-   **Obrigatoriedade:** A paginação é obrigatória.
-   **Parâmetros:** `page` (página, começando em 1) e `pageSize` (itens por página).
-   **Exemplo:** `GET /rest/v1/invoices?page=2&pageSize=25`

### 7.1.2. Ordenação
-   **Parâmetro:** `sort` (e.g., `sort=-created_at`).
-   **Sintaxe:** Prefixo `-` para descendente.

### 7.1.3. Filtros
-   **Sintaxe:** Filtros seguem a sintaxe `postgrest-js` (e.g., `status=eq.paid`).
-   **Soft Deletes:** Por padrão, as consultas DEVEM excluir itens marcados como "deletados" (com `deleted_at` preenchido). Para incluir itens deletados, um parâmetro explícito `include_deleted=true` pode ser usado.

## 7.2. Limites de Payload (Payload Size)

-   **Tamanho de Página Padrão:** 25.
-   **Tamanho de Página Máximo:** 100. Requisições acima deste limite receberão um erro `400 Bad Request`.
-   **Limite de Upload:** O corpo de uma requisição `POST`/`PUT` é limitado a **1MB**.

## 7.3. Política de Quotas e Limites de Uso

A verificação de quotas (e.g., número máximo de usuários por plano) NÃO é implementada via RLS.

-   **Justificativa:** RLS é para segurança de dados, não para lógica de negócio complexa como contagem de recursos, que seria ineficiente.
-   **Implementação:** A verificação de quotas é realizada na **lógica de negócio** (Funções de Banco de Dados RPC ou Edge Functions) antes da inserção de um novo recurso.
-   **Rastreabilidade:** A definição de quais quotas se aplicam a cada plano faz parte dos requisitos de faturamento.
    -   **Link para Requisitos:** [FR-004-billing-and-subscriptions.md](./04-functional-requirements/FR-004-billing-and-subscriptions.md)
