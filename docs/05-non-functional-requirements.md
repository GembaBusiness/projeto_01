# 5. Requisitos Não-Funcionais

Este documento descreve os requisitos não-funcionais (RNFs) do sistema, que definem os critérios de qualidade, desempenho e segurança.

## RNF-01: Segurança

-   **Isolamento de Dados (Multi-Tenant):** O sistema DEVE garantir que os dados de uma empresa (tenant) sejam completamente inacessíveis a qualquer outra empresa.
    -   **Medida:** Implementação rigorosa de políticas de Row Level Security (RLS) no PostgreSQL para todas as tabelas que contêm dados de tenants. Todas as queries devem ser filtradas por `company_id`.
-   **Autenticação Segura:** As senhas dos usuários DEVEM ser armazenadas de forma segura, utilizando os mecanismos de hashing fornecidos pelo Supabase Auth.
-   **Proteção contra Vulnerabilidades Comuns:** A aplicação deve ser protegida contra ataques comuns da web (ex: XSS, CSRF), aproveitando as boas práticas e proteções nativas do WeWeb e Supabase.

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
