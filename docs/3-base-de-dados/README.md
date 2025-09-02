# 3. Base de Dados

Esta seção contém toda a documentação relacionada com a nossa base de dados.

## Tecnologia

Utilizamos **PostgreSQL** como o nosso sistema de gestão de base de dados, alojado e gerido através do **Supabase**.

## Conteúdo

- **[Diagrama Entidade-Relacionamento (ERD)](./schema-diagram.png)**: Uma representação visual do esquema da nossa base de dados, mostrando as tabelas e as suas relações.

- **[Tabelas](./tabelas/)**: Documentação detalhada para cada tabela principal, incluindo a descrição de cada coluna, os seus tipos de dados e as `constraints`.
  - [`companies`](./tabelas/companies.md)
  - [`profiles`](./tabelas/profiles.md)

- **[Funções e Row Level Security (RLS)](./funcoes-e-rls/)**: Documentação para funções SQL customizadas, `triggers`, e as políticas de RLS que garantem a segurança e o isolamento dos dados dos tenants.
  - [`create_company_and_profile`](./funcoes-e-rls/create_company_and_profile.md)

## Migrações

As alterações ao esquema da base de dados são geridas através do sistema de migrações do Supabase. Os ficheiros de migração estão localizados no diretório `supabase/migrations` do repositório principal. É crucial manter estes ficheiros atualizados e nunca modificar a base de dados de produção diretamente.
