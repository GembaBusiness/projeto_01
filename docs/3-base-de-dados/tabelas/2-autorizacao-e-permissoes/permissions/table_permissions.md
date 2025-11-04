# Tabela: `permissions`

**Finalidade e Justificativa:**
É o catálogo de todas as ações granulares possíveis no sistema. Funciona como um `enum` na base de dados. Manter esta tabela permite que as permissões sejam geridas dinamicamente sem necessidade de alterações no código. A nomenclatura `recurso.acao` (ex: `projects.create`) é uma convenção para fácil entendimento.

**DDL (SQL):**
```sql
CREATE TABLE public.permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT
);
```

**Campos e Restrições:**
-   `name` (TEXT, UNIQUE): A chave da permissão.

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler as permissões.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar as permissões.

## Notas
- Esta tabela funciona como um `enum` do sistema e raramente deve ser alterada.
