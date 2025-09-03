# Tabela: `user_consents`

**Finalidade e Justificativa:**
Esta tabela é o registro de auditoria que vincula um usuário (`user_id`) a uma versão específica de um documento de consentimento (`consent_id`). Cada linha representa a prova de que um usuário concordou com um determinado termo em uma data específica. O `ON DELETE CASCADE` garante que, se um usuário ou um tipo de consentimento for removido, o registro de consentimento correspondente também seja limpo para manter a integridade dos dados.

**DDL (SQL):**
```sql
CREATE TABLE public.user_consents (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_id UUID NOT NULL REFERENCES public.consent_types(id) ON DELETE CASCADE,
  consented_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, consent_id)
);

COMMENT ON TABLE public.user_consents IS 'Registra qual usuário consentiu com qual versão de um documento.';

-- Índice para otimizar a busca de usuários que aceitaram um termo específico.
CREATE INDEX idx_user_consents_consent_id ON public.user_consents(consent_id);
```

**Campos e Restrições:**
-   `user_id` (UUID, NOT NULL, FK): Referencia o usuário que deu o consentimento.
-   `consent_id` (UUID, NOT NULL, FK): Referencia a versão específica do documento com a qual o usuário concordou.
-   `consented_at` (TIMESTAMPTZ, NOT NULL): A data e hora exatas em que o consentimento foi dado.
-   `PRIMARY KEY (user_id, consent_id)`: Garante que um usuário só possa consentir com a mesma versão de um documento uma única vez.

## Políticas de Row Level Security (RLS)
- **`select`**: Um utilizador pode ver os seus próprios consentimentos.
- **`insert`**: Um utilizador pode inserir o seu próprio consentimento.
- **`update`/`delete`**: Não é permitido atualizar ou apagar registos de consentimento para manter a integridade da auditoria.

## Notas
- Esta tabela serve como um registo de auditoria imutável para o consentimento do utilizador.
