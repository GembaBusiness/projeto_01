# Tabela: `navigation_items`

**Finalidade e Justificativa:**
Esta tabela armazena a estrutura hierárquica de todos os itens de navegação da aplicação (ex: menus laterais, menus de cabeçalho). Ao guardar a navegação no banco de dados, permitimos que ela seja gerida dinamicamente sem a necessidade de fazer deploy de novas versões do front-end. O suporte a hierarquia (`parent_id`) permite a criação de submenus.

**DDL (SQL):**
```sql
CREATE TABLE public.navigation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  path TEXT,
  icon TEXT,
  parent_id UUID REFERENCES public.navigation_items(id),
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE public.navigation_items IS 'Armazena a estrutura hierárquica dos itens de navegação da UI.';

-- Índice para otimizar a busca de sub-itens.
CREATE INDEX IF NOT EXISTS idx_navigation_items_parent_id ON public.navigation_items(parent_id);
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do item de navegação.
-   `key` (TEXT, UNIQUE): Uma chave de texto única e amigável para o desenvolvedor (ex: "dashboard", "settings.profile").
-   `label` (TEXT, NOT NULL): O texto que será exibido para o usuário na UI (ex: "Dashboard", "Meu Perfil").
-   `path` (TEXT): O caminho/rota da aplicação para onde o item aponta (ex: "/dashboard", "/settings/profile").
-   `icon` (TEXT): O nome ou identificador do ícone a ser exibido.
-   `parent_id` (UUID, FK): Referencia o `id` de outro item na mesma tabela, criando uma relação de parentesco (menu/submenu).
-   `display_order` (INTEGER, NOT NULL): Controla a ordem em que os itens aparecem no mesmo nível hierárquico.
-   `is_active` (BOOLEAN, NOT NULL): Permite ativar ou desativar um item de navegação globalmente.

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler os itens de navegação. A visibilidade de um item no front-end é controlada pela tabela `nav_item_permissions`.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar a estrutura de navegação.

## Notas
- Esta tabela permite que a navegação da UI seja gerida dinamicamente.
