# Tabela: `profiles`

**Finalidade e Justificativa:**
Armazena os dados públicos do perfil de um utilizador, como nome completo e avatar. Esta tabela estende a tabela `auth.users` do Supabase, permitindo adicionar campos personalizados sem modificar a estrutura de autenticação principal. A relação 1-para-1 é mantida por um trigger, garantindo a consistência dos dados do utilizador.

**DDL (SQL):**
```sql
create table public.profiles (
  id uuid not null,
  full_name text null,
  avatar_url text null,
  job_title text null,
  phone_number text null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone null,
  deleted_at timestamp with time zone null,
  avatar_path text null,
  email text null,
  constraint profiles_pkey primary key (id),
  constraint profiles_id_fkey foreign KEY (id) references auth.users (id) on delete CASCADE
) TABLESPACE pg_default;

create unique INDEX IF not exists idx_profiles_email_unique on public.profiles using btree (lower(email)) TABLESPACE pg_default;

create trigger profiles_audit_trigger
after INSERT
or DELETE
or
update on profiles for EACH row
execute FUNCTION log_audit_trail ();

create trigger trigger_validate_profile_email BEFORE INSERT
or
update OF email on profiles for EACH row
execute FUNCTION validate_profile_email ();

```

**Campos e Restrições:**
- `id` (UUID, PK, FK): Chave primária que também é uma chave estrangeira para `auth.users(id)`. Garante a relação 1-para-1.
- `full_name` (TEXT): O nome completo do utilizador.
- `avatar_url` (TEXT): O URL para a imagem de avatar do utilizador.
- `updated_at` (TIMESTAMPTZ): Carimbo de data/hora da última atualização do perfil.

## Políticas de Row Level Security (RLS)

As políticas de RLS para a tabela `profiles` são projetadas para garantir que os utilizadores só possam aceder e modificar perfis com base em um sistema de permissões refinado, que leva em consideração o contexto da empresa e do departamento.

### Política de `SELECT`

Permite que utilizadores visualizem perfis com base em duas permissões distintas: `profiles.read` para acesso pessoal e `profiles.read.total` para acesso alargado.

**Código SQL:**
```sql
-- POLICY: SELECT
CREATE POLICY "Allow users to view profiles based on permissions"
ON public.profiles
FOR SELECT
TO authenticated
USING (
  -- CONDIÇÃO 1: Acesso pessoal com a permissão 'profiles.read'
  (
    custom_auth_helpers.has_permission('profiles.read') AND
    (id = auth.uid()) -- O usuário só pode ver o seu próprio perfil
  )
  OR
  -- CONDIÇÃO 2: Acesso total com a permissão 'profiles.read.total'
  (
    custom_auth_helpers.has_permission('profiles.read.total')
    AND
    -- Verifica se o perfil que está sendo lido pertence a um usuário na mesma empresa do usuário logado
    EXISTS (
      SELECT 1
      FROM public.memberships m
      WHERE m.user_id = profiles.id
        AND m.company_id = custom_auth_helpers.current_company_id()
    )
    AND
    -- Aplica a regra de departamento ou acesso total
    (
      -- O usuário logado tem acesso a toda a empresa
      (custom_auth_helpers.current_membership_attributes()).has_company_wide_access = true
      OR
      -- O departamento do perfil visualizado é o mesmo do usuário logado
      (SELECT department_id FROM public.memberships WHERE user_id = profiles.id AND company_id = custom_auth_helpers.current_company_id()) = (custom_auth_helpers.current_membership_attributes()).department_id
    )
  )
);
```

**Lógica de Acesso:**
- **Condição 1 (`profiles.read`):** Um utilizador com a permissão `profiles.read` pode visualizar **apenas o seu próprio perfil**. A condição `id = auth.uid()` garante essa restrição.
- **Condição 2 (`profiles.read.total`):** Um utilizador com a permissão `profiles.read.total` tem acesso expandido, sujeito a duas verificações adicionais:
    1.  **Mesma Empresa:** O perfil a ser visualizado deve pertencer a um utilizador que seja membro da mesma empresa (`company_id`) que o utilizador autenticado.
    2.  **Escopo de Acesso:**
        - Se o utilizador autenticado tiver o atributo `has_company_wide_access = true`, ele poderá ver todos os perfis da sua empresa.
        - Caso contrário, ele só poderá ver perfis de utilizadores que pertençam ao **mesmo departamento** que ele.

---

### Política de `UPDATE`

Permite que utilizadores atualizem perfis, espelhando a lógica de acesso da política de `SELECT` para a cláusula `USING` e adicionando uma verificação de permissão de `UPDATE` na cláusula `WITH CHECK`.

**Código SQL:**
```sql
-- POLICY: UPDATE
CREATE POLICY "Allow users to update profiles with permission"
ON public.profiles
FOR UPDATE
TO authenticated
USING (
  -- A lógica de quais linhas podem ser atualizadas é a mesma da leitura (SELECT)
  (
    custom_auth_helpers.has_permission('profiles.read') AND (id = auth.uid())
  )
  OR
  (
    custom_auth_helpers.has_permission('profiles.read.total') AND
    EXISTS (SELECT 1 FROM public.memberships m WHERE m.user_id = profiles.id AND m.company_id = custom_auth_helpers.current_company_id()) AND
    (
      (custom_auth_helpers.current_membership_attributes()).has_company_wide_access = true OR
      (SELECT department_id FROM public.memberships WHERE user_id = profiles.id AND company_id = custom_auth_helpers.current_company_id()) = (custom_auth_helpers.current_membership_attributes()).department_id
    )
  )
)
WITH CHECK (
  -- A única verificação necessária nos dados após a atualização é se o usuário tem a permissão de 'update'
  custom_auth_helpers.has_permission('profiles.update')
);
```

**Lógica de Acesso:**
- **Cláusula `USING`:** Determina **quais perfis** um utilizador pode tentar atualizar. A lógica é idêntica à da política de `SELECT`, ou seja, o utilizador pode atualizar o seu próprio perfil ou os perfis da sua empresa/departamento, dependendo das suas permissões.
- **Cláusula `WITH CHECK`:** Garante que, para a operação de atualização ser bem-sucedida, o utilizador deve possuir a permissão `profiles.update`. Esta verificação é crucial para separar o direito de *ver* um perfil do direito de *modificá-lo*.

### Outras Políticas
- **`INSERT`**: A inserção é controlada por funções de segurança (`create_company_and_profile`), não sendo permitida diretamente por utilizadores para garantir a integridade dos dados na criação.
- **`DELETE`**: A exclusão é gerida por `ON DELETE CASCADE` a partir da tabela `auth.users`. Quando um utilizador é removido do sistema de autenticação, o seu perfil correspondente é automaticamente eliminado.

## Notas
- ID Vinculado à Autenticação: O id do perfil é o mesmo user_id do sistema de autenticação, criando uma ligação direta e fundamental.
- Prevenção de Duplicidade: O sistema verifica ativamente se um perfil com o id do utilizador já existe antes de tentar uma nova inserção, evitando duplicados.
- Esta tabela não armazena informações sensíveis ou de autenticação, apenas dados de perfil públicos.
