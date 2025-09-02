# Tabela: `nav_item_permissions`

**Finalidade e Justificativa:**
Esta tabela de junção é a ponte entre a estrutura da UI (`navigation_items`) e o sistema de autorização (`permissions`). Ela define explicitamente qual permissão é necessária para visualizar um determinado item de navegação. Com base nas permissões totais de um usuário (derivadas de seus papéis), o front-end pode consultar esta tabela para decidir dinamicamente quais itens de menu renderizar, garantindo que os usuários vejam apenas os links para as áreas do sistema que eles têm permissão para acessar.

**DDL (SQL):**
```sql
CREATE TABLE public.nav_item_permissions (
  nav_item_id UUID NOT NULL REFERENCES public.navigation_items(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (nav_item_id, permission_id)
);

COMMENT ON TABLE public.nav_item_permissions IS 'Tabela de junção N:N entre itens de navegação e as permissões necessárias para visualizá-los.';
```

**Campos e Restrições:**
-   `nav_item_id` (UUID, NOT NULL, FK): Referencia o item de navegação.
-   `permission_id` (UUID, NOT NULL, FK): Referencia a permissão necessária para ver o item.
-   `PRIMARY KEY (nav_item_id, permission_id)`: Garante que uma permissão só possa ser associada a um item de navegação uma única vez.

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler estas permissões.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar estas permissões.

## Notas
- Esta tabela é a ponte entre a UI e o sistema de permissões, controlando a visibilidade dos itens de navegação.
