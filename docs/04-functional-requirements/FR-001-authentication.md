# Requisito Funcional: Autenticação de Usuários

**ID:** FR-001
**Título:** Autenticação de Usuários

## Descrição
Este documento especifica os requisitos funcionais para o sistema de autenticação, permitindo que os usuários se cadastrem, acessem e gerenciem suas contas de forma segura.

## Requisitos

### RF-01.1: Cadastro Multi-empresa (Sign-up)
-   **Descrição:** Um novo usuário deve poder se cadastrar fornecendo um nome, endereço de e-mail, senha e o nome da sua empresa.
-   **Critérios de Aceitação:**
    1.  Ao submeter o formulário de cadastro, uma nova entrada deve ser criada na tabela `companies`.
    2.  Uma nova conta de usuário deve ser criada em `auth.users` no Supabase.
    3.  Um novo perfil deve ser criado na tabela `profiles`, ligando o usuário à nova empresa.
    4.  O primeiro usuário da empresa deve receber automaticamente o papel de "Admin".
    5.  O usuário deve ser redirecionado para a página de boas-vindas ou dashboard após o cadastro bem-sucedido.

### RF-01.2: Login de Usuário (Sign-in)
-   **Descrição:** Um usuário registrado deve poder fazer login no sistema usando seu e-mail e senha.
-   **Critérios de Aceitação:**
    1.  O sistema deve validar as credenciais contra o serviço de autenticação do Supabase.
    2.  Em caso de sucesso, o usuário deve ser redirecionado para o seu dashboard.
    3.  A sessão do usuário deve ser estabelecida e mantida (via JWT).
    4.  Em caso de falha (credenciais inválidas), uma mensagem de erro clara deve ser exibida.

### RF-01.3: Recuperação de Senha (Password Reset)
-   **Descrição:** Um usuário que esqueceu sua senha deve poder solicitar a redefinição da mesma.
-   **Critérios de Aceitação:**
    1.  O usuário deve poder inserir seu e-mail em um formulário de "Esqueci minha senha".
    2.  O sistema deve usar o serviço de recuperação de senha do Supabase para enviar um e-mail com um link de redefinição.
    3.  O link deve levar o usuário a uma página onde ele pode definir uma nova senha.
    4.  Após a redefinição bem-sucedida, o usuário deve ser notificado e poder fazer login com a nova senha.
