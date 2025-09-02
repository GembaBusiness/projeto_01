# Recurso: Empresas (Companies)

Endpoints para gerir as empresas ou organizações.

**URL Base**: `/rest/v1/companies`

---

## `GET /companies`

Recupera uma lista de empresas. Apenas as empresas às quais o utilizador autenticado tem acesso (via `memberships`) serão retornadas, graças à Row Level Security.

**Parâmetros de Query:**
- `select`: Permite especificar os campos a serem retornados (e.g., `id,name`).
- `id=eq.{company_id}`: Filtrar por um ID específico.

**Exemplo de Resposta (200 OK):**
```json
[
  {
    "id": "c1b2a3d4-e5f6-7890-1234-567890abcdef",
    "created_at": "2023-10-27T10:00:00Z",
    "name": "Empresa Exemplo"
  }
]
```

---

## `POST /companies`

Cria uma nova empresa. Este endpoint normalmente é chamado através de uma função de base de dados (`create_company_and_profile`) para garantir que o utilizador que cria a empresa é automaticamente definido como o seu primeiro membro/administrador.

**Corpo da Requisição (JSON):**
```json
{
  "name": "Nova Empresa Inc."
}
```

**Exemplo de Resposta (201 Created):**
O cabeçalho `Location` conterá a URL para o novo recurso. O corpo da resposta pode variar dependendo da configuração do Supabase (`Prefer: return=representation`).

---

## `PATCH /companies?id=eq.{company_id}`

Atualiza os dados de uma empresa existente. O utilizador deve ter permissões adequadas (e.g., ser `admin` da empresa) para realizar esta operação.

**Corpo da Requisição (JSON):**
```json
{
  "name": "Nome da Empresa Atualizado"
}
```

**Exemplo de Resposta (204 No Content):**
Indica que a atualização foi bem-sucedida.

---

## `DELETE /companies?id=eq.{company_id}`

Remove uma empresa. Esta é uma operação destrutiva e deve ser usada com cuidado. O utilizador deve ter permissões de `admin` ou `owner`.

**Exemplo de Resposta (204 No Content):**
Indica que a empresa foi removida com sucesso.
