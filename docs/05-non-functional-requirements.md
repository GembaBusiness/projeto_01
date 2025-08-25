# 5. Requisitos Não-Funcionais

Este documento descreve os requisitos não-funcionais (RNFs) do sistema, que definem os critérios de qualidade, desempenho e segurança.

## RNF-01: Segurança

-   **Isolamento de Dados (Multi-Tenant):** O sistema DEVE garantir que os dados de uma empresa (tenant) sejam completamente inacessíveis a qualquer outra empresa.
    -   **Medida:** Implementação rigorosa de políticas de Row Level Security (RLS) no PostgreSQL para todas as tabelas que contêm dados de tenants. Todas as queries devem ser filtradas por `company_id`.
-   **Autenticação Segura:** As senhas dos usuários DEVEM ser armazenadas de forma segura, utilizando os mecanismos de hashing fornecidos pelo Supabase Auth.
-   **Proteção contra Vulnerabilidades Comuns:** A aplicação deve ser protegida contra ataques comuns da web (ex: XSS, CSRF), aproveitando as boas práticas e proteções nativas do WeWeb e Supabase.

### RNF-01.1: Segurança de Armazenamento de Ficheiros
-   **Descrição:** Os ficheiros enviados pelos usuários (e.g., avatares, documentos) DEVEM ser armazenados de forma segura e com escopo por tenant.
-   **Medida:**
    1.  Utilização do Supabase Storage para armazenamento.
    2.  Os ficheiros devem ser organizados em buckets ou pastas com base na `company_id`.
    3.  Políticas de acesso no Storage DEVEM ser configuradas para garantir que um usuário só possa acessar ou fazer upload para o diretório da sua própria empresa.
    4.  Implementação de varredura de vírus no upload de ficheiros para prevenir a distribuição de malware.

### RNF-01.2: Políticas de Sessão e Palavra-passe
-   **Descrição:** O sistema DEVE impor políticas robustas para a gestão de sessões e a complexidade das palavras-passe.
-   **Medida:**
    1.  **Expiração de Sessão:** As sessões de usuário DEVEM expirar automaticamente após um período de inatividade (e.g., 24 horas para sessão ativa, 30 minutos para inatividade).
    2.  **Complexidade da Palavra-passe:** As palavras-passe definidas pelos usuários DEVEM exigir um comprimento mínimo (e.g., 12 caracteres) e uma combinação de letras maiúsculas, minúsculas, números e símbolos.
    3.  **Proteção contra Brute-force:** O sistema de autenticação DEVE ter proteção contra ataques de força bruta (e.g., bloqueio temporário de conta após várias tentativas falhadas).

## RNF-02: Performance

-   **Tempo de Carregamento da Página:** O tempo de carregamento inicial do dashboard principal (após login) DEVE ser inferior a 3 segundos em uma conexão de internet de banda larga padrão.
    -   **Medida:** Otimização de queries ao banco de dados, uso de paginação em listas longas e carregamento assíncrono de dados sempre que possível.
-   **Responsividade da API:** As chamadas à API do Supabase para operações comuns (leitura, escrita) DEVEM ter um tempo de resposta médio inferior a 500ms.
    -   **Medida:** Criação de índices apropriados nas colunas do banco de dados que são frequentemente usadas em cláusulas `WHERE` (ex: `company_id`, `user_id`).

## RNF-03: Usabilidade

-   **Responsividade da Interface:** A interface do usuário DEVE ser totalmente responsiva e funcional em dispositivos desktop, tablets e móveis.
    -   **Medida:** Utilização dos recursos de design responsivo do WeWeb, garantindo que todos os componentes se adaptem a diferentes tamanhos de tela.
-   **Consistência Visual:** A aplicação DEVE manter uma identidade visual consistente em todas as páginas, seguindo as diretrizes definidas no `06-weweb-style-guide.md`.
-   **Feedback ao Usuário:** O sistema DEVE fornecer feedback claro e imediato para as ações do usuário (ex: mensagens de sucesso, erro, indicadores de carregamento).

## RNF-04: Manutenibilidade

-   **Documentação:** A documentação (este repositório) DEVE ser mantida atualizada a cada nova funcionalidade ou mudança arquitetónica.
-   **Nomenclatura:** Os nomes de variáveis, componentes e páginas no WeWeb DEVEM seguir as convenções definidas no `06-weweb-style-guide.md` para facilitar a compreensão e manutenção.

## RNF-05: Confiabilidade e Resiliência

-   **Concorrência Otimista:** Para evitar condições de corrida (race conditions) em operações concorrentes sobre o mesmo recurso, o sistema DEVE usar um mecanismo de concorrência otimista.
    -   **Medida:** Utilização de um campo de versão (`version` ou `updated_at`) nas tabelas críticas. Antes de uma operação de UPDATE, o sistema verifica se a versão do registo não mudou desde que foi lido. Se mudou, a operação é rejeitada para evitar a sobreposição de dados.
-   **Backup e Restauração:** O sistema DEVE ter uma política de backup e restauração bem definida para garantir a recuperação de dados em caso de desastre.
    -   **Medida:**
        1.  Configuração dos backups automáticos do Supabase (Point-in-Time Recovery - PITR).
        2.  Os objetivos de **RPO (Recovery Point Objective)** e **RTO (Recovery Time Objective)** DEVEM ser formalmente definidos (e.g., RPO de 24 horas, RTO de 2 horas).
        3.  Procedimentos de restauração DEVEM ser testados periodicamente.

## RNF-06: Privacidade e Compliance (LGPD/GDPR)

-   **Minimização de PII:** O sistema DEVE coletar e armazenar apenas as Informações de Identificação Pessoal (PII) estritamente necessárias para a sua operação.
    -   **Medida:** Realizar uma auditoria dos dados coletados e remover/anonimizar quaisquer campos que não sejam essenciais para o negócio.
-   **Exclusão/Anonimização de Dados:** O sistema DEVE fornecer um mecanismo para que os administradores de um tenant possam solicitar a exclusão ou anonimização completa dos dados da sua empresa.
    -   **Medida:** Criação de um procedimento (runbook) que detalha os passos para localizar e apagar/anonimizar todos os dados associados a uma `company_id`, incluindo dados no banco de dados e no storage.
-   **Registo de Consentimentos:** O sistema DEVE manter um registo auditável de todos os consentimentos dados pelos usuários.
    -   **Medida:** A tabela `user_consents` DEVE ser usada para registar quando cada usuário aceitou cada versão dos documentos legais (e.g., Termos de Serviço, Política de Privacidade).
