# Tabela: `profiles`

Armazena os dados públicos do perfil de um utilizador. Esta tabela é uma extensão da tabela `auth.users` do Supabase.

**Schema**: `public`

## Relação com `auth.users`

Um `trigger` na base de dados (`on_auth_user_created`) é responsável por criar uma entrada nesta tabela sempre que um novo utilizador se regista e uma nova entrada é adicionada a `auth.users`. A relação é 1-para-1.

## Colunas

| Nome da Coluna | Tipo de Dados | Descrição                                                                 | Constraints                                   |
| :------------- | :------------ | :------------------------------------------------------------------------ | :-------------------------------------------- |
| `id`           | `uuid`        | Identificador único do utilizador. Este valor é o mesmo que em `auth.users.id`. | Chave Primária, Chave Estrangeira para `auth.users(id)` |
| `updated_at`   | `timestamptz` | Carimbo de data/hora da última atualização do perfil.                     | `default: now()`                              |
| `full_name`    | `text`        | O nome completo do utilizador.                                            | Pode ser `NULL`                               |
| `avatar_url`   | `text`        | O URL para a imagem de avatar do utilizador.                              | Pode ser `NULL`                               |

## Índices

- `profiles_pkey` (Índice da Chave Primária em `id`)

## Políticas de Row Level Security (RLS)

- **`select`**: Qualquer utilizador autenticado pode ver os perfis de outros utilizadores. (Pode ser restringido se a privacidade for uma preocupação maior).
- **`insert`**: A inserção é controlada por `security definer functions` (o trigger `on_auth_user_created`), não diretamente pelo utilizador.
- **`update`**: Um utilizador só pode atualizar o seu próprio perfil (`auth.uid() = id`).
- **`delete`**: A remoção é gerida por `CASCADE` a partir da tabela `auth.users`.

## Triggers

- **`handle_new_user`**: Quando um novo utilizador é criado em `auth.users`, esta função `trigger` cria a entrada correspondente em `public.profiles`.
- **`update_profile_updated_at`**: Atualiza automaticamente o campo `updated_at` sempre que um registo é modificado.
