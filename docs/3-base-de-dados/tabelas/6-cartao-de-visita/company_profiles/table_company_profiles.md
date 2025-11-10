# Tabela: `company_profiles`

**Finalidade e Justificativa:**
Armazena o cartão de visita público de uma empresa. Esta tabela estende a tabela `companies` com informações que a empresa deseja compartilhar publicamente, como descrição, contatos corporativos e redes sociais. A relação é de 1 para 1 com a tabela `companies`.

**DDL (SQL):**
```sql
CREATE TABLE company_profiles (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL UNIQUE,

  -- URL e identificação pública
  slug TEXT NOT NULL UNIQUE,

  -- Dados da empresa
  display_name TEXT,
  tagline TEXT,
  description TEXT,
  industry TEXT,
  founded_year INTEGER,
  company_size TEXT,

  -- Localização
  location_point POINT,
  location_string TEXT,
  address TEXT,

  -- Contatos corporativos
  corporate_email TEXT,
  corporate_phone TEXT,
  corporate_whatsapp TEXT,
  website TEXT,

  -- Redes sociais da empresa
  social_links JSONB DEFAULT '{}'::jsonb,

  -- Visual
  logo_url TEXT,
  logo_path TEXT,
  cover_image_url TEXT,
  cover_image_path TEXT,

  -- Controle de privacidade
  privacy_settings JSONB NOT NULL DEFAULT '{
    "email": "public",
    "phone": "public",
    "whatsapp": "public",
    "address": "public",
    "social_links": "public"
  }'::jsonb,

  -- NFC e compartilhamento
  nfc_enabled BOOLEAN DEFAULT true,
  qr_code_url TEXT,
  qr_code_path TEXT,

  -- Customização visual
  theme JSONB DEFAULT '{
    "primary_color": "#3B82F6",
    "secondary_color": "#10B981",
    "layout": "corporate"
  }'::jsonb,

  -- Controle
  is_active BOOLEAN DEFAULT true,

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,

  -- Foreign Keys
  CONSTRAINT fk_company
    FOREIGN KEY (company_id)
    REFERENCES companies(id) ON DELETE CASCADE,

  -- Constraints de validação
  CONSTRAINT valid_founded_year CHECK (
    founded_year IS NULL OR
    (founded_year >= 1800 AND founded_year <= EXTRACT(YEAR FROM CURRENT_DATE))
  )
);

-- Índices
CREATE UNIQUE INDEX idx_company_profiles_slug ON company_profiles(slug);
CREATE INDEX idx_company_profiles_company_id ON company_profiles(company_id);
CREATE INDEX idx_company_profiles_active ON company_profiles(is_active)
  WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_company_profiles_search ON company_profiles
  USING gin(to_tsvector('portuguese',
    coalesce(display_name, '') || ' ' ||
    coalesce(description, '') || ' ' ||
    coalesce(tagline, '')
  ));
```

**Campos e Restrições:**
- `id` (UUID, PK): Chave primária da tabela.
- `company_id` (UUID, FK, UNIQUE): Chave estrangeira que referencia `companies(id)`, garantindo a relação 1:1.
- `slug` (TEXT, UNIQUE): URL amigável e única para o perfil público da empresa.
- `is_active` (BOOLEAN): Controla a visibilidade pública do cartão de visita da empresa.
- `founded_year` (INTEGER): Ano de fundação da empresa, com uma restrição para garantir que seja um ano válido.

**Políticas de Row Level Security (RLS):**

```sql
ALTER TABLE company_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Qualquer pessoa pode ver perfis de empresas ativas"
ON company_profiles FOR SELECT
USING (
  is_active = true AND
  deleted_at IS NULL
);

CREATE POLICY "Usuários podem ver perfis da empresa"
ON company_profiles FOR SELECT
TO authenticated
USING (
  company_id = (SELECT custom_auth_helpers.current_company_id()) AND
  custom_auth_helpers.has_permission('company_profiles.read')
);

CREATE POLICY "Usuários podem criar perfil da empresa"
ON company_profiles FOR INSERT
TO authenticated
WITH CHECK (
  company_id = (SELECT custom_auth_helpers.current_company_id()) AND
  custom_auth_helpers.has_permission('company_profiles.create')
);

CREATE POLICY "Usuários podem atualizar perfil da empresa"
ON company_profiles FOR UPDATE
TO authenticated
USING (
  company_id = (SELECT custom_auth_helpers.current_company_id()) AND
  custom_auth_helpers.has_permission('company_profiles.update')
)
WITH CHECK (
  company_id = (SELECT custom_auth_helpers.current_company_id()) AND
  custom_auth_helpers.has_permission('company_profiles.update')
);

CREATE POLICY "Usuários podem deletar perfil da empresa"
ON company_profiles FOR DELETE
TO authenticated
USING (
  company_id = (SELECT custom_auth_helpers.current_company_id()) AND
  custom_auth_helpers.has_permission('company_profiles.delete')
);
```

**Notas:**
- A tabela `company_profiles` funciona como o "cartão de visita" digital da empresa.
- O `slug` permite criar URLs personalizadas para a empresa (ex: `app.com/c/empresa-tech`).
- As políticas de RLS garantem que apenas usuários com as permissões adequadas possam gerenciar o perfil da empresa à qual pertencem.
