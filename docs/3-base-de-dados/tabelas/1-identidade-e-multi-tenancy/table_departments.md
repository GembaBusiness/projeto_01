# Tabela: `departments`

**Finalidade e Justificativa:**
Armazena os departamentos específicos de cada empresa. A tabela está diretamente ligada a `companies`, garantindo que cada departamento pertença a um único tenant. A restrição `UNIQUE(name, company_id)` é crucial para evitar nomes de departamento duplicados dentro da mesma empresa, mantendo a organização dos dados. Um índice foi adicionado em `company_id` para otimizar consultas que filtram departamentos por empresa.

**DDL (SQL):**
```sql
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE(name, company_id)
);

COMMENT ON TABLE public.departments IS 'Armazena os departamentos de cada empresa.';

-- Índice para otimizar a busca de departamentos de uma empresa.
CREATE INDEX idx_departments_company_id ON public.departments(company_id);
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do departamento.
-   `name` (TEXT, NOT NULL): Nome do departamento (ex: "Financeiro", "Recursos Humanos").
-   `company_id` (UUID, NOT NULL, FK): Referencia a empresa à qual o departamento pertence.
-   `created_at`, `updated_at`, `deleted_at`: Timestamps para controlo de ciclo de vida e soft delete.
-   `UNIQUE(name, company_id)`: Garante que o nome do departamento seja único dentro de uma empresa.

## Políticas de Row Level Security (RLS)
- **`select`**: Um utilizador pode ver os departamentos de uma empresa da qual é membro.
- **`insert`**: Um administrador da empresa pode criar departamentos.
- **`update`**: Um administrador da empresa pode atualizar os departamentos.
- **`delete`**: Um administrador da empresa pode apagar os departamentos.

## Notas
- A unicidade do nome do departamento é garantida por empresa (`company_id`).
