# Tabela: `plan_features`

**Finalidade e Justificativa:**
Tabela de junção N-para-N que define quais `features` estão incluídas em cada `plan`.

**DDL (SQL):**
```sql
CREATE TABLE public.plan_features (
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  feature_id UUID NOT NULL REFERENCES public.features(id) ON DELETE CASCADE,
  PRIMARY KEY (plan_id, feature_id)
);

-- Índice para otimizar a busca de planos por feature.
CREATE INDEX idx_plan_features_feature_id ON public.plan_features(feature_id);
```

## Políticas de Row Level Security (RLS)
- **`select`**: Todos os utilizadores autenticados podem ler as funcionalidades do plano.
- **`insert`/`update`/`delete`**: Apenas um super-administrador pode modificar as funcionalidades do plano.

## Notas
- Esta tabela de junção define as funcionalidades disponíveis para cada plano.
