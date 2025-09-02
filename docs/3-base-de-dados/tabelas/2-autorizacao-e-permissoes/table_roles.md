# Tabela: `roles`

**Finalidade e Justificativa:**
Define um conjunto de permissões agrupadas (cargos). A `company_id` ser `NULLABLE` é uma decisão estratégica: se for `NULL`, é um "papel de sistema" (ex: Administrador, Membro) disponível para todas as empresas. Se tiver um valor, é um "papel customizado" criado por aquela empresa específica. A restrição `UNIQUE(name, company_id)` garante que os nomes dos papéis sejam únicos dentro do seu contexto (seja global ou por empresa).

**DDL (SQL):**
```sql
CREATE TABLE public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  deleted_at TIMESTAMPTZ,
  UNIQUE(name, company_id)
);

-- Índice para otimizar a busca de papéis customizados de uma empresa.
CREATE INDEX idx_roles_company_id ON public.roles(company_id);
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do papel.
-   `name` (TEXT, NOT NULL): Nome do papel (ex: "Administrador"). É obrigatório.
-   `description` (TEXT): Descrição amigável da função do papel.
-   `company_id` (UUID, FK): Permite a distinção entre papéis de sistema (`NULL`) e papéis customizados (preenchido). Garante que um papel customizado seja apagado se a empresa for removida.
-   `deleted_at` (TIMESTAMPTZ): Suporte a soft delete para papéis.
-   `UNIQUE(name, company_id)`: Restrição crucial que impede a criação de papéis com o mesmo nome dentro da mesma empresa, ou globalmente se `company_id` for `NULL`.

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores podem ver os papéis do sistema (`company_id` é NULL). Os utilizadores podem ver os papéis personalizados da sua empresa.
- **`insert`**: Apenas os administradores da empresa podem criar papéis personalizados para a sua empresa. Os papéis do sistema são geridos por um super-administrador.
- **`update`**: Os administradores da empresa podem atualizar os seus papéis personalizados.
- **`delete`**: Os administradores da empresa podem apagar os seus papéis personalizados.

## Notas
- Um valor `NULL` em `company_id` indica um "papel de sistema" disponível para todas as empresas.
