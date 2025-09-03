# Tabela: `companies`

Armazena as informações sobre as empresas ou organizações no sistema. Cada empresa funciona como um "tenant" isolado.

**Schema**: `public`

## Colunas

| Nome da Coluna | Tipo de Dados | Descrição                                                                 | Constraints                                   |
| :------------- | :------------ | :------------------------------------------------------------------------ | :-------------------------------------------- |
| `id`           | `uuid`        | Identificador único da empresa.                                           | Chave Primária, `default: uuid_generate_v4()` |
| `created_at`   | `timestamptz` | Carimbo de data/hora de quando a empresa foi criada.                      | `default: now()`                              |
| `name`         | `text`        | O nome da empresa.                                                        | `NOT NULL`                                    |
| `owner_id`     | `uuid`        | O `id` do utilizador que é o proprietário da empresa.                     | Chave Estrangeira para `public.profiles(id)`  |

## Índices

- `companies_pkey` (Índice da Chave Primária em `id`)
- `companies_owner_id_fkey` (Índice da Chave Estrangeira em `owner_id`)

## Políticas de Row Level Security (RLS)

As políticas de RLS nesta tabela são cruciais para garantir que os utilizadores só possam ver e modificar as empresas às quais pertencem.

- **`select`**: Um utilizador pode ver uma empresa se existir um registo correspondente na tabela `memberships` que o ligue a essa empresa.
- **`insert`**: Um utilizador pode criar uma nova empresa.
- **`update`**: Um utilizador pode atualizar uma empresa se tiver o papel (`role`) de `admin` nessa empresa (verificado através da tabela `memberships`).
- **`delete`**: Apenas o `owner` da empresa (ou um super-administrador) pode apagar a empresa.

## Notas

- A coluna `owner_id` serve para definir uma propriedade clara, mas as permissões do dia-a-dia são geridas pela tabela `memberships` e os papéis (`roles`) definidos nela.
