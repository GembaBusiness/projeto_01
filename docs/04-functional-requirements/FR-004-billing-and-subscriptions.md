# Requisito Funcional: Faturamento e Assinaturas

**ID:** FR-004
**Título:** Gestão de Faturamento e Assinaturas

## Descrição
Este documento especifica os requisitos funcionais para o ciclo de vida da monetização, permitindo que os usuários selecionem planos, gerenciem suas assinaturas e acessem o portal de faturamento.

## Requisitos

### RF-04.1: Seleção de Plano e Checkout
-   **Descrição:** O usuário deve poder selecionar um dos planos de assinatura disponíveis e iniciar o processo de pagamento através de um checkout seguro.
-   **Critérios de Aceitação:**
    1.  A página de preços deve exibir claramente os planos, funcionalidades e preços.
    2.  Ao selecionar um plano, o usuário deve ser redirecionado para a página de checkout do gateway de pagamentos (e.g., Stripe Checkout).
    3.  A sessão de checkout deve ser pré-preenchida com o e-mail do usuário, se ele estiver logado.
    4.  Após o pagamento bem-sucedido, a assinatura do tenant deve ser criada no sistema e o usuário redirecionado para uma página de sucesso.
    5.  Em caso de falha no pagamento, o usuário deve ser informado e poder tentar novamente.

### RF-04.2: Gestão do Ciclo de Vida da Assinatura
-   **Descrição:** O sistema deve gerenciar automaticamente o estado da assinatura do cliente com base nos eventos do gateway de pagamentos.
-   **Critérios de Aceitação:**
    1.  O sistema deve ser capaz de lidar com os seguintes status de assinatura, sincronizados via webhooks: `trial`, `active`, `past_due`, `canceled`, `unpaid`.
    2.  Se uma assinatura entrar em `past_due`, o sistema pode limitar o acesso a certas funcionalidades até que o pagamento seja regularizado.
    3.  Se uma assinatura for `canceled`, o acesso às funcionalidades pagas deve ser revogado ao final do período de faturamento corrente.
    4.  O sistema deve lidar com upgrades e downgrades de plano.

### RF-04.3: Portal do Cliente
-   **Descrição:** O usuário deve poder acessar um portal seguro para gerenciar seus dados de faturamento.
-   **Critérios de Aceitação:**
    1.  O usuário deve ter acesso a um link para o portal do cliente (e.g., Stripe Customer Portal) a partir da sua página de configurações de conta.
    2.  No portal, o usuário deve poder:
        -   Atualizar seus métodos de pagamento (adicionar/remover cartão).
        -   Visualizar e baixar seu histórico de faturas (invoices).
        -   Cancelar sua assinatura.
        -   Fazer upgrade ou downgrade do seu plano.

### RF-04.4: Aplicação de Limites e Funcionalidades do Plano
-   **Descrição:** O sistema deve aplicar em tempo real os limites e o acesso às funcionalidades de acordo com o plano ativo da assinatura do tenant.
-   **Critérios de Aceitação:**
    1.  O acesso a uma funcionalidade específica deve ser verificado contra o plano ativo do tenant (`subscriptions.plan_id`).
    2.  Limites quantitativos (e.g., número de usuários, volume de armazenamento) devem ser impostos pela lógica de negócio.
    3.  Quando um usuário tenta executar uma ação que excede os limites do seu plano, ele deve receber uma mensagem informativa com um call-to-action para fazer um upgrade.
