# Tabela: `memberships`

**Finalidade e Justificativa:**
Esta é uma das tabelas mais importantes do sistema. Modela a relação entre `users` e `companies`. É a "fonte da verdade" para determinar a que empresas e, opcionalmente, a que departamento um utilizador pertence. A restrição `UNIQUE(user_id, company_id)` garante que um utilizador só pode ser membro de uma empresa uma única vez.

**DDL (SQL):**
```sql
CREATE TYPE public.membership_status AS ENUM ('active', 'pending_invite');

CREATE TABLE public.memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  has_company_wide_access BOOLEAN NOT NULL DEFAULT false,
  status public.membership_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(user_id, company_id)
);

COMMENT ON TABLE public.memberships IS 'Tabela de associação entre utilizadores e empresas, indicando também o departamento do membro.';

-- Índices para otimizar buscas por usuário, empresa ou departamento.
CREATE INDEX idx_memberships_user_id ON public.memberships(user_id);
CREATE INDEX idx_memberships_company_id ON public.memberships(company_id);
CREATE INDEX idx_memberships_department_id ON public.memberships(department_id);
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do vínculo.
-   `user_id` (UUID, NOT NULL, FK): Referencia o utilizador.
-   `company_id` (UUID, NOT NULL, FK): Referencia a empresa.
-   `department_id` (UUID, FK): Referencia o departamento do membro. É `NULLABLE` para permitir membros sem departamento definido. `ON DELETE SET NULL` garante que se um departamento for apagado, o membro não é removido da empresa.
-   `has_company_wide_access` (BOOLEAN, NOT NULL): Um atributo que, se `true`, concede ao membro acesso a todos os departamentos da empresa, ignorando as regras de acesso baseadas no `department_id`.
-   `status` (ENUM, NOT NULL): Permite a implementação de um sistema de convites.
-   `UNIQUE(user_id, company_id)`: Garante a integridade da relação.

## Políticas de Row Level Security (RLS)
- **`select`**: Um utilizador pode ver a sua própria adesão. Um administrador da empresa pode ver todas as adesões da sua empresa.
- **`insert`**: Um administrador da empresa pode adicionar um novo membro.
- **`update`**: Um administrador da empresa pode atualizar uma adesão (por exemplo, alterar o departamento).
- **`delete`**: Um administrador da empresa pode remover um membro. O próprio utilizador pode remover-se a si próprio.

## Notas
- Esta tabela é a "fonte da verdade" para o acesso à empresa e é fundamental para a segurança multi-tenant.
