# Tabela: `profile_shares`

**Finalidade e Justificativa:**
Esta tabela armazena os links permanentes de compartilhamento associados a cada `showcase` de um usuário. Cada registro representa um link único (via `share_token`) que pode ser usado em cartões NFC, QR codes ou links diretos. A tabela também controla o modo de exibição do conteúdo compartilhado.

**DDL (SQL):**
```sql
CREATE TABLE profile_shares (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- TRÊS IDs OBRIGATÓRIOS (combinação fixa)
  public_profile_id UUID NOT NULL,
  company_profile_id UUID NOT NULL,
  showcase_id UUID NOT NULL UNIQUE,  -- UM share por showcase

  -- Token permanente e único
  share_token UUID NOT NULL DEFAULT gen_random_uuid() UNIQUE,

  -- Modo de exibição (MUTÁVEL - controla o que mostrar)
  share_display_type share_display_type NOT NULL DEFAULT 'user_and_company',

  -- Controle de ativação
  is_active BOOLEAN DEFAULT true,
  deactivated_at TIMESTAMPTZ,

  -- Analytics agregado (desnormalizado para performance)
  total_views INTEGER DEFAULT 0,
  total_events INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,

  -- Foreign Keys
  CONSTRAINT fk_public_profile
    FOREIGN KEY (public_profile_id)
    REFERENCES public_profiles(id) ON DELETE CASCADE,

  CONSTRAINT fk_company_profile
    FOREIGN KEY (company_profile_id)
    REFERENCES company_profiles(id) ON DELETE CASCADE,

  CONSTRAINT fk_showcase
    FOREIGN KEY (showcase_id)
    REFERENCES profile_company_showcase(id) ON DELETE CASCADE
);

-- Índices
CREATE UNIQUE INDEX idx_shares_showcase ON profile_shares(showcase_id);
CREATE UNIQUE INDEX idx_shares_token ON profile_shares(share_token);
CREATE INDEX idx_shares_public_profile ON profile_shares(public_profile_id);
CREATE INDEX idx_shares_company_profile ON profile_shares(company_profile_id);
CREATE INDEX idx_shares_display_type ON profile_shares(share_display_type);
CREATE INDEX idx_shares_active ON profile_shares(is_active)
  WHERE is_active = true;
CREATE INDEX idx_shares_last_accessed ON profile_shares(last_accessed_at DESC NULLS LAST);
```

**Campos e Restrições:**
- `showcase_id` (UUID, FK, UNIQUE): Garante que exista apenas um link de compartilhamento por `showcase`.
- `share_token` (UUID, UNIQUE): O token único e permanente usado para acessar o conteúdo compartilhado.
- `share_display_type` (ENUM): Campo mutável que controla o que é exibido: perfil do usuário, perfil da empresa ou ambos.
- `is_active` (BOOLEAN): Permite desativar o link de compartilhamento sem excluí-lo.
- `total_views`, `total_events`, `last_accessed_at`: Campos desnormalizados para analytics, visando a performance.

**Políticas de Row Level Security (RLS):**

```sql
ALTER TABLE profile_shares ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ver seus shares"
ON profile_shares FOR SELECT
TO authenticated
USING (
  public_profile_id IN (
    SELECT id FROM public_profiles WHERE profile_id = (SELECT auth.uid())
  ) AND
  custom_auth_helpers.has_permission('profile_shares.read')
);

CREATE POLICY "Apenas sistema pode criar shares"
ON profile_shares FOR INSERT
TO service_role
WITH CHECK (true);

CREATE POLICY "Usuários podem atualizar shares"
ON profile_shares FOR UPDATE
TO authenticated
USING (
  public_profile_id IN (
    SELECT id FROM public_profiles WHERE profile_id = (SELECT auth.uid())
  ) AND
  custom_auth_helpers.has_permission('profile_shares.update')
)
WITH CHECK (
  public_profile_id IN (
    SELECT id FROM public_profiles WHERE profile_id = (SELECT auth.uid())
  ) AND
  custom_auth_helpers.has_permission('profile_shares.update')
);

CREATE POLICY "Shares não podem ser deletados"
ON profile_shares FOR DELETE
TO authenticated
USING (false);

CREATE POLICY "Service role pode deletar shares"
ON profile_shares FOR DELETE
TO service_role
USING (true);
```

**Notas:**
- Esta tabela é central para a funcionalidade de compartilhamento. O `share_token` é o identificador chave para qualquer interação externa.
- O `share_display_type` é projetado para ser mutável, permitindo que o usuário alterne a visualização do conteúdo compartilhado a qualquer momento sem precisar gerar um novo link/QR code.
- As operações de `INSERT` e `DELETE` são restritas a `service_role` para garantir a integridade dos links de compartilhamento.
