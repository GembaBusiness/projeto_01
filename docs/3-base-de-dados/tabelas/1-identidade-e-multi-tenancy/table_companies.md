# Tabela: `companies`

**Finalidade e Justificativa:**
Armazena as informações sobre as empresas ou organizações no sistema. Cada empresa funciona como um "tenant" isolado, o que é fundamental para a arquitetura multi-tenancy da aplicação. A tabela `companies` é o ponto central para associar utilizadores, departamentos e outros recursos a uma organização específica.

**DDL (SQL):**
```sql
CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES public.profiles(id),
  created_at TIMESTAMptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.companies IS 'Armazena as informações sobre as empresas ou organizações no sistema. Cada empresa funciona como um "tenant" isolado.';

-- Índice para a chave estrangeira owner_id para otimizar a busca de empresas por proprietário.
CREATE INDEX idx_companies_owner_id ON public.companies(owner_id);
```

**Campos e Restrições:**
- `id` (UUID, PK): Chave primária da empresa.
- `name` (TEXT, NOT NULL): O nome da empresa.
- `owner_id` (UUID, NOT NULL, FK): Referencia o `id` do utilizador que é o proprietário da empresa na tabela `public.profiles`.
- `created_at` (TIMESTAMPTZ, NOT NULL): Carimbo de data/hora de quando a empresa foi criada.

## Políticas de Row Level Security (RLS)
- **`select`**: Um utilizador pode ver uma empresa se existir um registo correspondente na tabela `memberships` que o ligue a essa empresa.
- **`insert`**: Um utilizador pode criar uma nova empresa.
- **`update`**: Um utilizador pode atualizar uma empresa se tiver o papel (`role`) de `admin` nessa empresa (verificado através da tabela `memberships`).
- **`delete`**: Apenas o `owner` da empresa (ou um super-administrador) pode apagar a empresa.

## Notas
- A coluna `owner_id` serve para definir uma propriedade clara, mas as permissões do dia-a-dia são geridas pela tabela `memberships` e os papéis (`roles`) definidos nela.
- A tabela `companies` é a base do isolamento de dados entre diferentes "tenants".
