# Tabela: `prices`

**Finalidade e Justificativa:**
Desacopla os planos dos seus preços. Um mesmo plano "Pro" pode ter um preço mensal e um anual. A coluna `provider_price_id` é essencial para a integração com gateways de pagamento como o Stripe, armazenando o ID do preço correspondente nesse serviço.

**DDL (SQL):**
```sql
CREATE TYPE public.billing_interval AS ENUM ('month', 'year');

CREATE TABLE public.prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'BRL',
  interval public.billing_interval NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  provider_price_id TEXT
);

-- Índice para otimizar a busca de preços de um plano.
CREATE INDEX idx_prices_plan_id ON public.prices(plan_id);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler os preços.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar os preços.

## Notas
- A coluna `provider_price_id` é usada para integrar com serviços de pagamento externos como o Stripe.
