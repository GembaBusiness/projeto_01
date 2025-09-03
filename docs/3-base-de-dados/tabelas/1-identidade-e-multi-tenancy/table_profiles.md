# Tabela: `profiles`

**Finalidade e Justificativa:**
Armazena os dados públicos do perfil de um utilizador, como nome completo e avatar. Esta tabela estende a tabela `auth.users` do Supabase, permitindo adicionar campos personalizados sem modificar a estrutura de autenticação principal. A relação 1-para-1 é mantida por um trigger, garantindo a consistência dos dados do utilizador.

**DDL (SQL):**
```sql
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE public.profiles IS 'Armazena os dados públicos do perfil de um utilizador. Esta tabela é uma extensão da tabela auth.users do Supabase.';

-- Trigger para garantir que um perfil é criado quando um novo utilizador se regista.
-- A função handle_new_user() insere um novo registo em public.profiles.
-- (Ver documentação da função para mais detalhes)

-- Trigger para atualizar o timestamp `updated_at` em cada atualização.
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE moddatetime (updated_at);
```

**Campos e Restrições:**
- `id` (UUID, PK, FK): Chave primária que também é uma chave estrangeira para `auth.users(id)`. Garante a relação 1-para-1.
- `full_name` (TEXT): O nome completo do utilizador.
- `avatar_url` (TEXT): O URL para a imagem de avatar do utilizador.
- `updated_at` (TIMESTAMPTZ): Carimbo de data/hora da última atualização do perfil.

## Políticas de Row Level Security (RLS)
- **`select`**: Qualquer utilizador autenticado pode ver os perfis de outros utilizadores.
- **`insert`**: A inserção é controlada pela função `handle_new_user`, que é chamada por um trigger com `security definer` privileges. Os utilizadores não podem inserir perfis diretamente.
- **`update`**: Um utilizador só pode atualizar o seu próprio perfil (`auth.uid() = id`).
- **`delete`**: A remoção é gerida por `ON DELETE CASCADE` a partir da tabela `auth.users`.

## Notas
- A criação de perfis é automatizada através de um trigger (`handle_new_user`) na tabela `auth.users`.
- O campo `updated_at` é atualizado automaticamente por um trigger.
- Esta tabela não armazena informações sensíveis ou de autenticação, apenas dados de perfil públicos.
