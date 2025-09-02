# Função: `create_company_and_profile`

Esta é uma função de base de dados (procedimento armazenado) que encapsula a lógica de negócio para criar uma nova empresa e, ao mesmo tempo, estabelecer o utilizador que a criou como o seu primeiro membro com um papel de administrador.

**Schema**: `public`
**Tipo de Retorno**: `uuid` (o `id` da nova empresa)
**Argumentos**:
- `company_name` (`text`): O nome para a nova empresa.

## Propósito

Chamar esta função em vez de fazer `INSERT`s diretos nas tabelas `companies` e `memberships` oferece várias vantagens:
1.  **Atomicidade**: A operação inteira (criar a empresa E adicionar o membro) acontece numa única transação. Se uma parte falhar, tudo é revertido, garantindo a consistência dos dados.
2.  **Segurança**: A função é executada com `security definer`, o que significa que ela corre com os privilégios do seu criador (um administrador). Isto permite-lhe inserir dados em tabelas protegidas de uma forma controlada, sem dar permissões de `INSERT` diretas aos utilizadores finais na tabela `memberships`.
3.  **Abstração**: A lógica de negócio complexa é encapsulada na base de dados, simplificando as chamadas do lado do cliente (frontend/backend).

## Lógica da Função (resumo)

1.  **Verifica Autenticação**: A função primeiro verifica se o utilizador que a chama está autenticado (`auth.uid() IS NOT NULL`).
2.  **Insere a Empresa**: Cria um novo registo na tabela `public.companies`, definindo o `name` com o argumento recebido e o `owner_id` com o `id` do utilizador autenticado.
3.  **Recupera o ID da Nova Empresa**: Obtém o `id` da empresa que acabou de ser criada.
4.  **Insere o Vínculo (Membership)**: Cria um novo registo na tabela `public.memberships`, ligando o `id` do utilizador (`user_id`) ao `id` da nova empresa (`company_id`) e atribuindo-lhe o papel (`role`) de `'admin'`.
5.  **Retorna o ID da Empresa**: Retorna o `id` da nova empresa para que o cliente possa redirecionar ou realizar outras ações.

## Como Chamar (via API)

Esta função pode ser chamada através de um `POST` request para o endpoint de RPC do Supabase.

`POST /rest/v1/rpc/create_company_and_profile`

**Corpo da Requisição (JSON):**
```json
{
  "company_name": "Minha Nova Empresa Fantástica"
}
```
