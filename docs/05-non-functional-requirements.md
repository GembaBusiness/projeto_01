# 5. Requisitos Não-Funcionais

Este documento descreve os requisitos não-funcionais (RNFs) do sistema, que definem os critérios de qualidade, desempenho e segurança.

## RNF-01: Segurança

### RNF-01.1: Isolamento de Dados (Multi-Tenant)
-   **Requisito:** O sistema DEVE garantir que os dados de uma empresa (tenant) sejam completamente inacessíveis a qualquer outra empresa.
-   **Medida:** Implementação rigorosa de políticas de Row Level Security (RLS) no PostgreSQL. Todas as queries devem ser filtradas por `company_id`. Este padrão é a base da nossa [Arquitetura Híbrida RBAC + ABAC](./01-system-architecture.md#151-arquitetura-híbrida-rbac--abac).

### RNF-01.2: Autenticação Segura
-   **Requisito:** As senhas e sessões dos usuários DEVEM ser gerenciadas de forma segura.
-   **Medida:** Utilização dos mecanismos de hashing do Supabase Auth para senhas. Os requisitos funcionais para autenticação, incluindo MFA, estão em [FR-001-authentication.md](./04-functional-requirements/FR-001-authentication.md).

### RNF-01.3: Segurança de Armazenamento de Ficheiros
-   **Requisito:** Os ficheiros enviados pelos usuários DEVEM ser armazenados de forma segura e com escopo por tenant.
-   **Medida:** Utilização do Supabase Storage com políticas de acesso baseadas na `company_id` para garantir que um tenant não acesse os ficheiros de outro. Implementação de varredura de vírus no upload.

### RNF-01.4: Políticas de Sessão e Palavra-passe
-   **Requisito:** O sistema DEVE impor políticas robustas para a gestão de sessões e a complexidade das palavras-passe.
-   **Medida:** Exigência de comprimento mínimo e complexidade para senhas. As sessões DEVEM expirar após um período de inatividade. O sistema DEVE ter proteção contra ataques de força bruta.

---

## RNF-02: Performance

-   **Tempo de Carregamento:** O tempo de carregamento inicial do dashboard principal DEVE ser inferior a 3 segundos.
-   **Responsividade da API:** As chamadas à API DEVEM ter um tempo de resposta médio inferior a 500ms. A performance é garantida por práticas como paginação e indexação, definidas nos [Contratos da API](./07-api-contracts-and-policies.md) e no [Esquema da Base de Dados](./03-database-schema.md).

---

## RNF-03: Usabilidade

-   **Responsividade da Interface:** A UI DEVE ser totalmente responsiva (desktop, tablet, mobile).
-   **Consistência Visual:** A aplicação DEVE seguir as diretrizes do [Guia de Estilo do WeWeb](./06-weweb-style-guide.md).

---

## RNF-04: Manutenibilidade

-   **Documentação:** A documentação DEVE ser mantida atualizada.
-   **Nomenclatura:** Os nomes de variáveis e componentes DEVEM seguir as convenções do [Guia de Estilo do WeWeb](./06-weweb-style-guide.md).

---

## RNF-05: Confiabilidade e Resiliência

### RNF-05.1: Concorrência Otimista
-   **Requisito:** O sistema DEVE prevenir condições de corrida (race conditions) em operações concorrentes sobre o mesmo recurso.
-   **Medida:** Utilização de um campo de versão (`version` ou `updated_at`) nas tabelas críticas. A lógica de verificação é um dos nossos principais [Padrões de Arquitetura](./01-system-architecture.md#15-padrões-de-arquitetura).

### RNF-05.2: Backup e Restauração
-   **Requisito:** O sistema DEVE ter uma política de backup e restauração bem definida.
-   **Medida:** Configuração dos backups automáticos do Supabase (PITR). Os objetivos de **RPO (Recovery Point Objective)** e **RTO (Recovery Time Objective)** DEVEM ser formalmente definidos. Os procedimentos de teste de restauração estão documentados no [Runbook Operacional](./08-operations-and-testing.md#813-runbook-operacional).

---

## RNF-06: Privacidade e Compliance (LGPD/GDPR)

### RNF-06.1: Minimização de PII
-   **Requisito:** O sistema DEVE coletar e armazenar apenas as Informações de Identificação Pessoal (PII) estritamente necessárias.
-   **Medida:** Realizar uma auditoria periódica dos dados coletados para garantir que nenhum dado supérfluo seja armazenado.

### RNF-06.2: Política de "Soft Delete"
-   **Requisito:** Para permitir a recuperação de dados e manter a integridade referencial, os recursos não devem ser excluídos permanentemente (hard delete) por padrão.
-   **Medida:** As tabelas principais devem conter um campo `deleted_at` (timestamp). A exclusão de um item apenas preenche este campo. As consultas à API devem ser ajustadas para excluir estes itens por padrão. Este comportamento é definido no nosso [Contrato de Consulta](./07-api-contracts-and-policies.md#71-contrato-de-consulta-querying).

### RNF-06.3: Exclusão/Anonimização de Dados (Hard Delete)
-   **Requisito:** O sistema DEVE fornecer um mecanismo para a exclusão ou anonimização completa e permanente dos dados de um tenant, a pedido.
-   **Medida:** Criação de um procedimento detalhado no [Runbook Operacional](./08-operations-and-testing.md#813-runbook-operacional) para localizar e apagar/anonimizar todos os dados associados a uma `company_id`.

### RNF-06.4: Registo de Consentimentos
-   **Requisito:** O sistema DEVE manter um registo auditável de todos os consentimentos dados pelos usuários.
-   **Medida:** Utilização das tabelas [`consent_types`](./03-database-schema.md#consent_types) e [`user_consents`](./03-database-schema.md#user_consents) para registar quando cada usuário aceitou cada versão dos documentos legais.
