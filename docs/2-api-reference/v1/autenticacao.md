# Autenticação (v1)

A nossa API utiliza o sistema de autenticação do Supabase, que é baseado em JSON Web Tokens (JWT). Para fazer chamadas para endpoints protegidos, precisa de incluir um `access_token` no cabeçalho da sua requisição.

## Como obter um Token

Para obter um token, o utilizador deve autenticar-se usando um dos métodos suportados (e.g., email/password, login social).

**Exemplo de requisição para login com email e password:**

`POST /auth/v1/token?grant_type=password`

**Cabeçalhos:**
- `apikey`: `SUPABASE_ANON_KEY`

**Corpo (Body) da Requisição (JSON):**
```json
{
  "email": "user@example.com",
  "password": "user-password"
}
```

**Resposta de Sucesso (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1Ni...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "a_long_refresh_token_string",
  "user": {
    "id": "user-uuid",
    "aud": "authenticated",
    "role": "authenticated",
    "email": "user@example.com",
    "created_at": "...",
    "updated_at": "..."
  }
}
```

## Como usar o Token

Depois de obter o `access_token`, deve enviá-lo em todas as requisições para endpoints protegidos no cabeçalho `Authorization`.

**Cabeçalhos:**
- `apikey`: `SUPABASE_ANON_KEY`
- `Authorization`: `Bearer <seu_access_token>`

## Refresh do Token

O `access_token` tem uma vida útil curta (normalmente 1 hora). Quando expirar, vai receber um erro `401 Unauthorized`. Pode usar o `refresh_token` (que tem uma vida útil mais longa) para obter um novo par de tokens sem pedir ao utilizador para fazer login novamente.

**Exemplo de requisição para refresh:**

`POST /auth/v1/token?grant_type=refresh_token`

**Corpo (Body) da Requisição (JSON):**
```json
{
  "refresh_token": "o_refresh_token_recebido_no_login"
}
```
