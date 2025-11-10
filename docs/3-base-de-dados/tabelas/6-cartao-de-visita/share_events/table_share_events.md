# Tabela: `share_events`

**Finalidade e Justificativa:**
Esta tabela registra cada evento de interação com um link de compartilhamento, como toques NFC, escaneamentos de QR code e cliques em links. Ela fornece dados granulares para analytics, permitindo rastrear a eficácia dos diferentes métodos de compartilhamento.

**DDL (SQL):**
```sql
CREATE TABLE share_events (
  -- Identificação
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  share_id UUID NOT NULL,

  -- Tipo de evento
  event_type share_event_type NOT NULL,

  -- Contexto específico deste uso
  event_context JSONB,

  -- Dados técnicos da interação
  ip_address INET,
  user_agent TEXT,
  referrer TEXT,
  geolocation JSONB,

  -- Timestamp
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Foreign Key
  CONSTRAINT fk_share
    FOREIGN KEY (share_id)
    REFERENCES profile_shares(id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_events_share ON share_events(share_id);
CREATE INDEX idx_events_type ON share_events(event_type);
CREATE INDEX idx_events_date ON share_events(occurred_at DESC);
CREATE INDEX idx_events_share_date ON share_events(share_id, occurred_at DESC);
CREATE INDEX idx_events_ip ON share_events(ip_address);
```

**Campos e Restrições:**
- `share_id` (UUID, FK): Referencia o link de compartilhamento que gerou o evento.
- `event_type` (ENUM): O tipo de evento ocorrido (ex: `nfc_tap`, `qr_scan`).
- `event_context` (JSONB): Permite armazenar metadados adicionais sobre o evento, como a campanha ou localização.
- `occurred_at` (TIMESTAMPTZ): O carimbo de data/hora exato do evento.

**Políticas de Row Level Security (RLS):**

```sql
ALTER TABLE share_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuários podem ver eventos de seus shares"
ON share_events FOR SELECT
TO authenticated
USING (
  share_id IN (
    SELECT ps.id FROM profile_shares ps
    WHERE ps.public_profile_id IN (
      SELECT id FROM public_profiles WHERE profile_id = (SELECT auth.uid())
    )
  ) AND
  custom_auth_helpers.has_permission('share_events.read')
);

CREATE POLICY "Qualquer pessoa pode criar eventos"
ON share_events FOR INSERT
WITH CHECK (true);

CREATE POLICY "Apenas sistema pode atualizar eventos"
ON share_events FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Apenas sistema pode deletar eventos"
ON share_events FOR DELETE
TO service_role
USING (true);
```

**Notas:**
- Esta tabela é projetada para ter um alto volume de inserções (`INSERT`).
- A política de `INSERT` é aberta (`WITH CHECK (true)`), permitindo que sistemas externos (como o frontend ou um servidor de redirecionamento) registrem eventos de forma anônima.
- As operações de `UPDATE` e `DELETE` são restritas a `service_role` para garantir a imutabilidade dos registros de eventos.
