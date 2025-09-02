# Tabela: `subscription_history`

**Finalidade e Justificativa:**
Esta tabela funciona como um log de auditoria para cada assinatura, registando todos os eventos importantes do seu ciclo de vida. Ela é crucial para entender o histórico de um cliente, depurar problemas de faturação e analisar padrões de upgrade, downgrade ou cancelamento.

**DDL (SQL):**
```sql
CREATE TYPE public.subscription_event_type AS ENUM ('created', 'upgraded', 'downgraded', 'renewed', 'canceled');

CREATE TABLE public.subscription_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  event_type public.subscription_event_type NOT NULL,
  from_price_id UUID REFERENCES public.prices(id),
  to_price_id UUID REFERENCES public.prices(id),
  event_date TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.subscription_history IS 'Armazena o histórico de eventos de uma assinatura.';

-- Índice para otimizar a busca do histórico de uma assinatura específica.
CREATE INDEX IF NOT EXISTS idx_subscription_history_subscription_id ON public.subscription_history(subscription_id);
```

**Campos e Restrições:**
-   `id` (UUID, PK): Chave primária do registo de histórico.
-   `subscription_id` (UUID, NOT NULL, FK): Referencia a assinatura à qual este evento pertence.
-   `event_type` (ENUM, NOT NULL): O tipo de evento que ocorreu (ex: `upgraded`, `canceled`).
-   `from_price_id` (UUID, FK): O preço anterior da assinatura (relevante para `upgraded`, `downgraded`).
-   `to_price_id` (UUID, FK): O novo preço da assinatura (relevante para `created`, `upgraded`, `downgraded`).
-   `event_date` (TIMESTAMPTZ, NOT NULL): A data e hora em que o evento ocorreu.

## Políticas de Row Level Security (RLS)
- **`select`**: Um administrador da empresa pode ver o histórico de subscrições da sua empresa.
- **`insert`**: A inserção é feita por funções do sistema ou `triggers` em resposta a eventos de subscrição.

## Notas
- Esta tabela serve como um registo de auditoria para as subscrições.
