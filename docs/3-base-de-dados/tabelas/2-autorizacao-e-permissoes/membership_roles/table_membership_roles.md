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

```sql
-- Política para SELECT (leitura)
CREATE POLICY "Usuários podem visualizar relacionamentos membership-role"
ON public.membership_roles FOR SELECT
TO authenticated
USING (
  custom_auth_helpers.has_permission('membership_roles.read')
);

-- Política para INSERT (criação)
CREATE POLICY "Usuários podem criar relacionamentos membership-role"
ON public.membership_roles FOR INSERT
TO authenticated
WITH CHECK (
  custom_auth_helpers.has_permission('membership_roles.create')
);

-- Política para UPDATE (atualização)
CREATE POLICY "Usuários podem atualizar relacionamentos membership-role"
ON public.membership_roles FOR UPDATE
TO authenticated
USING (
  custom_auth_helpers.has_permission('membership_roles.update')
)
WITH CHECK (
  custom_auth_helpers.has_permission('membership_roles.update')
);

-- Política para DELETE (exclusão)
CREATE POLICY "Usuários podem excluir relacionamentos membership-role"
ON public.membership_roles FOR DELETE
TO authenticated
USING (
  custom_auth_helpers.has_permission('membership_roles.delete')
);
```

## Notas
- Esta tabela liga os utilizadores às suas permissões através de papéis.
