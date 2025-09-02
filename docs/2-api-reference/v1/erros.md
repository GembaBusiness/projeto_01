# Códigos de Erro (v1)

A API utiliza códigos de status HTTP padrão para indicar o sucesso ou falha de uma requisição.

## Códigos de Sucesso

- `200 OK`: A requisição foi bem-sucedida. O corpo da resposta contém os dados solicitados.
- `201 Created`: O recurso foi criado com sucesso. O URL do novo recurso está no cabeçalho `Location`.
- `204 No Content`: A requisição foi bem-sucedida, mas não há conteúdo para retornar (usado para `PATCH` ou `DELETE`).

## Códigos de Erro do Cliente (4xx)

- `400 Bad Request`: A requisição está malformada. Pode ser devido a JSON inválido ou parâmetros em falta. O corpo da resposta geralmente contém uma mensagem de erro específica.
  ```json
  { "msg": "Json body invalid" }
  ```
- `401 Unauthorized`: Falha na autenticação. O token de acesso está em falta, é inválido ou expirou.
  ```json
  { "message": "Invalid JWT" }
  ```
- `403 Forbidden`: O utilizador está autenticado, mas não tem permissão para realizar a ação solicitada. Isto é frequentemente imposto pela Row Level Security.
- `404 Not Found`: O recurso solicitado não existe.
- `406 Not Acceptable`: Ocorreu um erro ao tentar realizar a ação, como violar uma `constraint` da base de dados.
  ```json
  {
    "code": "23505",
    "details": "A key value violates a unique constraint \"companies_pkey\".",
    "hint": null,
    "message": "duplicate key value violates unique constraint \"companies_pkey\""
  }
  ```
- `429 Too Many Requests`: O cliente enviou demasiadas requisições num determinado período de tempo (rate limiting).

## Códigos de Erro do Servidor (5xx)

- `500 Internal Server Error`: Ocorreu um erro inesperado no servidor. A equipa de desenvolvimento é notificada automaticamente. Se o erro persistir, entre em contacto com o suporte.
- `502 Bad Gateway`: O servidor, enquanto atuava como um gateway, recebeu uma resposta inválida do servidor upstream.
- `503 Service Unavailable`: O serviço está temporariamente indisponível (e.g., por manutenção ou sobrecarga). Tente novamente mais tarde.
