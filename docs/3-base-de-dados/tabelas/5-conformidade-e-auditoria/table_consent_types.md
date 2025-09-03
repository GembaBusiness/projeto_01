# Tabela: `consent_types`

**Finalidade e Justificativa:**
Esta tabela funciona como um catálogo versionado de todos os documentos de consentimento. Ao separar o `type` da `version`, podemos gerenciar múltiplas versões de um mesmo documento (ex: "Termos de Serviço", versão "1.0", "1.1", etc.). Isso permite que a aplicação solicite o consentimento do usuário sempre que uma nova versão de um documento for publicada.

**DDL (SQL):**
```sql
CREATE TABLE public.consent_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  version TEXT NOT NULL,
  content_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (type, version)
);

COMMENT ON TABLE public.consent_types IS 'Catálogo versionado de documentos de consentimento (ex: Termos de Serviço, Política de Privacidade).';
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do tipo de consentimento.
-   `type` (TEXT, NOT NULL): O tipo do documento (ex: "TERMS_OF_SERVICE", "PRIVACY_POLICY").
-   `version` (TEXT, NOT NULL): A versão específica do documento (ex: "1.0", "2.0.1").
-   `content_url` (TEXT): Um link para o local onde o conteúdo completo do documento pode ser lido.
-   `is_active` (BOOLEAN, NOT NULL): Indica se esta versão do consentimento está ativa e pode ser apresentada aos usuários.
-   `UNIQUE (type, version)`: Garante que não existam duas entradas para a mesma versão do mesmo tipo de documento.
