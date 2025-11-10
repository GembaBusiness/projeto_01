# Tabela: `profile_company_showcase`

**Finalidade e Justificativa:**
Esta tabela de associação (N:N) controla quais empresas são exibidas no perfil público de um usuário. Ela permite que um usuário exiba suas afiliações profissionais atuais e passadas, com a flexibilidade de vincular a uma `membership` ativa ou manter um registro histórico.

**DDL (SQL):**
```sql
CREATE TABLE profile_company_showcase (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL,
  company_id UUID NOT NULL,

  -- URL slug único por profile (para /p/:profile_slug/:showcase_slug)
  slug TEXT NOT NULL,

  -- Link OPCIONAL com membership (híbrido)
  membership_id UUID,

  -- Dados da experiência profissional
  custom_title TEXT NOT NULL,
  custom_description TEXT,
  start_date DATE,
  end_date DATE,
  is_current BOOLEAN DEFAULT true,

  -- Controle de exibição no perfil público
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  show_company_link BOOLEAN DEFAULT true,

  -- Configurações específicas desta vinculação
  show_title BOOLEAN DEFAULT true,
  show_period BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,

  -- Foreign Keys
  CONSTRAINT fk_profile
    FOREIGN KEY (profile_id)
    REFERENCES profiles(id) ON DELETE CASCADE,

  CONSTRAINT fk_company
    FOREIGN KEY (company_id)
    REFERENCES companies(id) ON DELETE CASCADE,

  CONSTRAINT fk_membership
    FOREIGN KEY (membership_id)
    REFERENCES memberships(id) ON DELETE SET NULL,

  -- Constraints de validação
  CONSTRAINT unique_profile_company
    UNIQUE (profile_id, company_id),

  CONSTRAINT unique_slug_per_profile
    UNIQUE (profile_id, slug),

  CONSTRAINT check_current_dates CHECK (
    (is_current = true AND end_date IS NULL) OR
    (is_current = false)
  ),

  CONSTRAINT check_date_order CHECK (
    start_date IS NULL OR end_date IS NULL OR start_date <= end_date
  )
);

-- Índices
CREATE INDEX idx_showcase_profile ON profile_company_showcase(profile_id);
CREATE INDEX idx_showcase_company ON profile_company_showcase(company_id);
CREATE INDEX idx_showcase_membership ON profile_company_showcase(membership_id);
CREATE INDEX idx_showcase_slug ON profile_company_showcase(profile_id, slug);
CREATE INDEX idx_showcase_active ON profile_company_showcase(profile_id, is_active)
  WHERE is_active = true;
CREATE INDEX idx_showcase_order ON profile_company_showcase(profile_id, display_order);
```

**Campos e Restrições:**
- `profile_id` (UUID, FK): Referencia o perfil do usuário.
- `company_id` (UUID, FK): Referencia a empresa a ser exibida.
- `slug` (TEXT): URL amigável para esta afiliação específica, único por perfil.
- `membership_id` (UUID, FK): Vínculo opcional a uma `membership` ativa. Se `NULL`, representa uma experiência passada.
- `is_active` (BOOLEAN): Controla se esta afiliação é exibida no perfil público do usuário.
- `display_order` (INTEGER): Define a ordem de exibição das empresas no perfil.
- `unique_profile_company` (UNIQUE): Garante que um usuário só pode ter uma afiliação por empresa.

**Políticas de Row Level Security (RLS):**

```sql
ALTER TABLE profile_company_showcase ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Qualquer pessoa pode ver showcases ativos"
ON profile_company_showcase FOR SELECT
USING (
  is_active = true AND
  profile_id IN (
    SELECT profile_id FROM public_profiles
    WHERE is_active = true AND deleted_at IS NULL
  )
);

CREATE POLICY "Usuários podem ver showcases"
ON profile_company_showcase FOR SELECT
TO authenticated
USING (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('profile_company_showcase.read')
);

CREATE POLICY "Usuários podem criar showcases"
ON profile_company_showcase FOR INSERT
TO authenticated
WITH CHECK (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('profile_company_showcase.create')
);

CREATE POLICY "Usuários podem atualizar showcases"
ON profile_company_showcase FOR UPDATE
TO authenticated
USING (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('profile_company_showcase.update')
)
WITH CHECK (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('profile_company_showcase.update')
);

CREATE POLICY "Usuários podem apagar showcases"
ON profile_company_showcase FOR DELETE
TO authenticated
USING (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('profile_company_showcase.delete')
);
```

**Notas:**
- Esta tabela é o coração da funcionalidade de "showcase" de empresas no perfil do usuário.
- O campo `membership_id` permite uma integração elegante entre a experiência profissional atual (ligada a `memberships`) e as experiências passadas (registros manuais).
- A política de `SELECT` pública verifica se tanto o showcase quanto o perfil público do usuário estão ativos.
