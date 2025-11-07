# Acesso à API: Tabela `roles`

Este documento detalha como a API do Supabase expõe os dados da tabela `roles` e como configurá-la no WeWeb para criar coleções de dados dinâmicas e relacionais.

## Contexto: WeWeb e Supabase

A interface do sistema é desenvolvida em WeWeb, utilizando o plugin do Supabase para uma integração simplificada com o backend. Este plugin permite a criação de "Collections" no WeWeb, que são fontes de dados conectadas diretamente às tabelas e views do Supabase.

## Configuração da Collection no WeWeb

Para buscar os dados da tabela `roles`, incluindo as permissões associadas, seguimos os passos abaixo na configuração de uma collection no WeWeb.

### 1. Seleção da Fonte (Source)

A configuração inicial define de onde os dados serão extraídos.

- **Name**: `regras` (ou um nome descritivo para a collection).
- **Source**: `Supabase`.
- **Mode**: `Dynamic`.

A escolha do modo **Dynamic** é fundamental, pois garante que os dados sejam buscados diretamente do Supabase sempre que a página for carregada. Isso assegura que a aplicação exiba informações atualizadas sem a necessidade de republicar o projeto a cada alteração no banco de dados.

![Configuração da Fonte no WeWeb](https://i.imgur.com/wP9aL3g.png)

### 2. Configuração Avançada de Campos

Após selecionar a fonte, o próximo passo é definir a tabela e os campos desejados.

- **Table**: `roles`.
- **Fields**: Modo `Advanced`.

O modo **Advanced** é utilizado para especificar manualmente os campos e, mais importante, para realizar junções (joins) com tabelas relacionadas. Esta abordagem oferece flexibilidade total para moldar a resposta da API conforme a necessidade da interface.

A query de seleção de campos é a seguinte:

```
id,
name,
description,
company_id,
deleted_at,
role_permissions(role_id, permission_id)
```

**Análise da Query:**

1.  **Campos da Tabela `roles`**:
    -   `id`, `name`, `description`, `company_id`, `deleted_at`: São os campos diretos da tabela `roles` que desejamos obter.

2.  **Junção com a Tabela `role_permissions`**:
    -   `role_permissions(role_id, permission_id)`: Esta é a sintaxe do Supabase PostgREST para buscar dados de uma tabela relacionada.
    -   `role_permissions`: É o nome da tabela que tem uma relação de chave estrangeira com a tabela `roles`.
    -   `(role_id, permission_id)`: Especifica quais campos da tabela `role_permissions` devem ser incluídos na resposta para cada `role` correspondente.

![Configuração de Campos Avançados no WeWeb](https://i.imgur.com/t8bWcK7.png)

## Estrutura do Retorno da API

A configuração acima resulta em uma chamada à API do Supabase que retorna um array de objetos. Cada objeto representa um registro da tabela `roles` e contém um array aninhado com os dados da tabela `role_permissions`.

**Exemplo de Resposta (JSON):**

```json
[
  {
    "id": "8d3b11cf-36bd-4881-8836-f7730dbfba5e",
    "name": "User padrão",
    "description": null,
    "company_id": "21e3d0cc-08eb-499a-88e9-e749a9211dfa",
    "deleted_at": null,
    "role_permissions": [
      {
        "role_id": "8d3b11cf-36bd-4881-8836-f7730dbfba5e",
        "permission_id": "3369e413-f894-45b7-9fbb-13e8e230c473"
      },
      {
        "role_id": "8d3b11cf-36bd-4881-8836-f7730dbfba5e",
        "permission_id": "b939afef-4be0-4b4a-b909-6913556a980f"
      }
    ]
  }
]
```

Esta estrutura é extremamente útil no frontend, pois permite acessar facilmente tanto os detalhes do "papel" (role) quanto a lista de permissões associadas a ele, tudo em uma única requisição de dados.
