# Exemplos de Queries com `profile_id`

Este documento demonstra como usar a coluna `profile_id` em `memberships` para simplificar queries e eliminar a necessidade de funções `SECURITY DEFINER` ao acessar dados de perfil.

---

## Por que usar `profile_id`?

### ❌ ANTES: Query complexa com `auth.users`

```sql
-- Requeria função SECURITY DEFINER para acessar auth.users
CREATE FUNCTION get_company_members(p_company_id UUID)
RETURNS TABLE (
  membership_id UUID,
  full_name TEXT,
  email TEXT,
  job_title TEXT
)
LANGUAGE SQL
SECURITY DEFINER  -- ⚠️ Necessário para acessar auth.users
SET search_path = public
AS $$
  SELECT
    m.id,
    p.full_name,
    u.email,
    p.job_title
  FROM memberships m
  JOIN profiles p ON p.id = m.user_id
  JOIN auth.users u ON u.id = m.user_id  -- Acesso protegido!
  WHERE m.company_id = p_company_id;
$$;
```

### ✅ AGORA: Query simples com `profile_id`

```sql
-- Funciona direto, sem SECURITY DEFINER (para dados de profiles)
SELECT
  m.id,
  m.status,
  m.has_company_wide_access,
  p.full_name,
  p.avatar_url,
  p.job_title,
  p.phone_number,
  d.name as department_name
FROM memberships m
JOIN profiles p ON p.id = m.profile_id  -- ✅ JOIN direto!
LEFT JOIN departments d ON d.id = m.department_id
WHERE m.company_id = 'your-company-id'
  AND m.status = 'active';
```

---

## Exemplos Práticos

### 1. Listar Membros Ativos de uma Empresa

```sql
-- Query simples que funciona diretamente
SELECT
  m.id as membership_id,
  p.id as user_id,
  p.full_name,
  p.avatar_url,
  p.job_title,
  m.has_company_wide_access,
  d.name as department_name
FROM public.memberships m
JOIN public.profiles p ON p.id = m.profile_id
LEFT JOIN public.departments d ON d.id = m.department_id
WHERE m.company_id = $1
  AND m.status = 'active'
  AND m.deleted_at IS NULL
ORDER BY p.full_name;
```

**Parâmetros:**
- `$1`: `company_id` (UUID)

**Uso no frontend (Supabase):**
```typescript
const { data, error } = await supabase
  .from('memberships')
  .select(`
    id,
    status,
    has_company_wide_access,
    profiles:profile_id (
      id,
      full_name,
      avatar_url,
      job_title,
      phone_number
    ),
    departments:department_id (
      id,
      name
    )
  `)
  .eq('company_id', companyId)
  .eq('status', 'active')
  .is('deleted_at', null)
  .order('profiles(full_name)');
```

---

### 2. Buscar Perfil de um Membro Específico

```sql
-- Buscar dados completos de um membro
SELECT
  m.id as membership_id,
  m.status,
  m.has_company_wide_access,
  m.created_at as member_since,
  p.id as user_id,
  p.full_name,
  p.avatar_url,
  p.job_title,
  p.phone_number,
  c.name as company_name,
  c.logo_url as company_logo,
  d.name as department_name
FROM public.memberships m
JOIN public.profiles p ON p.id = m.profile_id
JOIN public.companies c ON c.id = m.company_id
LEFT JOIN public.departments d ON d.id = m.department_id
WHERE m.id = $1;
```

**Parâmetros:**
- `$1`: `membership_id` (UUID)

**Uso no frontend:**
```typescript
const { data, error } = await supabase
  .from('memberships')
  .select(`
    id,
    status,
    has_company_wide_access,
    created_at,
    profiles:profile_id (
      id,
      full_name,
      avatar_url,
      job_title,
      phone_number
    ),
    companies:company_id (
      id,
      name,
      logo_url
    ),
    departments:department_id (
      id,
      name
    )
  `)
  .eq('id', membershipId)
  .single();
```

---

### 3. Listar Membros por Departamento

```sql
-- Buscar todos os membros de um departamento específico
SELECT
  p.full_name,
  p.avatar_url,
  p.job_title,
  m.has_company_wide_access,
  m.status
FROM public.memberships m
JOIN public.profiles p ON p.id = m.profile_id
WHERE m.department_id = $1
  AND m.company_id = $2
  AND m.status = 'active'
ORDER BY p.full_name;
```

**Parâmetros:**
- `$1`: `department_id` (UUID)
- `$2`: `company_id` (UUID)

---

### 4. Contar Membros por Status

```sql
-- Estatísticas de membros de uma empresa
SELECT
  m.status,
  COUNT(*) as total,
  COUNT(m.department_id) as with_department,
  COUNT(*) FILTER (WHERE m.has_company_wide_access = true) as company_wide_access
FROM public.memberships m
WHERE m.company_id = $1
  AND m.deleted_at IS NULL
GROUP BY m.status;
```

**Resultado exemplo:**
```
status          | total | with_department | company_wide_access
----------------|-------|-----------------|--------------------
active          | 25    | 23              | 3
pending_invite  | 5     | 4               | 0
```

---

### 5. Buscar Membros com Acesso Company-Wide

```sql
-- Listar todos os membros que têm acesso irrestrito à empresa
SELECT
  p.full_name,
  p.avatar_url,
  p.job_title,
  p.phone_number,
  m.created_at as member_since
FROM public.memberships m
JOIN public.profiles p ON p.id = m.profile_id
WHERE m.company_id = $1
  AND m.has_company_wide_access = true
  AND m.status = 'active'
ORDER BY m.created_at ASC;
```

---

### 6. Buscar Membros Pendentes de Convite

```sql
-- Listar convites pendentes com dados de perfil
SELECT
  m.id as membership_id,
  p.full_name,
  p.avatar_url,
  p.phone_number,
  d.name as department_name,
  m.created_at as invited_at,
  AGE(NOW(), m.created_at) as pending_duration
FROM public.memberships m
JOIN public.profiles p ON p.id = m.profile_id
LEFT JOIN public.departments d ON d.id = m.department_id
WHERE m.company_id = $1
  AND m.status = 'pending_invite'
ORDER BY m.created_at DESC;
```

---

### 7. Buscar Membros do Mesmo Departamento (Query Relacional)

```sql
-- Encontrar colegas de departamento de um usuário
SELECT
  colleague.id as membership_id,
  colleague_profile.full_name,
  colleague_profile.avatar_url,
  colleague_profile.job_title,
  colleague_profile.phone_number
FROM public.memberships current_user
JOIN public.memberships colleague
  ON colleague.department_id = current_user.department_id
  AND colleague.company_id = current_user.company_id
  AND colleague.id != current_user.id
JOIN public.profiles colleague_profile
  ON colleague_profile.id = colleague.profile_id
WHERE current_user.user_id = $1
  AND current_user.company_id = $2
  AND colleague.status = 'active'
ORDER BY colleague_profile.full_name;
```

**Parâmetros:**
- `$1`: `user_id` do usuário atual (UUID)
- `$2`: `company_id` (UUID)

---

### 8. Buscar Hierarquia de Membros (com Agregação)

```sql
-- Agrupar membros por departamento com contagem
SELECT
  d.id as department_id,
  d.name as department_name,
  COUNT(m.id) as member_count,
  ARRAY_AGG(
    JSON_BUILD_OBJECT(
      'user_id', p.id,
      'full_name', p.full_name,
      'avatar_url', p.avatar_url,
      'job_title', p.job_title
    ) ORDER BY p.full_name
  ) as members
FROM public.departments d
LEFT JOIN public.memberships m
  ON m.department_id = d.id
  AND m.status = 'active'
LEFT JOIN public.profiles p
  ON p.id = m.profile_id
WHERE d.company_id = $1
GROUP BY d.id, d.name
ORDER BY d.name;
```

**Resultado exemplo:**
```json
[
  {
    "department_id": "xxx",
    "department_name": "Engineering",
    "member_count": 12,
    "members": [
      {
        "user_id": "yyy",
        "full_name": "Alice Smith",
        "avatar_url": "https://...",
        "job_title": "Senior Engineer"
      },
      ...
    ]
  }
]
```

---

## Quando AINDA Precisar de `SECURITY DEFINER`

Mesmo com `profile_id`, você ainda precisará de funções `SECURITY DEFINER` para acessar dados de `auth.users`, como:

### Exemplo: Buscar Email do Usuário

```sql
-- Email está em auth.users, então ainda precisa de SECURITY DEFINER
CREATE FUNCTION get_member_with_email(p_membership_id UUID)
RETURNS JSON
LANGUAGE SQL
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT JSON_BUILD_OBJECT(
    'membership_id', m.id,
    'full_name', p.full_name,
    'avatar_url', p.avatar_url,
    'job_title', p.job_title,
    'email', u.email,  -- ⚠️ De auth.users
    'email_confirmed', u.email_confirmed_at IS NOT NULL
  )
  FROM memberships m
  JOIN profiles p ON p.id = m.profile_id
  JOIN auth.users u ON u.id = m.user_id
  WHERE m.id = p_membership_id;
$$;
```

---

## Comparação de Performance

### Query SEM profile_id (via SECURITY DEFINER)

```sql
-- Chamada de função (round-trip adicional)
SELECT get_company_members('company-id');
```

**Etapas:**
1. Frontend chama função RPC
2. Função executa com privilégios elevados
3. JOIN com auth.users
4. Retorna resultado

### Query COM profile_id (direto)

```sql
-- Query direta do frontend/backend
SELECT m.*, p.*
FROM memberships m
JOIN profiles p ON p.id = m.profile_id
WHERE m.company_id = 'company-id';
```

**Etapas:**
1. Frontend/Backend executa query
2. JOIN direto entre tabelas públicas
3. RLS aplica automaticamente
4. Retorna resultado

**Vantagens:**
- ✅ Menos overhead de função
- ✅ Mais simples de debugar
- ✅ Melhor suporte a frameworks ORM
- ✅ Queries mais explícitas e legíveis

---

## Verificação de Integridade

### Garantir que profile_id está sincronizado

```sql
-- Deve retornar 0 linhas
SELECT
  m.id,
  m.user_id,
  m.profile_id
FROM public.memberships m
WHERE m.user_id != m.profile_id;
```

### Verificar Foreign Keys

```sql
-- Testar que todos os profile_ids existem
SELECT COUNT(*)
FROM public.memberships m
LEFT JOIN public.profiles p ON p.id = m.profile_id
WHERE p.id IS NULL;
-- Deve retornar 0
```

---

## Migrando Queries Antigas

### ANTES (com função SECURITY DEFINER)

```sql
-- arquivo: get_team_members.sql
CREATE FUNCTION get_team_members(p_company_id UUID)
RETURNS TABLE (...)
SECURITY DEFINER
AS $$
  SELECT ...
  FROM memberships m
  JOIN profiles p ON p.id = m.user_id
  JOIN auth.users u ON u.id = m.user_id
  WHERE ...
$$;
```

### DEPOIS (query direta)

```typescript
// arquivo: team.service.ts
const { data: members } = await supabase
  .from('memberships')
  .select(`
    id,
    status,
    profiles:profile_id (
      id,
      full_name,
      avatar_url,
      job_title
    )
  `)
  .eq('company_id', companyId)
  .eq('status', 'active');
```

**Benefícios:**
- ❌ Remove função SQL
- ✅ Código mais próximo da lógica de negócio
- ✅ Melhor type-safety (TypeScript)
- ✅ Mais fácil de testar

---

## Resumo

| Aspecto | Sem profile_id | Com profile_id |
|---------|----------------|----------------|
| **Acesso a profiles** | Via SECURITY DEFINER | Direto ✅ |
| **Acesso a auth.users** | Via SECURITY DEFINER | Via SECURITY DEFINER |
| **Complexidade** | Alta | Baixa ✅ |
| **Performance** | Boa | Melhor ✅ |
| **Manutenção** | Difícil | Fácil ✅ |
| **Type-safety** | Limitado | Completo ✅ |

---

## Próximos Passos

1. **Aplicar migration:** Execute `20250104000001_add_profile_id_to_memberships.sql`
2. **Testar queries:** Use os exemplos acima para validar
3. **Migrar código existente:** Substitua funções SECURITY DEFINER por queries diretas onde possível
4. **Monitorar performance:** Compare queries antes/depois
5. **Documentar padrões:** Estabeleça guidelines para o time

---

**Dúvidas?** Consulte a documentação da tabela `memberships` em `/docs/3-base-de-dados/tabelas/1-identidade-e-multi-tenancy/memberships/table_memberships.md`
