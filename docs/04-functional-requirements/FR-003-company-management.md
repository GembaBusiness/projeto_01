# Requisito Funcional: Gestão da Empresa

**ID:** FR-003
**Título:** Gestão da Empresa e de Usuários

## Descrição
Este documento especifica os requisitos para as funcionalidades que permitem aos administradores de uma empresa gerir os seus próprios usuários e configurações.

## Requisitos

### RF-03.1: Convidar Novos Usuários
-   **Descrição:** Um usuário com permissão de administrador (`Admin`) deve poder convidar novos usuários para se juntarem à sua empresa.
-   **Critérios de Aceitação:**
    1.  O administrador deve ter acesso a um formulário onde pode inserir o endereço de e-mail do convidado e selecionar um papel para ele.
    2.  O sistema deve enviar um e-mail de convite para o endereço fornecido, usando o sistema de convites do Supabase (`supabase.auth.admin.inviteUserByEmail()`).
    3.  O e-mail de convite deve conter um link único para o novo usuário definir sua senha e completar o cadastro.
    4.  O novo usuário será automaticamente associado à `company_id` correta.
    5.  O usuário convidado deve aparecer numa lista de "Convites Pendentes" até que o cadastro seja concluído.

### RF-03.2: Atribuir Papéis a Usuários
-   **Descrição:** Um administrador deve poder visualizar uma lista de todos os usuários da sua empresa e alterar os seus papéis.
-   **Critérios de Aceitação:**
    1.  Deve existir uma página de "Gestão de Usuários" visível apenas para administradores.
    2.  A página deve listar todos os usuários associados à `company_id` do administrador.
    3.  Para cada usuário na lista, o administrador deve poder selecionar um novo papel a partir de uma lista suspensa (dropdown).
    4.  A alteração do papel deve ser refletida imediatamente nas permissões do usuário.
    5.  Um administrador não pode alterar o seu próprio papel para um nível inferior se for o único administrador da empresa.

### RF-03.3: Remover Usuários da Empresa
-   **Descrição:** Um administrador deve poder remover um usuário da sua empresa.
-   **Critérios de Aceitação:**
    1.  Na lista de usuários, deve haver uma opção para remover um usuário.
    2.  O sistema deve pedir uma confirmação antes de prosseguir com a remoção.
    3.  A remoção deve desativar o perfil do usuário na tabela `profiles` ou removê-lo, impedindo o acesso à empresa. (A conta em `auth.users` pode ser mantida, mas o acesso à empresa é revogado).
    4.  Um administrador não pode remover a si próprio.

---

## Tabelas de Banco de Dados Relacionadas
-   [`companies`](../03-database-schema.md#companies): Armazena os dados da própria empresa (tenant).
-   [`profiles`](../03-database-schema.md#profiles): Gerencia os perfis dos usuários que pertencem à empresa.
