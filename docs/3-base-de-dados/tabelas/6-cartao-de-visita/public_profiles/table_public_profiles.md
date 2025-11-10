# Tabela: `public_profiles`

**Finalidade e Justificativa:**
Armazena o cartão de visita público e pessoal de um usuário. Esta tabela estende a tabela `profiles` com informações que o usuário deseja compartilhar publicamente, como redes sociais, biografia e informações de contato. A relação é de 1 para 1 com a tabela `profiles`.

**DDL (SQL):**
```sql
CREATE TABLE public_profiles (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE,

  -- URL e identificação pública
  slug TEXT NOT NULL UNIQUE,

  -- Dados pessoais exibidos
  display_name TEXT,
  personal_title TEXT,
  bio TEXT,

  -- Localização
  location_point POINT,
  location_string TEXT,

  -- Contatos pessoais
  personal_email TEXT,
  personal_phone TEXT,
  personal_whatsapp TEXT,

  -- Redes sociais pessoais (JSONB para flexibilidade)
  social_links JSONB DEFAULT '{}'::jsonb,

  -- Avatar
  avatar_url TEXT,
  avatar_path TEXT,

  -- Controle de privacidade GRANULAR
  privacy_settings JSONB NOT NULL DEFAULT '{
    "email": "public",
    "phone": "private",
    "whatsapp": "public",
    "location_exact": "private",
    "location_city": "public",
    "social_links": {
      "linkedin": "public",
      "github": "public",
      "twitter": "public",
      "instagram": "private",
      "website": "public",
      "facebook": "private"
    }
  }'::jsonb,

  -- NFC e compartilhamento
  nfc_enabled BOOLEAN DEFAULT true,
  qr_code_url TEXT,
  qr_code_path TEXT,

  -- Customização visual
  theme JSONB DEFAULT '{
    "primary_color": "#3B82F6",
    "layout": "modern",
    "show_qr_code": true
  }'::jsonb,

  -- Controle
  is_active BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,

  -- Foreign Keys
  CONSTRAINT fk_profile
    FOREIGN KEY (profile_id)
    REFERENCES profiles(id) ON DELETE CASCADE,

  -- Constraints de validação
  CONSTRAINT valid_privacy_settings CHECK (
    privacy_settings ? 'email' AND
    privacy_settings ? 'phone'
  ),

  CONSTRAINT valid_location CHECK (
    (location_point IS NULL AND location_string IS NULL) OR
    (location_point IS NOT NULL)
  )
);

-- Índices
CREATE UNIQUE INDEX idx_public_profiles_slug ON public_profiles(slug);
CREATE INDEX idx_public_profiles_profile_id ON public_profiles(profile_id);
CREATE INDEX idx_public_profiles_active ON public_profiles(is_active)
  WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_public_profiles_search ON public_profiles
  USING gin(to_tsvector('portuguese',
    coalesce(display_name, '') || ' ' ||
    coalesce(bio, '') || ' ' ||
    coalesce(personal_title, '')
  ));
```

**Campos e Restrições:**
- `id` (UUID, PK): Chave primária da tabela.
- `profile_id` (UUID, FK, UNIQUE): Chave estrangeira que referencia `profiles(id)`, garantindo a relação 1:1.
- `slug` (TEXT, UNIQUE): URL amigável e única para o perfil público.
- `privacy_settings` (JSONB): Configurações granulares de privacidade para cada campo do perfil.
- `social_links` (JSONB): Armazena links de redes sociais do usuário.
- `is_active` (BOOLEAN): Controla a visibilidade pública do cartão de visita.

**Políticas de Row Level Security (RLS):**

```sql
ALTER TABLE public_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Qualquer pessoa pode ver perfis públicos ativos"
ON public_profiles FOR SELECT
USING (
  is_active = true AND
  deleted_at IS NULL
);

CREATE POLICY "Usuários podem ver perfis públicos"
ON public_profiles FOR SELECT
TO authenticated
USING (
  custom_auth_helpers.has_permission('public_profiles.read')
);

CREATE POLICY "Usuários podem criar perfil público"
ON public_profiles FOR INSERT
TO authenticated
WITH CHECK (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('public_profiles.create')
);

CREATE POLICY "Usuários podem atualizar perfil público"
ON public_profiles FOR UPDATE
TO authenticated
USING (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('public_profiles.update')
)
WITH CHECK (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('public_profiles.update')
);

CREATE POLICY "Usuários podem apagar perfil público"
ON public_profiles FOR DELETE
TO authenticated
USING (
  profile_id = (SELECT auth.uid()) AND
  custom_auth_helpers.has_permission('public_profiles.delete')
);
```

**Notas:**
- A tabela `public_profiles` é o "cartão de visita" digital do usuário.
- O campo `slug` é fundamental para criar URLs personalizadas (ex: `app.com/p/joao.silva`).
- As `privacy_settings` permitem que o usuário tenha controle total sobre quais informações são exibidas publicamente.
