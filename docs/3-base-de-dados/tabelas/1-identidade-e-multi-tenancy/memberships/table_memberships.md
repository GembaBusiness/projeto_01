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

As políticas de RLS para a tabela `memberships` são a espinha dorsal da segurança multi-tenant, garantindo que os utilizadores só possam ver e gerir as membresias dentro do seu próprio contexto de empresa e com as permissões adequadas.

### Política de `SELECT`

Permite que utilizadores visualizem membresias com base em duas permissões distintas: `memberships.read` para acesso pessoal e `memberships.read.total` para acesso alargado dentro da empresa.

**Código SQL:**
```sql
-- POLICY: SELECT
CREATE POLICY "Allow users to view memberships based on permissions"
ON public.memberships
FOR SELECT
TO authenticated
USING (
  -- CONDIÇÃO 1: Acesso pessoal com a permissão 'memberships.read'
  (
    custom_auth_helpers.has_permission('memberships.read') AND
    (user_id = auth.uid()) -- O usuário só pode ver a sua própria membresia
  )
  OR
  -- CONDIÇÃO 2: Acesso total com a permissão 'memberships.read.total'
  (
    custom_auth_helpers.has_permission('memberships.read.total')
    AND
    -- A membresia que está sendo lida pertence à mesma empresa do usuário logado
    (company_id = custom_auth_helpers.current_company_id())
    AND
    -- Aplica a regra de departamento ou acesso total do usuário logado
    (
      -- O usuário logado tem acesso a toda a empresa
      (custom_auth_helpers.current_membership_attributes()).has_company_wide_access = true
      OR
      -- O departamento da membresia visualizada é o mesmo do usuário logado
      (department_id = (custom_auth_helpers.current_membership_attributes()).department_id)
    )
  )
);
```

**Lógica de Acesso:**
-   **Condição 1 (`memberships.read`):** Um utilizador com esta permissão pode ver **apenas a sua própria membresia**. A condição `user_id = auth.uid()` é a chave para esta restrição.
-   **Condição 2 (`memberships.read.total`):** Um utilizador com esta permissão tem uma visão mais ampla, podendo ver as membresias de outros utilizadores, mas sempre dentro da **mesma empresa** (`company_id`). O acesso é ainda mais refinado:
    -   Se o utilizador autenticado tiver `has_company_wide_access = true`, ele poderá ver todas as membresias da sua empresa.
    -   Caso contrário, ele só poderá ver as membresias de utilizadores que partilham o **mesmo departamento** que ele.

---

### Política de `UPDATE`

Permite a atualização de membresias, seguindo a mesma lógica de visibilidade da política de `SELECT`, mas adicionando verificações cruciais para garantir que a atualização seja permitida e segura.

**Código SQL:**
```sql
-- POLICY: UPDATE
CREATE POLICY "Allow users to update memberships with permission"
ON public.memberships
FOR UPDATE
TO authenticated
USING (
  -- A lógica de quais linhas podem ser atualizadas é a mesma da leitura (SELECT)
  (
    custom_auth_helpers.has_permission('memberships.read') AND (user_id = auth.uid())
  )
  OR
  (
    custom_auth_helpers.has_permission('memberships.read.total') AND
    (company_id = custom_auth_helpers.current_company_id()) AND
    (
      (custom_auth_helpers.current_membership_attributes()).has_company_wide_access = true OR
      (department_id = (custom_auth_helpers.current_membership_attributes()).department_id)
    )
  )
)
WITH CHECK (
  -- O usuário deve ter a permissão de 'update'
  custom_auth_helpers.has_permission('memberships.update')
  AND
  -- Garante que a atualização não mova a membresia para outra empresa
  (company_id = custom_auth_helpers.current_company_id())
);
```

**Lógica de Acesso:**
-   **Cláusula `USING`:** Define **quais membresias** um utilizador pode sequer tentar atualizar. A lógica é um espelho da política de `SELECT`.
-   **Cláusula `WITH CHECK`:** Aplica duas verificações finais durante a tentativa de `UPDATE`:
    1.  O utilizador deve possuir a permissão `memberships.update`.
    2.  A `company_id` da membresia não pode ser alterada, garantindo que um membro não possa ser movido para uma empresa diferente no momento da atualização, o que poderia violar a lógica de segurança.

### Outras Políticas
-   **`INSERT`**: A inserção de novos membros é controlada por funções de segurança, geralmente acessíveis apenas a administradores com a permissão `memberships.create`.
-   **`DELETE`**: A remoção de membros é igualmente controlada por funções de segurança, exigindo a permissão `memberships.delete`.

## Notas
- Esta tabela é a "fonte da verdade" para o acesso à empresa e é fundamental para a segurança multi-tenant.
