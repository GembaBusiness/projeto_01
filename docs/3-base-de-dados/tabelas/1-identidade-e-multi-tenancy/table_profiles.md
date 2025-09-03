# Tabela: `profiles`

**Finalidade e Justificativa:**
Esta tabela estende a tabela `auth.users` do Supabase. A separação é uma best practice que desacopla os dados de autenticação (geridos pelo Supabase) dos dados de perfil público da aplicação. A relação 1-para-1 com `auth.users` é garantida pela PK ser também uma FK. O `ON DELETE CASCADE` assegura que, se um utilizador for apagado do sistema de autenticação, o seu perfil seja automaticamente removido, mantendo a consistência dos dados.

**DDL (SQL):**
```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  job_title TEXT,
  phone_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.profiles IS 'Armazena os dados públicos do perfil do utilizador, estendendo a tabela auth.users.';
```

**Campos e Restrições:**
-   `id` (UUID, PK, FK): Chave primária que referencia `auth.users.id`, criando a relação 1-para-1 e garantindo a integridade referencial.
-   `full_name`, `avatar_url`, etc.: Campos de perfil que podem ser geridos pela aplicação.

## Políticas de Row Level Security (RLS)
- **`select`**: Qualquer utilizador autenticado pode ver os perfis de outros utilizadores.
- **`insert`**: A inserção é controlada por `security definer functions` (um trigger `on_auth_user_created`), não diretamente pelo utilizador.
- **`update`**: Um utilizador só pode atualizar o seu próprio perfil (`auth.uid() = id`).
- **`delete`**: A remoção é gerida por `CASCADE` a partir da tabela `auth.users`.

## Notas
- A criação de um perfil é automatizada por um `trigger` no banco de dados que observa a tabela `auth.users`.
