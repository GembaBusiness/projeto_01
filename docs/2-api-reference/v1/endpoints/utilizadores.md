# Recurso: Utilizadores (Profiles)

Endpoints para gerir os perfis dos utilizadores.

**URL Base**: `/rest/v1/profiles`

**Nota Importante**: A tabela `profiles` contém dados públicos e semi-públicos dos utilizadores. Ela é uma extensão da tabela `auth.users` do Supabase, que contém as informações de autenticação (email, password hash). A ligação entre elas é feita pelo `id` do utilizador.

---

## `GET /profiles`

Recupera uma lista de perfis. Por razões de segurança, esta consulta deve ser restrita. Um caso de uso comum é um administrador a ver os utilizadores da sua própria empresa.

**Parâmetros de Query:**
- `select=id,full_name,avatar_url`: Selecionar campos específicos.
- `id=eq.{user_id}`: Obter um perfil de utilizador específico.

**Exemplo de Resposta (200 OK):**
```json
[
  {
    "id": "a1b2c3d4-e5f6-g7h8-i9j0-k1l2m3n4o5p6",
    "updated_at": "2023-10-27T11:00:00Z",
    "full_name": "João da Silva",
    "avatar_url": "https://example.com/avatar.png"
  }
]
```

---

## `PATCH /profiles?id=eq.{user_id}`

Atualiza o perfil do utilizador autenticado. A Row Level Security garante que um utilizador só pode atualizar o seu próprio perfil.

**Corpo da Requisição (JSON):**
```json
{
  "full_name": "João Pereira da Silva",
  "avatar_url": "https://example.com/new_avatar.png"
}
```

**Exemplo de Resposta (204 No Content):**
Indica que a atualização foi bem-sucedida.

---

### Outras Operações

- **Criação (`POST`)**: A criação de um `profile` é geralmente automatizada através de um `trigger` na base de dados que observa inserções na tabela `auth.users`. Quando um novo utilizador se regista, o seu perfil é criado automaticamente.
- **Remoção (`DELETE`)**: A remoção de um perfil também é tipicamente gerida por `triggers` ou políticas de `CASCADE` a partir da tabela `auth.users` para manter a consistência dos dados. Um utilizador pode apagar a sua própria conta, o que desencadearia este processo.
