# Tabela: `role_permissions`

**Finalidade e Justificativa:**
Esta tabela é o coração do modelo RBAC, servindo como a matriz que conecta as ações granulares (`permissions`) aos papéis (`roles`). Ao definir explicitamente quais permissões um papel como "Administrador" possui, esta tabela permite que as capacidades de um papel sejam geridas dinamicamente através de dados, garantindo flexibilidade e desacoplando as regras de autorização do código da aplicação.

**DDL (SQL):**
```sql
CREATE TABLE public.role_permissions (
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- Índice para otimizar a busca de papéis por permissão.
CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions(permission_id);
```

**Campos e Restrições:**
-   `PRIMARY KEY (role_id, permission_id)`: Chave primária composta que também garante a unicidade da relação.

## Políticas de Row Level Security (RLS)
- **`select`**: Os utilizadores podem ver quais as permissões associadas aos papéis que podem ver.
- **`insert`/`delete`**: Para papéis personalizados, os administradores da empresa podem gerir as permissões. Para papéis de sistema, apenas um super-administrador.

## Notas
- Esta tabela define o modelo RBAC, ligando papéis a permissões.
