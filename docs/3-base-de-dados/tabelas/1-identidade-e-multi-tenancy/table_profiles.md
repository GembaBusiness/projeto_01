# Tabela: `profiles`

**Finalidade e Justificativa:**
Armazena os dados públicos do perfil de um utilizador, como nome completo e avatar. Esta tabela estende a tabela `auth.users` do Supabase, permitindo adicionar campos personalizados sem modificar a estrutura de autenticação principal. A relação 1-para-1 é mantida por um trigger, garantindo a consistência dos dados do utilizador.

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


-- Trigger para garantir que um perfil é criado quando um novo utilizador se regista (em definição).
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
- **`select`**: O utilizador autenticado pode ver seu perfil e utilizador (Adm) pode ver outros utilizadores.
- **`insert`**: A inserção é dividida em dois momento: 
  ### Cadastro inicial do utilizador/empresa  controlada pela função `create_company_and_profile`, que é chamada por uma Edge Function `create_company_and_user`
  ### Cadastro de utilizadores pelo 'Admin'. (Em definição)
 Os utilizadores não podem inserir perfis diretamente.
- **`update`**: Um utilizador só pode atualizar o seu próprio perfil (`auth.uid() = id`).
- **`delete`**: A remoção é gerida por `ON DELETE CASCADE` a partir da tabela `auth.users`.

## Notas
- ID Vinculado à Autenticação: O id do perfil é o mesmo user_id do sistema de autenticação, criando uma ligação direta e fundamental.
- Prevenção de Duplicidade: O sistema verifica ativamente se um perfil com o id do utilizador já existe antes de tentar uma nova inserção, evitando duplicados.
- Esta tabela não armazena informações sensíveis ou de autenticação, apenas dados de perfil públicos.
