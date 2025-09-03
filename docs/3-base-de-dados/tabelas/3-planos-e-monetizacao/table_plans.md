# Tabela: `plans`

**Finalidade e Justificativa:**
Define os pacotes comerciais (ex: Básico, Pro).

**DDL (SQL):**
```sql
CREATE TABLE public.plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler os planos.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar os planos.

## Notas
- Esta tabela define os pacotes comerciais do produto.
