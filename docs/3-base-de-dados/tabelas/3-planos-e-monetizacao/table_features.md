# Tabela: `features`

**Finalidade e Justificativa:**
Catálogo de todas as funcionalidades que podem ser ligadas/desligadas por um plano (feature flags). O `key` é a chave programática que o código usará para verificar se uma funcionalidade está ativa para o tenant atual.

**DDL (SQL):**
```sql
CREATE TABLE public.features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler as funcionalidades.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar as funcionalidades.

## Notas
- Esta tabela define as "feature flags" do sistema.
