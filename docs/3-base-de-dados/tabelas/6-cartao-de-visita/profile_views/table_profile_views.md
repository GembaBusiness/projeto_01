# Tabela: `profile_views`

**Finalidade e Justificativa:**
Esta tabela de analytics registra cada visualização de um perfil público (seja de usuário ou de empresa). Ela é crucial para entender o alcance e o engajamento dos cartões de visita. Uma característica importante é o `snapshot` do modo de exibição no momento da visualização, o que permite análises precisas sobre qual modo de compartilhamento gera mais visualizações.

**DDL (SQL):**
```sql
CREATE TABLE profile_views (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Qual perfil foi visualizado
  public_profile_id UUID,
  company_profile_id UUID,

  -- Token de compartilhamento usado (rastreabilidade)
  share_token UUID,

  -- SNAPSHOT do modo de exibição no momento da visualização
  share_display_type_at_view share_display_type,

  -- Dados do visitante (anônimo ou autenticado)
  viewer_profile_id UUID,
  viewer_company_id UUID,

  -- Dados técnicos da visita
  ip_address INET,
  user_agent TEXT,
  referrer TEXT,
  geolocation JSONB,

  -- Snapshot de empresas ativas no momento da visualização
  active_companies_snapshot JSONB,

  -- Timestamp
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Foreign Keys
  CONSTRAINT fk_public_profile
    FOREIGN KEY (public_profile_id)
    REFERENCES public_profiles(id) ON DELETE CASCADE,

  CONSTRAINT fk_company_profile
    FOREIGN KEY (company_profile_id)
    REFERENCES company_profiles(id) ON DELETE CASCADE,

  CONSTRAINT fk_share_token
    FOREIGN KEY (share_token)
    REFERENCES profile_shares(share_token) ON DELETE SET NULL,

  CONSTRAINT fk_viewer_profile
    FOREIGN KEY (viewer_profile_id)
    REFERENCES profiles(id) ON DELETE SET NULL,

  CONSTRAINT fk_viewer_company
    FOREIGN KEY (viewer_company_id)
    REFERENCES companies(id) ON DELETE SET NULL,

  -- Validação: exatamente um perfil visualizado
  CONSTRAINT check_profile_type CHECK (
    (public_profile_id IS NOT NULL AND company_profile_id IS NULL) OR
    (public_profile_id IS NULL AND company_profile_id IS NOT NULL)
  )
);

-- Índices
CREATE INDEX idx_views_public_profile ON profile_views(public_profile_id);
CREATE INDEX idx_views_company_profile ON profile_views(company_profile_id);
CREATE INDEX idx_views_date ON profile_views(viewed_at DESC);
CREATE INDEX idx_views_share_token ON profile_views(share_token);
CREATE INDEX idx_views_display_type ON profile_views(share_display_type_at_view);
CREATE INDEX idx_views_viewer ON profile_views(viewer_profile_id);
CREATE INDEX idx_views_ip ON profile_views(ip_address);
```

**Campos e Restrições:**
- `public_profile_id`, `company_profile_id`: Chaves estrangeiras que indicam qual perfil foi visualizado. A restrição `check_profile_type` garante que apenas um deles seja preenchido.
- `share_token` (FK): Rastreia qual link de compartilhamento originou a visualização.
- `share_display_type_at_view` (ENUM): Um **snapshot** do modo de exibição no momento da visualização, essencial para analytics precisos.
- `viewer_profile_id`, `viewer_company_id`: Identificam o visitante, se ele estiver autenticado.
- `active_companies_snapshot` (JSONB): Grava quais empresas estavam ativas no perfil do usuário no momento da visita.

**Políticas de Row Level Security (RLS):**
```sql
ALTER TABLE profile_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ver visualizações de seu perfil"
ON profile_views FOR SELECT
TO authenticated
USING (
  public_profile_id IN (
    SELECT id FROM public_profiles WHERE profile_id = (SELECT auth.uid())
  ) AND
  custom_auth_helpers.has_permission('profile_views.read')
);

CREATE POLICY "Qualquer pessoa pode criar visualizações"
ON profile_views FOR INSERT
WITH CHECK (true);

CREATE POLICY "Apenas sistema pode atualizar visualizações"
ON profile_views FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Apenas sistema pode deletar visualizações"
ON profile_views FOR DELETE
TO service_role
USING (true);
```

**Notas:**
- Assim como `share_events`, esta tabela é otimizada para um alto volume de inserções.
- A política de `INSERT` é aberta para permitir o registro de visualizações anônimas.
- O campo `share_display_type_at_view` é fundamental. Como o `share_display_type` na tabela `profile_shares` pode mudar, este snapshot garante que a análise de dados reflita o estado do sistema no momento exato da visualização.
