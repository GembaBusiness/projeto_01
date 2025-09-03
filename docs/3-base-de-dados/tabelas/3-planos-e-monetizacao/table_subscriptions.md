# Tabela: `subscriptions`

**Finalidade e Justificativa:**
Regista o estado da subscrição de uma empresa. A restrição `UNIQUE` em `company_id` é a regra de negócio que garante que uma empresa só pode ter uma subscrição ativa de cada vez.

**DDL (SQL):**
```sql
CREATE TYPE public.subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'incomplete');

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
  price_id UUID NOT NULL REFERENCES public.prices(id),
  status public.subscription_status NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para otimizar a busca de assinaturas por preço.
CREATE INDEX idx_subscriptions_price_id ON public.subscriptions(price_id);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Um administrador da empresa pode ver a subscrição da sua empresa.
- **`insert`/`update`/`delete`**: A gestão das subscrições é feita por administradores da empresa, normalmente através de um portal de faturação ou fluxo de checkout.

## Notas
- A restrição `UNIQUE` em `company_id` garante que uma empresa só pode ter uma subscrição ativa de cada vez.
