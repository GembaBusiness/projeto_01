🏛️ Documentação Racional: Módulo 7 (Cartão de Visita)
1. Visão Geral
O objetivo deste módulo é criar um sistema de "Cartão de Visita Digital" flexível e rastreável. O design separa claramente a identidade pessoal (public_profiles) da identidade corporativa (company_profiles) e as conecta através de uma tabela de "vitrine" (profile_company_showcase).
O recurso principal é o "Share" (profile_shares): um link/token único gerado para cada papel (showcase) que um usuário possui. A "mágica" deste sistema é que o usuário pode alterar o que esse link exibe (só perfil, só empresa, ou ambos) a qualquer momento, sem precisar trocar o QR Code ou o cartão NFC físico.
2. Conceitos Principais e Racional do Design
Abaixo está o racional por trás de cada tabela principal e sua interação.
🌍 Conceito 1: Perfis de Entidade (A Base)
O sistema armazena dois tipos distintos de perfis públicos:
public_profiles (O Indivíduo):
Racional: Esta tabela armazena os dados pessoais que um usuário deseja exibir (nome, bio, redes sociais pessoais).
Relação: É 1:1 com a tabela profiles (que por sua vez está ligada ao auth.users). Cada usuário autenticado pode ter no máximo um perfil público.
Destaques:
privacy_settings (JSONB): Permite controle granular (campo a campo) sobre o que é público ou privado.
slug: Garante uma URL limpa e única para o perfil pessoal (ex: /p/joao.silva).
company_profiles (A Organização):
Racional: Armazena dados institucionais (logo, tagline, redes sociais da empresa).
Relação: É 1:1 com a tabela companies. Cada entidade de empresa tem um perfil público.
Destaques:
slug: Garante uma URL limpa para a empresa (ex: /c/empresa-tech).
🔗 Conceito 2: O "Showcase" (A Conexão)
Esta é a tabela-pivô que conecta Pessoas e Empresas.
Tabela: profile_company_showcase
Racional: Um usuário não está apenas "ligado" a uma empresa; ele tem um papel ou cargo específico nela (ex: "CEO na Empresa A" ou "Consultor na Empresa B"). Esta tabela armazena essa relação de "experiência profissional".
Relação: N:N (Muitos-para-Muitos) entre profiles e companies.
Destaques:
membership_id (Híbrido): Este é um campo-chave.
Se NÃO NULO, o showcase está ativamente vinculado a um membership (cargo atual). Se o membership for excluído, o campo vira NULL.
Se NULO, representa uma experiência passada (histórico profissional) que o usuário inseriu manualmente ou que já expirou.
slug (Único por Perfil): Permite URLs de experiência, como /p/joao.silva/empresa-a.
is_active (Toggle): Permite ao usuário "ocultar" uma empresa de seu perfil público sem excluir o registro.
🚀 Conceito 3: O "Share" (O Token Compartilhável)
Este é o coração funcional do módulo.
Tabela: profile_shares
Racional: Este registro é o "link" físico/digital. É o que é gravado no NFC, no QR Code ou enviado como URL. A decisão de design mais importante está aqui.
Regra de Ouro: A relação é 1:1 com profile_company_showcase.
Isso significa: Para cada cargo/showcase que um usuário tem (ex: "João na Empresa A" e "João na Empresa B"), um novo e distinto profile_shares (com um share_token único) é criado.
Por quê? Isso permite que João tenha um cartão NFC para a Empresa A e outro cartão para a Empresa B, ambos gerenciados por ele.
A "Mágica" - share_display_type (ENUM Mutável):
Este campo (user, company, user_and_company) define o que o share_token exibe quando acessado.
Racional: O share_token é permanente, mas o share_display_type é mutável. O usuário pode ir ao app e mudar o modo de exibição do seu cartão a qualquer momento. O cartão NFC/QR físico (que apenas contém o share_token) passa a exibir o novo modo instantaneamente.
📊 Conceito 4: Analytics (Rastreamento Detalhado)
O analytics foi dividido em duas tabelas para maior clareza e performance:
share_events (A Interação):
Racional: Registra o evento de interação inicial (o "toque" ou "scan").
Responde: "Quantas vezes meu cartão foi escaneado/tapado?"
Destaques: event_type (nfc_tap, qr_scan) e event_context (JSONB) para o usuário adicionar notas (ex: "Evento Tech SP 2025").
profile_views (O Resultado):
Racional: Registra a visualização de página bem-sucedida que resultou da interação.
Responde: "Quantas pessoas realmente viram meu perfil após o scan?"
Destaque Crítico - share_display_type_at_view (Snapshot):
Racional: Como o share_display_type na tabela profile_shares é mutável, não podemos usá-lo para analytics históricos.
Esta coluna é um SNAPSHOT: ela salva qual era o modo de exibição (user, company, etc.) no exato momento em que a visualização ocorreu.
Exemplo: Se João recebe 100 views no modo "company" e depois muda para "user", o dashboard de analytics pode mostrar corretamente "100 views no modo 'company'" graças a este snapshot, em vez de assumir erroneamente que todas as 100 views foram no modo "user".
3. Fluxo de Dados (Exemplo Prático)
Este fluxo ilustra como as tabelas interagem:
Setup Inicial:
Usuário "João" tem um public_profiles (ID: pub_joao).
Empresa "TechCorp" tem um company_profiles (ID: com_tech).
João é adicionado à TechCorp. Um profile_company_showcase é criado (ID: show_joao_tech) ligando pub_joao e com_tech, com o cargo "Developer".
Criação do Share:
O sistema cria automaticamente um profile_shares (ID: share_1) ligado ao showcase_id = show_joao_tech.
Este registro ganha um share_token único (ex: a1b2c3d4-xxxx...).
João define o share_display_type deste share como user_and_company.
Uso (NFC):
João grava o share_token (a1b2c3d4-xxxx...) em seu cartão NFC físico.
Maria encosta o celular no cartão de João.
Tracking (Evento):
O celular envia um "ping" para o sistema.
O sistema cria um share_events (share_id: share_1, event_type: nfc_tap).
Visualização (View):
O sistema lê o share_1, vê que o modo é user_and_company, e renderiza a página com os dados de João E da TechCorp.
O sistema cria um profile_views, registrando a view e o snapshot: share_display_type_at_view = 'user_and_company'.
A Mudança (A "Mágica"):
Na semana seguinte, João (sem trocar o cartão NFC) acessa o app e muda o share_display_type do share_1 para company.
Pedro encosta o celular no mesmo cartão NFC.
O sistema lê o share_1, vê que o modo agora é company, e renderiza a página mostrando apenas os dados da TechCorp.
Um novo profile_views é criado com o snapshot: share_display_type_at_view = 'company'.
