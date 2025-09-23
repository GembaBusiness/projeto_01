# Documentação do Módulo de Navegação Baseado em Permissões

## 1. Visão Geral

Este documento descreve a arquitetura e o funcionamento do módulo de navegação do sistema. O objetivo principal deste módulo é construir e exibir dinamicamente os menus de navegação (barras laterais, menus superiores, etc.) com base nas permissões específicas de cada usuário autenticado.

A lógica é centralizada no banco de dados PostgreSQL, utilizando Tabelas, Funções e Políticas de Segurança em Nível de Linha (Row-Level Security - RLS) para garantir que um usuário possa visualizar apenas os itens de menu para os quais possui autorização explícita.

## 2. Arquitetura e Componentes

O sistema é composto por três componentes principais que trabalham em conjunto:

-   **Tabelas de Dados:** Armazenam a estrutura do menu, as permissões disponíveis e a relação entre eles.
-   **Função de Autorização:** Uma função PL/pgSQL que encapsula a lógica de verificação de acesso para um item de menu específico.
-   **Política de Segurança (RLS):** Uma regra aplicada diretamente na tabela de itens de navegação que utiliza a função de autorização para filtrar os resultados de qualquer consulta, garantindo a aplicação da segurança em nível de banco de dados.

### 2.1. Estrutura do Banco de Dados

As três tabelas a seguir formam o núcleo do sistema de navegação.

#### Tabela: `public.navigation_items`

Esta tabela define a estrutura hierárquica de todos os possíveis itens de navegação no sistema.

| Coluna          | Tipo    | Descrição                                                                      |
| --------------- | ------- | ------------------------------------------------------------------------------ |
| `id`            | `uuid`  | Chave primária única para cada item de menu.                                   |
| `key`           | `text`  | Um identificador textual único (e.g., "dashboard", "users-list").              |
| `label`         | `text`  | O texto que será exibido para o usuário (e.g., "Painel Principal").            |
| `path`          | `text`  | O caminho da rota (URL) para o qual o item aponta (e.g., "/dashboard").        |
| `icon`          | `text`  | O nome ou classe de um ícone a ser exibido ao lado do label.                   |
| `parent_id`     | `uuid`  | Chave estrangeira que aponta para o `id` de outro item, criando a hierarquia.  |
| `display_order` | `integer` | Define a ordem de exibição dos itens dentro do mesmo nível hierárquico.        |
| `is_active`     | `boolean` | Flag para ativar ou desativar um item de menu globalmente.                     |
| `group`         | `text`  | Um campo opcional para agrupar itens, como "Configurações" ou "Relatórios".    |

**Índice:** `idx_navigation_items_parent_id` otimiza as consultas para construir a árvore de navegação.

#### Tabela: `public.permissions`

Armazena a lista de todas as permissões disponíveis no sistema.

| Coluna        | Tipo   | Descrição                                                          |
| ------------- | ------ | -------------------------------------------------------------------- |
| `id`          | `uuid` | Chave primária única da permissão.                                   |
| `name`        | `text` | Nome único da permissão (e.g., "users.read", "reports.generate").    |
| `description` | `text` | Descrição amigável do que a permissão concede.                       |

#### Tabela: `public.nav_item_permissions`

Esta é uma tabela de junção que vincula os itens de navegação às permissões necessárias para visualizá-los.

| Coluna          | Tipo   | Descrição                                       |
| --------------- | ------ | ----------------------------------------------- |
| `nav_item_id`   | `uuid` | Chave estrangeira referenciando `navigation_items.id`. |
| `permission_id` | `uuid` | Chave estrangeira referenciando `permissions.id`.      |

**Lógica de Acesso:**

-   Se um `nav_item_id` não existe nesta tabela, ele é considerado **público** e visível para todos os usuários autenticados.
-   Se um `nav_item_id` existe aqui, ele só será visível se o usuário possuir **pelo menos uma** das permissões associadas.

### 2.2. Função de Verificação de Acesso

A lógica para determinar se um usuário pode ou não ver um item de menu é centralizada na seguinte função.

#### Função: `custom_auth_helpers.can_view_navigation_item(item_id uuid)`

Esta função recebe o `id` de um item de navegação e retorna `true` ou `false`.

**Regras de Negócio Implementadas:**

1.  **Item Público:** A função primeiro verifica se o `item_id` possui alguma entrada na tabela `nav_item_permissions`. Se não houver nenhuma, o item é público e a função retorna `true`.
2.  **Item Restrito:** Se existem permissões associadas, a função verifica se o usuário atual possui pelo menos uma delas. Isso é feito através de uma chamada à função auxiliar `custom_auth_helpers.has_permission(p.name)`, que deve retornar as permissões do usuário logado. Se o usuário tiver a permissão, a função retorna `true`; caso contrário, `false`.

```sql
CREATE OR REPLACE FUNCTION custom_auth_helpers.can_view_navigation_item(item_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Um item é visível se for público (não tem permissões) OU se o usuário tiver pelo menos uma das permissões necessárias.
  RETURN
    (
      -- Condição 1: O item é público
      NOT EXISTS (SELECT 1 FROM public.nav_item_permissions WHERE nav_item_id = item_id)
    )
    OR
    (
      -- Condição 2: O usuário tem pelo menos uma das permissões necessárias
      EXISTS (
        SELECT 1
        FROM public.nav_item_permissions nip
        JOIN public.permissions p ON nip.permission_id = p.id
        WHERE nip.nav_item_id = item_id AND custom_auth_helpers.has_permission(p.name)
      )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 2.3. Política de Segurança em Nível de Linha (RLS)

A aplicação da lógica de segurança é feita através de uma política de RLS na tabela `navigation_items`.

-   **Política:** `Allow authenticated users to see their permitted menu items`
-   **Tabela Alvo:** `public.navigation_items`
-   **Aplicada a:** Usuários com o role `authenticated`.
-   **Condição (USING):** `custom_auth_helpers.can_view_navigation_item(id)`

Essa política garante que qualquer `SELECT` executado na tabela `navigation_items` por um usuário autenticado seja automaticamente filtrado. Para cada linha da tabela, o PostgreSQL invocará a função `can_view_navigation_item` passando o `id` da linha. Somente as linhas para as quais a função retornar `true` serão incluídas no resultado da consulta.

## 3. Fluxo de Dados

1.  Um usuário faz login no sistema.
2.  A aplicação (frontend ou backend) executa uma consulta na tabela `public.navigation_items` para buscar o menu. Ex: `SELECT * FROM public.navigation_items WHERE is_active = true ORDER BY display_order;`.
3.  O PostgreSQL intercepta a consulta e a política de RLS é ativada.
4.  Para cada linha da tabela `navigation_items`, a política executa a função `can_view_navigation_item(id)`.
5.  A função, por sua vez, verifica as permissões do usuário atual (contexto da sessão) contra as permissões necessárias para o item.
6.  O PostgreSQL retorna para a aplicação apenas o subconjunto de itens de menu que o usuário tem permissão para ver.
7.  A aplicação renderiza a estrutura do menu (incluindo submenus) com base nos dados filtrados recebidos.

## 4. Benefícios da Abordagem

-   **Segurança Centralizada:** A lógica de permissão reside no banco de dados, evitando que seja contornada e garantindo consistência em toda a aplicação.
-   **Manutenibilidade:** Para alterar uma regra de acesso, basta modificar a função ou as permissões nas tabelas, sem necessidade de alterar o código da aplicação.
-   **Simplicidade no Frontend:** A aplicação cliente não precisa conter lógica de permissões; ela simplesmente consulta e renderiza os dados que recebe.

## 5. Implementação no Front-End

Após o back-end (neste caso, o próprio PostgreSQL via RLS) filtrar e retornar a lista de itens de menu permitidos, o front-end precisa processar esses dados para construir a interface de navegação hierárquica e agrupada.

### 5.1. Consulta e Recebimento dos Dados

A aplicação front-end recebe uma lista "plana" (flat list) de objetos, onde cada objeto representa um item de menu autorizado para o usuário.

### 5.2. Lógica de Hierarquização em JavaScript

Para transformar a lista plana em uma estrutura de árvore agrupada que possa ser facilmente renderizada, uma função em JavaScript é utilizada. O objetivo é primeiro agrupar os itens pelo campo `group` e, em seguida, construir a hierarquia de pais e filhos dentro de cada grupo.

```javascript
/*
  Assume que 'items' é o array de objetos que vem da sua coleção do Supabase.
  Cada objeto deve ter: id, parent_id, group, label, path, icon, etc.
*/
function buildNavigationTree(items) {
    const flatList = items;

    // Se a lista estiver vazia, retorna um array vazio.
    if (!flatList || flatList.length === 0) {
        return [];
    }

    // 1. Primeiro, agrupa todos os itens pela coluna 'group'.
    const groups = {};
    for (const item of flatList) {
        // Se o item não tiver um grupo, pode-se usar um grupo padrão 'default'
        const groupName = item.group || 'default';

        if (!groups[groupName]) {
            groups[groupName] = [];
        }
        groups[groupName].push(item);
    }

    // 2. Agora, para cada grupo, constrói a árvore de filhos (cascata).
    const result = [];
    for (const groupName in groups) {
        const groupItems = groups[groupName];
        const map = {};

        // Cria um mapa para acesso rápido a cada item do grupo.
        for (const item of groupItems) {
            map[item.id] = { ...item, children: [] };
        }

        // Constrói a árvore dentro do grupo.
        const roots = [];
        for (const item of groupItems) {
            // Se o item tem um pai DENTRO DO MESMO GRUPO...
            if (item.parent_id && map[item.parent_id]) {
                map[item.parent_id].children.push(map[item.id]);
            } else {
                // Se não tem pai (ou o pai não está no grupo), é um item raiz do grupo.
                roots.push(map[item.id]);
            }
        }

        // Função interna para ordenar os filhos recursivamente pela `display_order`
        function sortChildren(node) {
            if (node.children && node.children.length > 0) {
                node.children.sort((a, b) => a.display_order - b.display_order);
                node.children.forEach(sortChildren);
            }
        }

        // Ordena os itens raiz do grupo
        roots.sort((a, b) => a.display_order - b.display_order);
        // Ordena os filhos de cada item raiz
        roots.forEach(sortChildren);

        result.push({
            group: groupName,
            items: roots
        });
    }

    // Opcional: Ordena os próprios grupos, se necessário.
    result.sort((a, b) => a.group.localeCompare(b.group));

    return result;
}
```

### 5.3. Renderização no Componente de UI

O array `result` gerado pela função acima é então utilizado por um componente de UI (como React, Vue, etc.) para renderizar o menu lateral. A estrutura de dados resultante, com grupos e itens aninhados, permite iterar e exibir facilmente a navegação.
