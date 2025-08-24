# Requisito Funcional: RBAC e Permissões

**ID:** FR-002
**Título:** Controle de Acesso Baseado em Papéis (RBAC) e Permissões

## Descrição
Este documento detalha os requisitos para o sistema de controle de acesso, que restringe as ações e a visibilidade dos dados com base no papel atribuído a um usuário dentro da sua empresa.

## Requisitos

### RF-02.1: Papéis Pré-definidos
-   **Descrição:** O sistema deve ter um conjunto de papéis pré-definidos com diferentes níveis de acesso (ex: Administrador, Usuário Padrão, Visualizador).
-   **Critérios de Aceitação:**
    1.  A tabela `roles` no banco de dados deve ser populada com os papéis iniciais.
    2.  Cada papel deve ter um conjunto claro de permissões associadas na tabela `role_permissions`.
    3.  Um Administrador da empresa pode atribuir ou alterar o papel de outros usuários dentro da sua própria empresa.

### RF-02.2: Menu de Navegação Dinâmico
-   **Descrição:** O menu de navegação principal da aplicação deve ser renderizado dinamicamente, mostrando apenas os itens aos quais o usuário tem permissão para acessar.
-   **Critérios de Aceitação:**
    1.  A tabela `navigation_items` deve conter uma coluna `required_permission`.
    2.  Ao carregar a aplicação, o frontend deve buscar os itens de navegação e as permissões do usuário logado.
    3.  Apenas os itens de menu cujo `required_permission` corresponda a uma das permissões do usuário (através do seu papel) devem ser exibidos.

### RF-02.3: Visibilidade Condicional de Elementos de UI
-   **Descrição:** Elementos específicos da interface do usuário (botões, formulários, colunas de tabelas) devem ser visíveis ou habilitados apenas para usuários com as permissões apropriadas.
-   **Critérios de Aceitação:**
    1.  O frontend deve ser capaz de verificar se o usuário atual possui uma permissão específica (ex: 'users:create').
    2.  O botão "Convidar Usuário" só deve ser visível para usuários com a permissão 'users:create'.
    3.  A coluna "Salário" em uma tabela de funcionários só deve ser visível para usuários com a permissão 'employees:read:salary'.
    4.  A lógica de visibilidade deve ser aplicada de forma consistente em toda a aplicação.
