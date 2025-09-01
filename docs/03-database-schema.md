Módulo de Fundação: Modelagem da Base de Dados
Versão: 1.1 Data: 31 de Agosto de 2025
1. Objetivo Geral da Seção
Esta seção detalha o esquema completo da base de dados no Supabase (PostgreSQL). O objetivo é estabelecer a fundação sobre a qual toda a lógica de negócio, segurança e funcionalidades serão construídas, garantindo integridade, escalabilidade e alinhamento com os requisitos de um sistema SaaS B-to-B multi-tenant.
2. Modelo de Dados
2.1. Domínio: Identidade e Multi-Tenancy
Este é o núcleo do sistema, responsável por gerir as empresas (tenants), os utilizadores e a relação entre eles.
2.1.1. Tabela companies
Finalidade e Justificativa: Esta é a entidade central da arquitetura multi-tenant. Cada registo representa uma empresa cliente (um "tenant"), servindo como a âncora para o isolamento de dados. A coluna status é fundamental para gerir o ciclo de vida do cliente (ex: suspender o acesso por falta de pagamento). Para a criação de empresas, a idempotência será garantida inicialmente pela restrição UNIQUE na coluna cnpj. A coluna idempotency_key é mantida no esquema como uma salvaguarda para futuros processos de criação mais complexos que possam envolver múltiplas operações.
DDL (SQL):
CREATE TYPE public.company_status AS ENUM ('pending_confirmation', 'active', 'suspended', 'deactivated');

CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  cnpj TEXT UNIQUE,
  logo_url TEXT,
  status public.company_status NOT NULL DEFAULT 'active',
  idempotency_key UUID UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.companies IS 'Armazena as informações de cada empresa cliente (tenant) no sistema.';

Campos e Restrições:
id (UUID, PK): Chave primária. Usar UUID evita a enumeração de clientes e conflitos em ambientes distribuídos.
name (TEXT, NOT NULL): Nome da empresa. É obrigatório para identificação.
cnpj (TEXT, UNIQUE): Documento de identificação fiscal. É UNIQUE para garantir que uma mesma empresa não seja registada múltiplas vezes.
logo_url (TEXT): URL para o logótipo da empresa.
status (ENUM, NOT NULL): Controla o estado da conta, essencial para a lógica de negócio (ex: acesso, faturação).
idempotency_key (UUID, UNIQUE): Chave de idempotência para a criação da empresa, preenchida no momento do registo para evitar duplicados.
created_at, updated_at, deleted_at: Timestamps para controlo de ciclo de vida e soft delete.
2.1.2. Tabela profiles
Finalidade e Justificativa: Esta tabela estende a tabela auth.users do Supabase. A separação é uma best practice que desacopla os dados de autenticação (geridos pelo Supabase) dos dados de perfil público da aplicação. A relação 1-para-1 com auth.users é garantida pela PK ser também uma FK. O ON DELETE CASCADE assegura que, se um utilizador for apagado do sistema de autenticação, o seu perfil seja automaticamente removido, mantendo a consistência dos dados.
DDL (SQL):
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  job_title TEXT,
  phone_number TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

COMMENT ON TABLE public.profiles IS 'Armazena os dados públicos do perfil do utilizador, estendendo a tabela auth.users.';

Campos e Restrições:
id (UUID, PK, FK): Chave primária que referencia auth.users.id, criando a relação 1-para-1 e garantindo a integridade referencial.
full_name, avatar_url, etc.: Campos de perfil que podem ser geridos pela aplicação.
2.1.3. Tabela memberships
Finalidade e Justificativa: Esta é uma das tabelas mais importantes do sistema. Modela a relação entre users e companies. É a "fonte da verdade" para determinar a que empresas e, opcionalmente, a que departamento um utilizador pertence. A restrição UNIQUE(user_id, company_id) garante que um utilizador só pode ser membro de uma empresa uma única vez.
DDL (SQL):
CREATE TYPE public.membership_status AS ENUM ('active', 'pending_invite');

CREATE TABLE public.memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  department_id UUID REFERENCES public.departments(id) ON DELETE SET NULL,
  has_company_wide_access BOOLEAN NOT NULL DEFAULT false,
  status public.membership_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(user_id, company_id)
);

COMMENT ON TABLE public.memberships IS 'Tabela de associação entre utilizadores e empresas, indicando também o departamento do membro.';

-- Índices para otimizar buscas por usuário, empresa ou departamento.
CREATE INDEX idx_memberships_user_id ON public.memberships(user_id);
CREATE INDEX idx_memberships_company_id ON public.memberships(company_id);
CREATE INDEX idx_memberships_department_id ON public.memberships(department_id);

Campos e Restrições:
id (UUID, PK): Chave primária do vínculo.
user_id (UUID, NOT NULL, FK): Referencia o utilizador.
company_id (UUID, NOT NULL, FK): Referencia a empresa.
department_id (UUID, FK): Referencia o departamento do membro. É NULLABLE para permitir membros sem departamento definido. ON DELETE SET NULL garante que se um departamento for apagado, o membro não é removido da empresa.
has_company_wide_access (BOOLEAN, NOT NULL): Um atributo que, se true, concede ao membro acesso a todos os departamentos da empresa, ignorando as regras de acesso baseadas no department_id.
status (ENUM, NOT NULL): Permite a implementação de um sistema de convites.
UNIQUE(user_id, company_id): Garante a integridade da relação.
2.1.4. Tabela departments
Finalidade e Justificativa: Armazena os departamentos específicos de cada empresa. A tabela está diretamente ligada a companies, garantindo que cada departamento pertença a um único tenant. A restrição UNIQUE(name, company_id) é crucial para evitar nomes de departamento duplicados dentro da mesma empresa, mantendo a organização dos dados. Um índice foi adicionado em company_id para otimizar consultas que filtram departamentos por empresa.
DDL (SQL):
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE(name, company_id)
);

COMMENT ON TABLE public.departments IS 'Armazena os departamentos de cada empresa.';

-- Índice para otimizar a busca de departamentos de uma empresa.
CREATE INDEX idx_departments_company_id ON public.departments(company_id);

Campos e Restrições:
id (UUID, PK): Chave primária do departamento.
name (TEXT, NOT NULL): Nome do departamento (ex: "Financeiro", "Recursos Humanos").
company_id (UUID, NOT NULL, FK): Referencia a empresa à qual o departamento pertence.
created_at, updated_at, deleted_at: Timestamps para controlo de ciclo de vida e soft delete.
UNIQUE(name, company_id): Garante que o nome do departamento seja único dentro de uma empresa.
2.2. Domínio: Autorização e Permissões (Abordagem Híbrida ABAC + RBAC)
Este domínio define o que um utilizador pode fazer dentro de uma empresa, utilizando uma abordagem híbrida que combina o melhor do ABAC (Attribute-Based Access Control) e do RBAC (Role-Based Access Control) para criar um sistema de autorização seguro, flexível e escalável.
A Camada de Contexto: ABAC (Attribute-Based Access Control)
O ABAC concede acesso com base em atributos (características). A permissão é decidida dinamicamente com base no contexto: quem é o usuário, o que ele está tentando acessar e em que condições?
No nosso projeto, o ABAC é a fundação da segurança e do multi-tenancy:
Exemplo Real (Multi-Tenancy): A regra mais fundamental do sistema é um exemplo clássico de ABAC: "um usuário só pode acessar os dados que pertencem à sua company_id". Aqui, a company_id é o atributo que governa o acesso, garantindo o isolamento total dos dados entre os tenants.
Exemplo Real (Departamentos): Expandindo a ideia, um usuário do departamento 'Financeiro' (atributo do usuário) só poderia visualizar relatórios marcados como 'Financeiro' (atributo do recurso). No entanto, se esse mesmo usuário possuir um atributo específico, como uma flag has_company_wide_access (atributo do usuário na tabela "memberships"), ele teria acesso a todos os departamentos, funcionando como um acesso privilegiado dentro da própria empresa, mesmo que seu papel seja o mesmo.
A Estrutura de Cargos: RBAC (Role-Based Access Control)
O RBAC concede acesso com base em "cargos" (Roles) atribuídos aos usuários. Ele define de forma estática o que um usuário pode fazer dentro do sistema (as ações que ele pode executar).
No nosso modelo, a estrutura do RBAC é definida pela seguinte cadeia de relacionamentos:
Um usuário pertence a uma empresa, criando um vínculo (memberships).
A esse vínculo (membership_id) é atribuído um ou mais papéis (membership_roles).
Cada papel (role_id) é um agrupamento de permissões (role_permissions).
Cada permissão (permission_id) é uma ação granular no sistema (ex: projects.create).
Dessa forma, um usuário será vinculado a uma permissão através dessa conexão e terá acesso somente aos itens e ações para os quais seu papel concede permissão explicitamente.
Implementação e Por Que Usar uma Abordagem Híbrida
Toda essa lógica de autorização é garantida em múltiplos níveis para criar uma defesa em profundidade:
No Banco de Dados (Segurança Máxima): As regras, principalmente as de ABAC (como o isolamento por company_id), serão implementadas diretamente no PostgreSQL utilizando RLS (Row-Level Security). Isso garante que, mesmo que ocorra uma falha na aplicação, um usuário jamais conseguirá acessar dados de outra empresa.
No Front-End (Experiência do Usuário): Adotamos uma abordagem híbrida para o controle de acesso. Enquanto o RLS atua como a camada final de segurança no banco de dados, o RBAC será utilizado no front-end para controlar a interface. Tabelas de apoio (como navigation_items e nav_item_permissions) definirão quais itens de menu, páginas e botões um usuário pode ver com base nos seus papéis, criando uma experiência de usuário limpa e relevante, sempre respaldada pela segurança do RLS.
Motivos da Escolha:
O Melhor dos Dois Mundos: Ganhamos a simplicidade e previsibilidade do RBAC para as permissões do dia a dia e a flexibilidade contextual e poderosa do ABAC para regras de negócio dinâmicas.
Segurança em Profundidade: A combinação de RLS (ABAC) no banco e controle de UI (RBAC) no front-end cria uma defesa robusta em camadas.
Escalabilidade e Manutenibilidade: É fácil adicionar novas regras baseadas em atributos (ex: um novo plano de assinatura que libera features) sem precisar criar uma infinidade de novos papéis, mantendo o sistema organizado e fácil de evoluir.
2.2.1. Tabela roles
Finalidade e Justificativa: Define um conjunto de permissões agrupadas (cargos). A company_id ser NULLABLE é uma decisão estratégica: se for NULL, é um "papel de sistema" (ex: Administrador, Membro) disponível para todas as empresas. Se tiver um valor, é um "papel customizado" criado por aquela empresa específica. A restrição UNIQUE(name, company_id) garante que os nomes dos papéis sejam únicos dentro do seu contexto (seja global ou por empresa).
DDL (SQL):
CREATE TABLE public.roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
  deleted_at TIMESTAMPTZ,
  UNIQUE(name, company_id)
);

-- Índice para otimizar a busca de papéis customizados de uma empresa.
CREATE INDEX idx_roles_company_id ON public.roles(company_id);

Campos e Restrições:
id (UUID, PK): Chave primária do papel.
name (TEXT, NOT NULL): Nome do papel (ex: "Administrador"). É obrigatório.
description (TEXT): Descrição amigável da função do papel.
company_id (UUID, FK): Permite a distinção entre papéis de sistema (NULL) e papéis customizados (preenchido). Garante que um papel customizado seja apagado se a empresa for removida.
deleted_at (TIMESTAMPTZ): Suporte a soft delete para papéis.
UNIQUE(name, company_id): Restrição crucial que impede a criação de papéis com o mesmo nome dentro da mesma empresa, ou globalmente se company_id for NULL.
2.2.2. Tabela permissions
Finalidade e Justificativa: É o catálogo de todas as ações granulares possíveis no sistema. Funciona como um enum na base de dados. Manter esta tabela permite que as permissões sejam geridas dinamicamente sem necessidade de alterações no código. A nomenclatura recurso.acao (ex: projects.create) é uma convenção para fácil entendimento.
DDL (SQL):
CREATE TABLE public.permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT
);

Campos e Restrições:
name (TEXT, UNIQUE): A chave da permissão.
2.2.3. Tabela role_permissions
Finalidade e Justificativa: Esta tabela é o coração do modelo RBAC, servindo como a matriz que conecta as ações granulares (permissions) aos papéis (roles). Ao definir explicitamente quais permissões um papel como "Administrador" possui, esta tabela permite que as capacidades de um papel sejam geridas dinamicamente através de dados, garantindo flexibilidade e desacoplando as regras de autorização do código da aplicação.
DDL (SQL):
CREATE TABLE public.role_permissions (
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- Índice para otimizar a busca de papéis por permissão.
CREATE INDEX idx_role_permissions_permission_id ON public.role_permissions(permission_id);

Campos e Restrições:
PRIMARY KEY (role_id, permission_id): Chave primária composta que também garante a unicidade da relação.
2.2.4. Tabela membership_roles
Finalidade e Justificativa: Esta é a tabela que efetivamente concede as permissões. Ela atribui um role a um membership, ou seja, a um utilizador DENTRO de uma empresa específica. Esta é a implementação do racional "as permissões pertencem à relação e não ao utilizador".
DDL (SQL):
CREATE TABLE public.membership_roles (
  membership_id UUID NOT NULL REFERENCES public.memberships(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  PRIMARY KEY (membership_id, role_id)
);

-- Índice para otimizar a busca de membros por papel.
CREATE INDEX idx_membership_roles_role_id ON public.membership_roles(role_id);

2.3. Domínio: Planos e Monetização
Este domínio controla o acesso a funcionalidades com base no plano comercial subscrito.
2.3.1. Tabela features
Finalidade e Justificativa: Catálogo de todas as funcionalidades que podem ser ligadas/desligadas por um plano (feature flags). O key é a chave programática que o código usará para verificar se uma funcionalidade está ativa para o tenant atual.
DDL (SQL):
CREATE TABLE public.features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);

2.3.2. Tabela plans
Finalidade e Justificativa: Define os pacotes comerciais (ex: Básico, Pro).
DDL (SQL):
CREATE TABLE public.plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true
);

2.3.3. Tabela prices
Finalidade e Justificativa: Desacopla os planos dos seus preços. Um mesmo plan "Pro" pode ter um preço mensal e um anual. A coluna provider_price_id é essencial para a integração com gateways de pagamento como o Stripe, armazenando o ID do preço correspondente nesse serviço.
DDL (SQL):
CREATE TYPE public.billing_interval AS ENUM ('month', 'year');

CREATE TABLE public.prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'BRL',
  interval public.billing_interval NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  provider_price_id TEXT
);

-- Índice para otimizar a busca de preços de um plano.
CREATE INDEX idx_prices_plan_id ON public.prices(plan_id);

2.3.4. Tabela subscriptions
Finalidade e Justificativa: Regista o estado da subscrição de uma empresa. A restrição UNIQUE em company_id é a regra de negócio que garante que uma empresa só pode ter uma subscrição ativa de cada vez.
DDL (SQL):
CREATE TYPE public.subscription_status AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'incomplete');

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL UNIQUE REFERENCES public.companies(id) ON DELETE CASCADE,
  price_id UUID NOT NULL REFERENCES public.prices(id),
  status public.subscription_status NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índice para otimizar a busca de assinaturas por preço.
CREATE INDEX idx_subscriptions_price_id ON public.subscriptions(price_id);

2.3.5. Tabela subscription_history
Finalidade e Justificativa: Esta tabela funciona como um log de auditoria para cada assinatura, registando todos os eventos importantes do seu ciclo de vida. Ela é crucial para entender o histórico de um cliente, depurar problemas de faturação e analisar padrões de upgrade, downgrade ou cancelamento.
DDL (SQL):
CREATE TYPE public.subscription_event_type AS ENUM ('created', 'upgraded', 'downgraded', 'renewed', 'canceled');

CREATE TABLE public.subscription_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscriptions(id) ON DELETE CASCADE,
  event_type public.subscription_event_type NOT NULL,
  from_price_id UUID REFERENCES public.prices(id),
  to_price_id UUID REFERENCES public.prices(id),
  event_date TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.subscription_history IS 'Armazena o histórico de eventos de uma assinatura.';

-- Índice para otimizar a busca do histórico de uma assinatura específica.
CREATE INDEX IF NOT EXISTS idx_subscription_history_subscription_id ON public.subscription_history(subscription_id);

Campos e Restrições:
id (UUID, PK): Chave primária do registo de histórico.
subscription_id (UUID, NOT NULL, FK): Referencia a assinatura à qual este evento pertence.
event_type (ENUM, NOT NULL): O tipo de evento que ocorreu (ex: upgraded, canceled).
from_price_id (UUID, FK): O preço anterior da assinatura (relevante para upgraded, downgraded).
to_price_id (UUID, FK): O novo preço da assinatura (relevante para created, upgraded, downgraded).
event_date (TIMESTAMPTZ, NOT NULL): A data e hora em que o evento ocorreu.
2.3.6. Tabela plan_features
Finalidade e Justificativa: Tabela de junção N-para-N que define quais features estão incluídas em cada plan.
DDL (SQL):
CREATE TABLE public.plan_features (
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  feature_id UUID NOT NULL REFERENCES public.features(id) ON DELETE CASCADE,
  PRIMARY KEY (plan_id, feature_id)
);

-- Índice para otimizar a busca de planos por feature.
CREATE INDEX idx_plan_features_feature_id ON public.plan_features(feature_id);

3. Domínio: Interface e Navegação
Este domínio define a estrutura e o controle de acesso aos elementos visuais da interface, como menus de navegação. Ele materializa a camada de "Experiência do Usuário" mencionada na nossa abordagem de autorização, permitindo que a UI se adapte dinamicamente às permissões do usuário.
3.1. Tabela navigation_items
Finalidade e Justificativa: Esta tabela armazena a estrutura hierárquica de todos os itens de navegação da aplicação (ex: menus laterais, menus de cabeçalho). Ao guardar a navegação no banco de dados, permitimos que ela seja gerida dinamicamente sem a necessidade de fazer deploy de novas versões do front-end. O suporte a hierarquia (parent_id) permite a criação de submenus.
DDL (SQL):
CREATE TABLE public.navigation_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  label TEXT NOT NULL,
  path TEXT,
  icon TEXT,
  parent_id UUID REFERENCES public.navigation_items(id),
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE public.navigation_items IS 'Armazena a estrutura hierárquica dos itens de navegação da UI.';

-- Índice para otimizar a busca de sub-itens.
CREATE INDEX IF NOT EXISTS idx_navigation_items_parent_id ON public.navigation_items(parent_id);

Campos e Restrições:
id (UUID, PK): Chave primária do item de navegação.
key (TEXT, UNIQUE): Uma chave de texto única e amigável para o desenvolvedor (ex: "dashboard", "settings.profile").
label (TEXT, NOT NULL): O texto que será exibido para o usuário na UI (ex: "Dashboard", "Meu Perfil").
path (TEXT): O caminho/rota da aplicação para onde o item aponta (ex: "/dashboard", "/settings/profile").
icon (TEXT): O nome ou identificador do ícone a ser exibido.
parent_id (UUID, FK): Referencia o id de outro item na mesma tabela, criando uma relação de parentesco (menu/submenu).
display_order (INTEGER, NOT NULL): Controla a ordem em que os itens aparecem no mesmo nível hierárquico.
is_active (BOOLEAN, NOT NULL): Permite ativar ou desativar um item de navegação globalmente.
3.2. Tabela nav_item_permissions
Finalidade e Justificativa: Esta tabela de junção é a ponte entre a estrutura da UI (navigation_items) e o sistema de autorização (permissions). Ela define explicitamente qual permissão é necessária para visualizar um determinado item de navegação. Com base nas permissões totais de um usuário (derivadas de seus papéis), o front-end pode consultar esta tabela para decidir dinamicamente quais itens de menu renderizar, garantindo que os usuários vejam apenas os links para as áreas do sistema que eles têm permissão para acessar.
DDL (SQL):
CREATE TABLE public.nav_item_permissions (
  nav_item_id UUID NOT NULL REFERENCES public.navigation_items(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (nav_item_id, permission_id)
);

COMMENT ON TABLE public.nav_item_permissions IS 'Tabela de junção N:N entre itens de navegação e as permissões necessárias para visualizá-los.';

Campos e Restrições:
nav_item_id (UUID, NOT NULL, FK): Referencia o item de navegação.
permission_id (UUID, NOT NULL, FK): Referencia a permissão necessária para ver o item.
PRIMARY KEY (nav_item_id, permission_id): Garante que uma permissão só possa ser associada a um item de navegação uma única vez.
4. Domínio: Conformidade e Auditoria
Este domínio gerencia o consentimento do usuário para documentos legais, como Termos de Serviço e Políticas de Privacidade. É essencial para garantir a conformidade com regulamentações de proteção de dados e para manter uma trilha de auditoria clara sobre quais termos cada usuário aceitou e quando.
4.1. Tabela consent_types
Finalidade e Justificativa: Esta tabela funciona como um catálogo versionado de todos os documentos de consentimento. Ao separar o tipo (type) da versão (version), podemos gerenciar múltiplas versões de um mesmo documento (ex: "Termos de Serviço", versão "1.0", "1.1", etc.). Isso permite que a aplicação solicite o consentimento do usuário sempre que uma nova versão de um documento for publicada.
DDL (SQL):
CREATE TABLE public.consent_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  version TEXT NOT NULL,
  content_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  UNIQUE (type, version)
);

COMMENT ON TABLE public.consent_types IS 'Catálogo versionado de documentos de consentimento (ex: Termos de Serviço, Política de Privacidade).';

Campos e Restrições:
id (UUID, PK): Chave primária do tipo de consentimento.
type (TEXT, NOT NULL): O tipo do documento (ex: "TERMS_OF_SERVICE", "PRIVACY_POLICY").
version (TEXT, NOT NULL): A versão específica do documento (ex: "1.0", "2.0.1").
content_url (TEXT): Um link para o local onde o conteúdo completo do documento pode ser lido.
is_active (BOOLEAN, NOT NULL): Indica se esta versão do consentimento está ativa e pode ser apresentada aos usuários.
UNIQUE (type, version): Garante que não existam duas entradas para a mesma versão do mesmo tipo de documento.
4.2. Tabela user_consents
Finalidade e Justificativa: Esta tabela é o registro de auditoria que vincula um usuário (user_id) a uma versão específica de um documento de consentimento (consent_id). Cada linha representa a prova de que um usuário concordou com um determinado termo em uma data específica. O ON DELETE CASCADE garante que, se um usuário ou um tipo de consentimento for removido, o registro de consentimento correspondente também seja limpo para manter a integridade dos dados.
DDL (SQL):
CREATE TABLE public.user_consents (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_id UUID NOT NULL REFERENCES public.consent_types(id) ON DELETE CASCADE,
  consented_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, consent_id)
);

COMMENT ON TABLE public.user_consents IS 'Registra qual usuário consentiu com qual versão de um documento.';

-- Índice para otimizar a busca de usuários que aceitaram um termo específico.
CREATE INDEX idx_user_consents_consent_id ON public.user_consents(consent_id);

Campos e Restrições:
user_id (UUID, NOT NULL, FK): Referencia o usuário que deu o consentimento.
consent_id (UUID, NOT NULL, FK): Referencia a versão específica do documento com a qual o usuário concordou.
consented_at (TIMESTAMPTZ, NOT NULL): A data e hora exatas em que o consentimento foi dado.
PRIMARY KEY (user_id, consent_id): Garante que um usuário só possa consentir com a mesma versão de um documento uma única vez.
5. Conclusão
O esquema da base de dados aqui detalhado estabelece uma fundação robusta e coesa para um sistema SaaS B-to-B. Através da separação lógica em domínios distintos — Identidade, Autorização, Monetização, Interface e Conformidade — criamos um modelo que é ao mesmo tempo seguro, escalável e de fácil manutenção.
As principais características desta arquitetura são:
Segurança Multi-Tenant: O isolamento de dados por company_id é o pilar central, garantindo que os dados de um cliente nunca sejam expostos a outro.
Autorização Flexível: A abordagem híbrida de ABAC e RBAC oferece um controle de acesso poderoso, combinando a simplicidade dos papéis com a granularidade do acesso baseado em atributos, tudo reforçado por RLS no nível do banco de dados.
Modelo de Negócio Adaptável: A estrutura de planos, preços e features permite que a oferta comercial do produto evolua sem a necessidade de alterações complexas no código.
Governança e Auditoria: As tabelas de consentimento e históricos fornecem as trilhas de auditoria necessárias para conformidade e análise de negócio.
Em suma, este modelo de dados não é apenas uma estrutura para armazenar informações, mas sim o alicerce estratégico sobre o qual toda a lógica de negócio, experiência do usuário e segurança da aplicação serão construídas.
