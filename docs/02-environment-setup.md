# 2. Configuração do Ambiente de Desenvolvimento

Este guia descreve os passos necessários para configurar o ambiente de desenvolvimento local para trabalhar com este template.

## 2.1. Pré-requisitos

-   Conta no [Supabase](https://supabase.com/)
-   Conta no [WeWeb](https://weweb.io/)

## 2.2. Configuração do Supabase

1.  **Criar um novo projeto:**
    -   Aceda ao seu dashboard do Supabase e crie um novo projeto.
    -   Guarde a sua senha do banco de dados num local seguro.

2.  **Obter as Chaves de API:**
    -   No dashboard do seu projeto, vá para `Settings` -> `API`.
    -   Você precisará de duas informações:
        -   **Project URL** (URL do Projeto)
        -   **API Key (anon key)** (Chave de API anônima)

3.  **Executar Scripts de Migração (se aplicável):**
    -   Navegue até o `SQL Editor` no dashboard do Supabase.
    -   Execute os scripts SQL localizados em `supabase/migrations` para criar as tabelas, papéis e políticas de RLS. (Nota: Este diretório será criado no futuro).

## 2.3. Configuração do WeWeb

1.  **Criar um novo projeto:**
    -   Aceda ao seu dashboard do WeWeb e crie um novo projeto a partir de um template em branco.

2.  **Instalar o Plugin do Supabase:**
    -   No editor do WeWeb, vá para a secção `Plugins`.
    -   Adicione o plugin oficial do `Supabase`.

3.  **Conectar ao Supabase:**
    -   Nas configurações do plugin do Supabase, insira a **Project URL** e a **API Key (anon key)** que você obteve no passo 2.2.

4.  **Configurar Variáveis de Ambiente Globais:**
    -   É uma boa prática armazenar URLs e chaves em variáveis globais no WeWeb.
    -   Vá para a secção `Data` -> `Global Variables`.
    -   Crie variáveis para a URL e a chave do Supabase para reutilização em todo o projeto.

5.  **Testar a Conexão:**
    -   Tente criar uma `Collection` a partir de uma tabela do Supabase (ex: `profiles`). Se as tabelas aparecerem, a conexão foi bem-sucedida.
