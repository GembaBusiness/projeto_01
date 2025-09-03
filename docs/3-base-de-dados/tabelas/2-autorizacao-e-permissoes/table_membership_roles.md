# Tabela: `membership_roles`

**Finalidade e Justificativa:**
Esta é a tabela que efetivamente concede as permissões. Ela atribui um `role` a um `membership`, ou seja, a um utilizador DENTRO de uma empresa específica. Esta é a implementação do racional "as permissões pertencem à relação e não ao utilizador".

**DDL (SQL):**
```sql
CREATE TABLE public.membership_roles (
  membership_id UUID NOT NULL REFERENCES public.memberships(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  PRIMARY KEY (membership_id, role_id)
);

-- Índice para otimizar a busca de membros por papel.
CREATE INDEX idx_membership_roles_role_id ON public.membership_roles(role_id);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Um utilizador pode ver os seus próprios papéis. Um administrador pode ver os papéis de todos os membros da sua empresa.
- **`insert`/`delete`**: Os administradores da empresa podem atribuir/desatribuir papéis aos membros.

## Notas
- Esta tabela liga os utilizadores às suas permissões através de papéis.
