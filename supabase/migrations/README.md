# Migrations do Banco de Dados

Este diretório contém migrations SQL para o banco de dados Supabase.

## Como Aplicar Migrations

### Opção 1: Via Supabase CLI (Recomendado)

```bash
# Certifique-se de estar logado no Supabase
supabase login

# Link seu projeto local ao projeto remoto
supabase link --project-ref your-project-ref

# Aplique todas as migrations pendentes
supabase db push

# Ou aplique uma migration específica
supabase db push --file supabase/migrations/20250104000001_add_profile_id_to_memberships.sql
```

### Opção 2: Via Dashboard do Supabase

1. Acesse [app.supabase.com](https://app.supabase.com)
2. Selecione seu projeto
3. Vá para **SQL Editor**
4. Copie e cole o conteúdo do arquivo de migration
5. Execute a query

### Opção 3: Via API (Programático)

```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // ⚠️ Use service_role apenas no backend
)

const migrationSQL = await fs.readFile(
  'supabase/migrations/20250104000001_add_profile_id_to_memberships.sql',
  'utf-8'
)

const { error } = await supabase.rpc('exec', { sql: migrationSQL })
```

## Migrations Disponíveis

### 20250104000001_add_profile_id_to_memberships.sql

**Descrição:** Adiciona coluna `profile_id` na tabela `memberships` para permitir acesso direto à tabela `profiles` sem passar por `auth.users`.

**O que faz:**
1. ✅ Adiciona coluna `profile_id UUID NOT NULL` com FK para `profiles(id)`
2. ✅ Cria índice `idx_memberships_profile_id` para performance
3. ✅ Popula `profile_id` para registros existentes
4. ✅ Cria trigger para sincronizar `profile_id` com `user_id` automaticamente
5. ✅ Adiciona constraint `CHECK` para garantir integridade (`profile_id = user_id`)

**Impacto:**
- Sem breaking changes (apenas adiciona funcionalidade)
- Permite queries mais simples sem `SECURITY DEFINER`
- Melhora performance de JOINs com profiles

**Rollback:**
```sql
-- Se precisar reverter (não recomendado após uso em produção)
ALTER TABLE public.memberships DROP COLUMN profile_id;
DROP TRIGGER IF EXISTS trg_sync_membership_profile_id ON public.memberships;
DROP FUNCTION IF EXISTS public.sync_membership_profile_id();
```

**Documentação relacionada:**
- [Tabela Memberships](/docs/3-base-de-dados/tabelas/1-identidade-e-multi-tenancy/memberships/table_memberships.md)
- [Exemplos de Queries](/docs/3-base-de-dados/tabelas/1-identidade-e-multi-tenancy/memberships/query_examples_with_profile_id.md)

## Boas Práticas

### Nomenclatura de Arquivos

```
YYYYMMDDHHMMSS_descriptive_name.sql
```

Exemplo: `20250104000001_add_profile_id_to_memberships.sql`

### Estrutura de uma Migration

```sql
-- ============================================================================
-- Migration: [Título]
-- Purpose: [Descrição do propósito]
-- Date: [Data]
-- ============================================================================

-- STEP 1: [Descrição]
-- Código SQL...

-- STEP 2: [Descrição]
-- Código SQL...

-- VERIFICATION QUERIES (commented out)
-- Queries para testar/validar a migration
```

### Antes de Criar uma Migration

1. **Planeje:** Escreva o que a migration fará
2. **Teste localmente:** Use ambiente de desenvolvimento primeiro
3. **Documente:** Explique o porquê e o impacto
4. **Rollback:** Sempre tenha um plano de reversão
5. **Comunique:** Informe o time sobre mudanças críticas

### Checklist de Validação

- [ ] Migration tem nome descritivo
- [ ] Código está documentado
- [ ] Índices foram criados para FKs
- [ ] RLS policies foram consideradas
- [ ] Trigger functions têm `SECURITY DEFINER` se necessário
- [ ] Testado em ambiente local/staging
- [ ] Documentação atualizada
- [ ] Plano de rollback documentado

## Verificação Pós-Migration

### Validar profile_id

```sql
-- 1. Verificar que todos os registros têm profile_id
SELECT COUNT(*) as total,
       COUNT(profile_id) as with_profile_id,
       COUNT(*) - COUNT(profile_id) as missing
FROM public.memberships;

-- 2. Verificar sincronização com user_id
SELECT COUNT(*)
FROM public.memberships
WHERE user_id != profile_id;
-- Deve retornar 0

-- 3. Testar query simples
SELECT m.id, p.full_name, p.avatar_url
FROM memberships m
JOIN profiles p ON p.id = m.profile_id
LIMIT 5;
```

## Troubleshooting

### Erro: "relation does not exist"

**Causa:** Tabelas/schemas não foram criados
**Solução:** Execute migrations anteriores primeiro

### Erro: "column already exists"

**Causa:** Migration já foi aplicada
**Solução:** Verifique histórico de migrations aplicadas

```sql
-- Verificar migrations aplicadas (se usar supabase_migrations)
SELECT * FROM supabase_migrations.schema_migrations
ORDER BY version DESC;
```

### Erro: "violates check constraint"

**Causa:** Dados existentes violam nova constraint
**Solução:** Corrija dados antes de adicionar constraint

```sql
-- Encontrar registros problemáticos
SELECT * FROM memberships
WHERE profile_id != user_id;
```

## Suporte

Para dúvidas sobre migrations:
1. Consulte a [documentação do Supabase](https://supabase.com/docs/guides/cli/local-development)
2. Revise a documentação do projeto em `/docs/3-base-de-dados/`
3. Abra uma issue no repositório
