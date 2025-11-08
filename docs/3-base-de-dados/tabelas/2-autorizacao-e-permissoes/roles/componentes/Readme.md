# Documentação do Sistema: Editor de Permissões de Acesso

**Versão:** 1.4
**Data:** 07 de Novembro de 2025
**Autor:** (Nome do Autor/Equipe)

## 1. Visão Geral e Objetivos

### 1.1. Introdução

Este documento detalha o comportamento e a arquitetura do componente "Editor de Permissões de Acesso" (Role Permissions Editor), uma solução customizada desenvolvida em WeWeb e integrada ao Supabase.

O objetivo principal deste componente é fornecer uma interface visual intuitiva para gerenciar permissões de usuários baseadas em papéis (roles), otimizando a performance e a experiência do usuário através de um sistema de salvamento em lote (batch save).

### 1.2. Principais Funcionalidades

- **Salvamento em Lote (Batch Save):** Minimiza o número de chamadas à API. O usuário pode fazer múltiplas alterações na interface (adicionar ou remover dezenas de permissões) e o sistema só executará as operações no banco de dados no momento do salvamento final.
- **Cancelamento Fácil:** Como as alterações são rastreadas localmente, o usuário pode cancelar todas as suas modificações pendentes simplesmente fechando o modal, sem que nenhuma alteração seja persistida.
- **Feedback Visual Imediato:** A interface (checkboxes) responde instantaneamente à ação do usuário, dando-lhe a sensação de controle e agilidade, mesmo que a operação no banco de dados ainda não tenha ocorrido.
- **Segurança Integrada:** O componente respeita e opera dentro das regras de Segurança em Nível de Linha (Row Level Security - RLS) configuradas no Supabase, garantindo que os usuários só possam gerenciar permissões dentro de seu próprio escopo (ex: sua própria empresa).

## 2. Arquitetura e Fluxo do Usuário

O fluxo de gerenciamento de permissões é centralizado em um único modal (pop-up), que se adapta dinamicamente dependendo da ação do usuário. O comportamento deste modal é controlado pela propriedade `isEdit`.

### 2.1. Fluxo de Usuário

1. **Tela Principal (Lista de Regras):** O usuário visualiza todos os papéis (roles) existentes em formato de cards. Cada card já armazena o JSON completo da regra, incluindo suas permissões (`role_permissions`).
2. Clicar em "Adicionar Nova Regra".
3. Clicar em "Editar Regras" em um card existente.
4. **Ação: Abrir Modal (Criação ou Edição)**
   - **Ao clicar em "Adicionar Nova Regra":**
     - O modal é aberto.
     - A propriedade `isEdit` é passada ao modal com o valor `false`.
     - O modal exibe apenas o campo para o Nome da nova regra. O editor de permissões fica oculto.
   - **Ao clicar em "Editar Regras":**
     - O JSON completo do card clicado é passado para a propriedade interna `Dados` do modal. Nenhuma nova busca ao banco é necessária.
     - O modal é aberto.
     - A propriedade `isEdit` é passada ao modal com o valor `true`.
     - Os dados da regra são carregados no modal.
     - O modal exibe o componente "Editor de Permissões", que carrega todas as permissões do sistema e marca aquelas que a regra selecionada já possui (lendo da propriedade `Dados`).

## 3. Lógica de Funcionamento (Batch Save)

Quando em modo de edição (ou seja, a propriedade `isEdit` é `true`), o núcleo do componente reside em como ele gerencia as alterações pendentes. Para isso, o modal utiliza duas listas (variáveis) temporárias internas.

- **Lista `item_added`:** Armazena permissões que devem ser adicionadas no salvamento.
- **Lista `item_remove`:** Armazena permissões que devem ser removidas no salvamento.

### 3.1. A Lógica do Clique (Toggle)

(Esta lógica só é ativada quando `isEdit = true`)

Quando o usuário clica em um checkbox (marcando ou desmarcando uma permissão), o sistema executa a seguinte lógica:

- **Cenário 1: A permissão clicada JÁ EXISTIA no banco de dados (checkbox estava marcado).**
  - **Intenção do Usuário:** Remover esta permissão.
  - **Ação do Sistema:**
    - O sistema verifica a lista `item_remove`.
    - Se a permissão já estiver na lista `item_remove` (o usuário está "cancelando a remoção"), ela é retirada da lista `item_remove`.
    - Se a permissão não estiver na lista `item_remove`, ela é adicionada a essa lista, marcando-a para exclusão futura.

- **Cenário 2: A permissão clicada NÃO EXISTIA no banco de dados (checkbox estava desmarcado).**
  - **Intenção do Usuário:** Adicionar esta permissão.
  - **Ação do Sistema:**
    - O sistema verifica a lista `item_added`.
    - Se a permissão já estiver na lista `item_added` (o usuário está "cancelando a adição"), ela é retirada da lista `item_added`.
    - Se a permissão não estiver na lista `item_added`, ela é adicionada a essa lista, marcando-a para adição futura.

**Resultado:** Esta lógica permite que o usuário clique múltiplas vezes no mesmo checkbox, "arrependendo-se" de suas ações, sem que o sistema perca o estado final desejado.

## 4. Workflows (Processos do Sistema)

### 4.1. Workflow: Abrir Modal (Dinâmico)

- **Gatilho 1 (Criação):** Usuário clica em "Adicionar Nova Regra".
  - **Ação:** O modal é aberto, passando a propriedade `isEdit` como `false`. As listas `item_added` e `item_remove` são esvaziadas (caso contenham dados de uma sessão anterior).
- **Gatilho 2 (Edição):** Usuário clica em "Editar Regras".
  - **Ação 1 - Configurar Popup:** O modal é aberto. O JSON completo do card é passado para a propriedade `Dados` do modal. A propriedade `isEdit` é passada como `true`.
  - **Ação 2 - Limpar Cache:** As listas `item_added` e `item_remove` são esvaziadas (para garantir uma sessão limpa).

### 4.2. Workflow: Gerenciar Mudanças (Toggle)

(Este workflow só é executado se `isEdit = true`)

- **Gatilho:** O componente "role-permissions-editor" dispara um evento interno ("permission-toggled") sempre que um checkbox é clicado.
- **Ação:** O sistema recebe os detalhes da permissão clicada (ID, e se a ação é "adicionar" ou "remover").
- **Lógica:** A lógica descrita na Seção 3.1 é executada para adicionar ou remover o item das listas `item_added` ou `item_remove`.

### 4.3. Workflow: Salvar Alterações (Submit)

- **Gatilho:** Usuário clica no botão "Salvar" (ou "Atualizar") no modal.
- **Ação Condicional:** O sistema verifica o valor da propriedade `isEdit`.
  - **SE `isEdit` for `false` (Modo Criação):**
    - O sistema pega o Nome da regra digitado pelo usuário.
    - Executa um único comando de inserção na tabela `roles` do Supabase para criar a nova regra.
    - O novo card aparece na lista principal.
  - **SE `isEdit` for `true` (Modo Edição de Permissões):**
    - **Inserir Novas:** O sistema verifica a lista `item_added`. Se ela contiver itens, ele utiliza uma ação nativa do plugin Supabase que permite a inserção em lote (batch insert). O sistema simplesmente passa o array `item_added` (formatado corretamente) para esta ação, que insere todos os novos registros de uma só vez.
    - **Remover Antigas:** O sistema percorre a lista `item_remove` e executa um comando de exclusão (delete) para cada permissão.
    - **(Opcional):** Se o nome da regra também foi alterado, atualiza o nome na tabela `roles`.
- **Ação Final (Comum):**
  - As listas `item_added` e `item_remove` são esvaziadas.
  - O modal é fechado.
  - Uma notificação de sucesso é exibida.

### 4.4. Workflow: Fechar Modal (Sem Salvar)

- **Gatilho:** Usuário clica no ícone 'X', pressiona 'ESC' ou clica fora da área do modal.
- **Ação:** Um workflow é acionado para esvaziar as listas `item_added` e `item_remove`.
- **Resultado:** Nenhuma alteração é salva e todas as mudanças pendentes da sessão são permanentemente descartadas.

## 5. Configuração no WeWeb

Para a correta implementação, as seguintes configurações são necessárias no editor do WeWeb:

- **Collection 'Permissions':**
  - Deve ser criada uma collection (fonte de dados) conectada ao Supabase para buscar todas as permissões disponíveis no sistema (ex: `SELECT * FROM permissions`).
  - É recomendado que ela seja ordenada (ex: por tabela, depois por ação).

- **Configuração do Popup (Modal Único):**
  - **Propriedades:** O modal deve ter propriedades para receber dados externos (passados pelo workflow que o abre):
    - `Title` (Texto): Ex: "Gerenciar Regra".
    - `Dados` (Objeto): Recebe o JSON completo da regra selecionada.
    - `isEdit` (Booleano): Controla o modo do modal. `true` para edição, `false` para criação.
  - **Variáveis Internas:** O modal deve conter:
    - `item_added` (Array): Para o "batch save". Valor inicial: `[]`.
    - `item_remove` (Array): Para o "batch save". Valor inicial: `[]`.
  - **Visibilidade Condicional:**
    - O campo "Nome da Regra" deve ser visível sempre.
    - O "Editor de Permissões" (e seu contêiner) deve ter a visibilidade definida como: Propriedade `isEdit === true`.

- **Conexão do Componente (Bindings):**
  - O componente "role-permissions-editor" deve ser inserido no modal (dentro do contêiner que ficará visível apenas se `isEdit = true`).
  - Suas propriedades principais devem ser conectadas (binded) às fontes de dados corretas:
    - `allPermissions` (Todas as Permissões) -> Deve ser conectado à collection 'permissions'.
    - `activePermissions` (Permissões Ativas) -> Deve ser conectado à lista `role_permissions` dentro da propriedade `Dados` do modal. (Ex: `Dados.role_permissions`)
    - `roleId` (ID da Regra) -> Deve ser conectado ao `id` dentro da propriedade `Dados` do modal. (Ex: `Dados.id`)
