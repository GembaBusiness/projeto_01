# 7. Contratos e Políticas da API

Este documento formaliza os contratos e as políticas que governam a interação com a API do Supabase, garantindo consistência, performance e uso justo dos recursos.

## 7.1. Contrato de Consulta (Querying)

Para garantir uma experiência previsível e performática na leitura de dados, todas as consultas a coleções de recursos (e.g., listas de clientes, faturas) DEVEM aderir ao seguinte contrato.

### 7.1.1. Paginação
-   **Obrigatoriedade:** A paginação é obrigatória para todos os endpoints que retornam uma lista de recursos.
-   **Parâmetros:** A paginação é controlada pelos parâmetros de query `page` (número da página, começando em 1) e `pageSize` (número de itens por página).
-   **Exemplo:** `GET /rest/v1/invoices?page=2&pageSize=25`

### 7.1.2. Ordenação
-   **Parâmetro:** A ordenação é controlada pelo parâmetro de query `sort`.
-   **Sintaxe:** O valor do parâmetro deve ser o nome do campo a ser ordenado. A direção é especificada por um prefixo: `-` para descendente (DESC) e ausência de prefixo para ascendente (ASC).
-   **Exemplo:** `GET /rest/v1/invoices?sort=-created_at` (ordena pela data de criação, da mais recente para a mais antiga).

### 7.1.3. Filtros
-   **Sintaxe:** Os filtros são aplicados usando a sintaxe de `postgrest-js`, permitindo o uso de operadores como `eq`, `neq`, `gt`, `lt`, `like`, etc.
-   **Exemplo:** `GET /rest/v1/invoices?status=eq.paid&total=gt.1000` (retorna faturas pagas com valor maior que 1000).

## 7.2. Limites de Payload (Payload Size)

Para proteger a API contra sobrecarga e garantir tempos de resposta rápidos, aplicam-se os seguintes limites de payload:

-   **Tamanho de Página Padrão (`pageSize`):** Se não especificado, o tamanho padrão da página é **25**.
-   **Tamanho de Página Máximo (`pageSize`):** O valor máximo permitido para `pageSize` é **100**. Requisições que solicitarem um `pageSize` maior resultarão em um erro `400 Bad Request`.
-   **Limite de Upload:** O tamanho máximo para o corpo de uma requisição `POST` ou `PUT` é de **1MB**. Para uploads de ficheiros maiores, deve ser usado o Supabase Storage.

## 7.3. Política de Quotas e Limites de Uso

A verificação de quotas e limites (e.g., número máximo de usuários por plano, número de projetos permitidos) NÃO é implementada via Row Level Security (RLS).

-   **Justificativa:** A RLS é projetada para segurança de dados (o que o usuário pode ver), e não para lógica de negócio complexa como a contagem de recursos. Usar RLS para quotas seria ineficiente e complexo de manter.
-   **Implementação:** A verificação de quotas é realizada na **lógica de negócio**, preferencialmente dentro de Funções de Banco de Dados (RPC) ou Edge Functions.
    -   **Fluxo:** Antes de criar um novo recurso (e.g., um novo usuário), a função verifica se o tenant já atingiu o limite definido pelo seu plano (`subscriptions.plan_id`). Se o limite foi atingido, a operação é rejeitada com uma mensagem de erro apropriada (e.g., `403 Forbidden` ou `422 Unprocessable Entity`).
