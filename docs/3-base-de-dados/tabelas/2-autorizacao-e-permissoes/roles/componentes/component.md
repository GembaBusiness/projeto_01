# Documentação do Componente: Role Permissions Editor

**Componente**: `role-permissions-editor`
**Rótulo (PT)**: Editor de Permissões de Papel
**Ícone**: `key`

---

## 1. Visão Geral

O **Role Permissions Editor** é um componente customizado para WeWeb projetado para fornecer uma interface de usuário completa para gerenciar permissões.

Ele exibe uma lista de todas as permissões disponíveis (`allPermissions`), marca visualmente quais permissões estão ativas para uma determinada regra (`activePermissions`) e permite que o usuário altere essas permissões.

O componente é otimizado para cenários de "salvamento em lote" (batch save), pois ele não modifica os dados diretamente. Em vez disso, ele emite eventos (`permission-toggled`) que podem ser capturados por um workflow do WeWeb para registrar as alterações pendentes (como salvar em uma variável `item_added` ou `item_remove`).

### Principais Funcionalidades

- **Agrupamento**: Agrupa permissões por "Recurso" (tabela) ou "Ação" (acao) para melhor organização.
- **Busca**: Filtra a lista de permissões em tempo real.
- **Seleção Total**: Permite selecionar/desmarcar todas as permissões de uma vez.
- **Modo Desabilitado**: Pode ser configurado como "read-only" (apenas leitura).
- **Customização de Estilo**: Oferece 20+ propriedades de estilo para se adaptar a qualquer design.

---

## 2. Propriedades (Properties)

Estas são as configurações disponíveis no painel de edição do WeWeb para este componente.

### 2.1. Propriedades de Dados (Settings)

Estas são as propriedades principais para vincular os dados do seu aplicativo ao componente.

| Propriedade         | Rótulo (PT)        | Tipo   | Obrigatório | Descrição                                                                                                                               |
| ------------------- | ------------------ | ------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `allPermissions`    | Todas as Permissões | Array  | Sim         | O array mestre de todas as permissões disponíveis no seu sistema. O componente usará isso para renderizar a lista de checkboxes.         |
| `activePermissions` | Permissões Ativas  | Array  | Sim         | Um array contendo apenas as permissões que a regra (role) selecionada atualmente possui. O componente usa isso para marcar os checkboxes como "ativos". |
| `roleId`            | ID do Papel Atual  | Text   | Sim         | O ID da regra que está sendo editada. Este valor não é usado visualmente, mas é essencial, pois é incluído no payload do evento `permission-toggled` para o workflow. |

### 2.2. Propriedades de Comportamento (Settings)

Estas propriedades controlam a funcionalidade e a aparência da interface.

| Propriedade         | Rótulo (PT)             | Tipo       | Padrão  | Descrição                                                                                                                               |
| ------------------- | ----------------------- | ---------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `groupBy`           | Agrupar Por             | TextSelect | `tabela`  | Define como as permissões serão agrupadas visualmente. <br> • `tabela`: Agrupa por recurso (ex: "Gerenciamento de Usuários"). <br> • `acao`: Agrupa por tipo de ação (ex: "Read", "Write"). <br> • `none`: Renderiza uma lista simples, sem grupos. |
| `searchable`        | Habilitar Busca         | OnOff      | `true`  | Exibe uma barra de busca no topo do componente para filtrar a lista.                                                                      |
| `showDescription`   | Mostrar Descrições      | OnOff      | `true`  | Exibe o campo `description` de cada permissão abaixo do seu nome.                                                                        |
| `selectAllEnabled`  | Habilitar Selecionar Tudo | OnOff      | `true`  | Exibe um checkbox principal no cabeçalho para marcar/desmarcar todas as permissões visíveis.                                            |
| `disabled`          | Desabilitado            | OnOff      | `false` | Se `true`, desabilita todos os checkboxes, tornando o componente "read-only".                                                               |

### 2.3. Propriedades de Estilo (Style)

O componente expõe um conjunto completo de propriedades de estilo para customização total. Elas estão agrupadas no painel "Style" do WeWeb:

**Contêiner e Layout:**
- `backgroundColor`: Cor de fundo do componente.
- `borderRadius`: Raio da borda do contêiner.
- `padding`: Espaçamento interno do contêiner.
- `rowPadding`: Espaçamento vertical de cada linha de permissão.
- `dividerColor`: Cor das linhas divisórias.
- `compactMode`: (OnOff) Usa um layout mais denso com menos espaçamento.
- `checkboxPosition`: ('left' ou 'right') Posição dos checkboxes.

**Tipografia:**
- `titleColor`, `titleSize`, `titleWeight`: Estilos do título principal ("Role Permissions").
- `groupLabelColor`, `groupLabelSize`, `groupLabelWeight`: Estilos dos títulos de cada grupo (ex: "User Management").
- `permissionTextColor`, `permissionTextSize`: Estilos do nome de cada permissão (ex: "Read").
- `descriptionTextColor`, `descriptionTextSize`: Estilos do texto de descrição da permissão.

**Checkboxes:**
- `checkboxColor`: Cor da borda do checkbox inativo.
- `checkboxSize`: Tamanho (largura e altura) do checkbox.
- `checkboxActiveColor`: Cor de fundo do checkbox marcado.

---

## 3. Eventos Emitidos (Trigger Events)

O componente emite eventos para que o WeWeb possa reagir às ações do usuário através de workflows.

### 3.1. `permission-toggled` (Evento Principal)

Este é o evento mais importante. Ele é disparado sempre que um checkbox individual é clicado.

- **Quando dispara**: Ao clicar em qualquer checkbox de permissão.
- **O que faz**: Ele não altera seus dados. Ele apenas informa ao WeWeb o que aconteceu, permitindo que você implemente a lógica de "batch save" (adicionando o item a uma variável `item_added` ou `item_remove`).
- **Payload do Evento (`event`)**: O workflow recebe um objeto com a seguinte estrutura:

```json
{
  "permissionId": "3",
  "roleId": "role-123-uuid",
  "isActive": true,
  "action": "added",
  "permissionData": {
    "id": "3",
    "name": "users.create",
    "description": "Create users",
    "tabela": "User Management",
    "acao": "Create"
  }
}
```

- `permissionId`: (String) O ID da permissão que foi clicada.
- `roleId`: (String) O ID da regra que está sendo editada (vindo da propriedade `roleId`).
- `isActive`: (Boolean) O novo estado do checkbox (se `true`, ele foi marcado; se `false`, foi desmarcado).
- `action`: (String) A intenção do usuário. `added` se o checkbox foi marcado, `removed` se foi desmarcarcado.
- `permissionData`: (Object) O objeto completo da permissão que foi clicada (útil para não ter que procurá-lo novamente).

### 3.2. `select-all-toggled`

Disparado apenas quando o checkbox "Select All" principal no cabeçalho é clicado.

- **Payload do Evento (`event`)**:
```json
{
  "groupName": "All Permissions",
  "action": "select-all",
  "permissionIds": ["1", "2", "3", ...],
  "permissions": [ { "id": "1", ... }, { "id": "2", ... } ]
}
```

- `groupName`: (String) Sempre "All Permissions" (indica que foi o "Select All" global).
- `action`: (String) `select-all` ou `deselect-all`.
- `permissionIds`: (Array) Um array com os IDs de todas as permissões que foram afetadas (baseado no filtro de busca atual).
- `permissions`: (Array) Um array com os objetos completos de todas as permissões afetadas.

---

## 4. Estrutura de Dados (Exemplos)

Para que o componente funcione, os dados vinculados às propriedades `allPermissions` e `activePermissions` devem seguir uma estrutura específica.

### Exemplo para `allPermissions` (Obrigatório)

Este é o array com todas as permissões do sistema. O campo `tabela` é usado para agrupamento por recurso, e `acao` para agrupamento por ação.

```json
[
  {
    "id": "1",
    "name": "users.read",
    "description": "Visualizar usuários",
    "tabela": "Gerenciamento de Usuários",
    "acao": "Ler"
  },
  {
    "id": "2",
    "name": "users.write",
    "description": "Editar usuários",
    "tabela": "Gerenciamento de Usuários",
    "acao": "Escrever"
  },
  {
    "id": "3",
    "name": "content.read",
    "description": "Visualizar conteúdo",
    "tabela": "Gerenciamento de Conteúdo",
    "acao": "Ler"
  }
]
```

### Exemplo para `activePermissions` (Obrigatório)

Este é o array que representa a relação entre a regra (role) e suas permissões. Note que a estrutura é diferente de `allPermissions`.

```json
[
  {
    "role_id": "role-123-uuid",
    "permission_id": "1"
  },
  {
    "role_id": "role-123-uuid",
    "permission_id": "3"
  }
]
```

Neste exemplo, os checkboxes "users.read" (id: 1) e "content.read" (id: 3) apareceriam marcados.
