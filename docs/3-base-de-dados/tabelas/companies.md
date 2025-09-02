# Tabela: `companies`

**Finalidade e Justificativa:**
Esta é a entidade central da arquitetura multi-tenant. Cada registo representa uma empresa cliente (um "tenant"), servindo como a âncora para o isolamento de dados. A coluna `status` é fundamental para gerir o ciclo de vida do cliente (ex: suspender o acesso por falta de pagamento). Para a criação de empresas, a idempotência será garantida inicialmente pela restrição `UNIQUE` na coluna `cnpj`. A coluna `idempotency_key` é mantida no esquema como uma salvaguarda para futuros processos de criação mais complexos que possam envolver múltiplas operações.

**DDL (SQL):**
```sql
CREATE TYPE public.company_status AS ENUM ('pending_confirmation', 'active', 'suspended', 'deactivated');

CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  cnpj TEXT UNIQUE,
  logo_url TEXT,
  status public.company_status NOT NULL DEFAULT 'active',
  idempotency_key UUID UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.companies IS 'Armazena as informações de cada empresa cliente (tenant) no sistema.';
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária. Usar UUID evita a enumeração de clientes e conflitos em ambientes distribuídos.
-   `name` (TEXT, NOT NULL): Nome da empresa. É obrigatório para identificação.
-   `cnpj` (TEXT, UNIQUE): Documento de identificação fiscal. É `UNIQUE` para garantir que uma mesma empresa não seja registada múltiplas vezes.
-   `logo_url` (TEXT): URL para o logótipo da empresa.
-   `status` (ENUM, NOT NULL): Controla o estado da conta, essencial para a lógica de negócio (ex: acesso, faturação).
-   `idempotency_key` (UUID, UNIQUE): Chave de idempotência para a criação da empresa, preenchida no momento do registo para evitar duplicados.
-   `created_at`, `updated_at`, `deleted_at`: Timestamps para controlo de ciclo de vida e soft delete.

## Políticas de Row Level Security (RLS)
As políticas de RLS nesta tabela são cruciais para garantir que os utilizadores só possam ver e modificar as empresas às quais pertencem.

- **`select`**: Um utilizador pode ver uma empresa se existir um registo correspondente na tabela `memberships` que o ligue a essa empresa.
- **`insert`**: Um utilizador pode criar uma nova empresa.
- **`update`**: Um utilizador pode atualizar uma empresa se tiver o papel (`role`) de admin nessa empresa (verificado através da tabela `memberships`).
- **`delete`**: Apenas o owner da empresa (ou um super-administrador) pode apagar a empresa.

## Notas
A coluna owner_id serve para definir uma propriedade clara, mas as permissões do dia-a-dia são geridas pela tabela memberships e os papéis (roles) definidos nela.
