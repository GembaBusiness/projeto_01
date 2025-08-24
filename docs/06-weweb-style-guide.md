# 6. Guia de Estilo do WeWeb

Este documento serve como um guia de estilo para o desenvolvimento no WeWeb, garantindo consistência, manutenibilidade e escalabilidade do projeto frontend.

## 6.1. Nomenclatura

Uma nomenclatura consistente é fundamental para um projeto organizado.

### 6.1.1. Páginas
-   **Padrão:** `kebab-case` (letras minúsculas, separadas por hífen).
-   **Exemplos:**
    -   `auth-login`
    -   `user-dashboard`
    -   `company-settings`

### 6.1.2. Componentes Reutilizáveis
-   **Padrão:** `PascalCase` (começa com letra maiúscula).
-   **Exemplos:**
    -   `PrimaryButton`
    -   `UserAvatar`
    -   `DataTable`

### 6.1.3. Variáveis e Fórmulas
-   **Padrão:** `camelCase` (começa com letra minúscula).
-   **Prefixos Sugeridos:**
    -   `tmp_` para variáveis temporárias de workflow.
    -   `data_` para variáveis que armazenam dados de coleções.
    -   `form_` para variáveis ligadas a inputs de formulário.
    -   `is_` ou `has_` para variáveis booleanas.
-   **Exemplos:**
    -   `data_userProfile`
    -   `form_emailInput`
    -   `is_modalOpen`
    -   `has_unsavedChanges`

### 6.1.4. Workflows (Ações)
-   **Padrão:** Descreva a ação de forma clara, usando `PascalCase`.
-   **Exemplos:**
    -   `On Page Load -> FetchUserData`
    -   `On Button Click -> SubmitLoginForm`
    -   `On Input Change -> ValidateEmailFormat`

## 6.2. Padrões Visuais

### 6.2.1. Cores
Defina a paleta de cores como variáveis globais no WeWeb para fácil reutilização e alteração.

-   **Primária:** `#4F46E5` (Indigo 600) - *Placeholder*
-   **Secundária:** `#10B981` (Emerald 500) - *Placeholder*
-   **Texto Principal:** `#111827` (Gray 900) - *Placeholder*
-   **Texto Secundário:** `#6B7280` (Gray 500) - *Placeholder*
-   **Fundo:** `#F9FAFB` (Gray 50) - *Placeholder*
-   **Erro:** `#EF4444` (Red 500) - *Placeholder*
-   **Sucesso:** `#22C55E` (Green 500) - *Placeholder*

### 6.2.2. Tipografia
Defina os estilos de texto (headings, parágrafos) como "Design System" no WeWeb.

-   **Fonte Principal:** Inter (ou outra fonte sans-serif) - *Placeholder*
-   **H1 (Título 1):** 36px, Bold
-   **H2 (Título 2):** 24px, Bold
-   **H3 (Título 3):** 20px, SemiBold
-   **Body (Corpo de Texto):** 16px, Regular
-   **Small (Texto Pequeno):** 14px, Regular

## 6.3. Estrutura e Organização

-   **Componentização:** Sempre que um conjunto de elementos se repetir em mais de uma página, crie um componente reutilizável.
-   **Dados Globais:** Use o `App Data` para armazenar dados que precisam ser acessados globalmente (ex: perfil do usuário logado, configurações da empresa).
-   **Workflows Globais:** Crie workflows globais para ações que podem ser disparadas de múltiplos locais (ex: `logoutUser`, `showNotification`).
