# Tabela: `permissions`

**Finalidade e Justificativa:**
É o catálogo de todas as ações granulares possíveis no sistema. Funciona como um `enum` na base de dados. Manter esta tabela permite que as permissões sejam geridas dinamicamente sem necessidade de alterações no código. A nomenclatura `recurso.acao` (ex: `projects.create`) é uma convenção para fácil entendimento.

**DDL (SQL):**
```sql
create table public.permissions (
  id uuid not null default gen_random_uuid (),
  name text not null,
  description text null,
  tabela text null,
  acao text null,
  constraint permissions_pkey primary key (id),
  constraint permissions_name_key unique (name)
) TABLESPACE pg_default;

create index IF not exists idx_permissions_tabela on public.permissions using btree (tabela) TABLESPACE pg_default;

create index IF not exists idx_permissions_acao on public.permissions using btree (acao) TABLESPACE pg_default;
```

**Campos e Restrições:**
-   `name` (TEXT, UNIQUE): A chave da permissão.

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler as permissões.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar as permissões.

## Notas
- Esta tabela funciona como um `enum` do sistema e raramente deve ser alterada.
