# Glossário

Este documento define os termos e conceitos chave específicos do nosso projeto para garantir que toda a equipa partilha um vocabulário comum.

---

### A

- **ADR (Architecture Decision Record)**
  - Um documento que captura uma decisão arquitetural importante, o seu contexto e as suas consequências. Ver a secção de [Decisões Chave](./1-arquitetura/1.3-decisoes-chave.md).

- **API Key**
  - As chaves (anónima e de serviço) fornecidas pelo Supabase para permitir o acesso à API. A chave anónima (`anon key`) é pública e segura para ser usada no frontend, pois as permissões são controladas pela RLS.

### C

- **Company (Empresa)**
  - A entidade principal do nosso sistema, que representa uma organização ou um cliente. Funciona como o nosso "tenant" principal.

### J

- **JWT (JSON Web Token)**
  - O standard que usamos para os tokens de acesso. São emitidos pelo serviço de autenticação do Supabase após um login bem-sucedido.

### M

- **Membership (Vínculo)**
  - A relação entre um `Profile` (utilizador) e uma `Company` (empresa). A tabela `memberships` define a que empresas um utilizador pertence e qual o seu papel (`role`) em cada uma.

- **Multi-tenancy**
  - A arquitetura onde uma única instância da aplicação serve múltiplos clientes (tenants). No nosso caso, cada `Company` é um tenant. A separação dos dados é garantida pela Row Level Security (RLS).

### P

- **Profile (Perfil)**
  - A representação de um utilizador na nossa aplicação. Contém dados públicos como nome e avatar. Está ligada à tabela `auth.users` do Supabase.

### R

- **RLS (Row Level Security)**
  - Uma funcionalidade do PostgreSQL que usamos extensivamente para controlar o acesso aos dados. As políticas de RLS garantem que um utilizador só pode aceder e modificar as linhas (rows) nas tabelas a que tem permissão (e.g., só pode ver os dados da sua própria empresa).

- **RPC (Remote Procedure Call)**
  - Um método para invocar funções da base de dados diretamente através da API do Supabase. Usamos isto para encapsular lógica de negócio complexa, como a criação de uma empresa e do seu primeiro membro numa única transação.

### S

- **Supabase**
  - A plataforma open-source que usamos como nosso Backend-as-a-Service (BaaS). Fornece-nos uma base de dados PostgreSQL, autenticação, APIs, storage e muito mais.

- **Staging**
  - O nosso ambiente de pré-produção, usado para testar as alterações antes de serem lançadas ao público.

### T

- **Tenant**
  - Um cliente ou um grupo de utilizadores que partilham um acesso comum a uma instância da aplicação. No nosso sistema, o tenant é a `Company`.
