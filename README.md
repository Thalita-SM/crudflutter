# DOCUMENTAÇÃO TÉCNICA: CRUD SIMPLES COM FLUTTER & SUPABASE

## 1. Visão Geral do Sistema

Esta documentação descreve o funcionamento do aplicativo Flutter desenvolvido para realizar operações básicas de CRUD (Create, Read, Update, Delete) em uma tabela de usuários integrada ao BaaS (Backend-as-a-Service) Supabase.

O aplicativo é composto por uma única arquitetura de página (Single Page) que se comunica diretamente com o Supabase utilizando o padrão Reativo. Ele gerencia dados da tabela `users`, estruturada da seguinte forma:

### Estrutura da Tabela (Tabela: users)

* id (uuid):* Chave primária gerada automaticamente pelo banco de dados.
* name (text):* Nome do usuário (obrigatório).
* email (text):* Endereço de e-mail do usuário (obrigatório).

---

## 2. Inicialização e Configuração Global

### Função main()

A função principal do ecossistema Flutter é configurada como assíncrona (`async`) para permitir a inicialização dos serviços do Supabase antes da renderização da interface.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Garante o vínculo dos Widgets nativos

  await Supabase.initialize(
    url: 'SUA_SUPABASE_URL_AQUI',
    anonKey: 'SUA_SUPABASE_ANON_KEY_AQUI',
  );

  runApp(const MyApp());
}

```

### Instância Global do Cliente

Uma constante global foi definida para simplificar as chamadas de banco de dados ao longo do código, evitando injeções de dependência complexas para este escopo:

```dart
final supabase = Supabase.instance.client;

```

---

## 3. Fluxo de Operações CRUD

O ciclo de vida dos dados é gerenciado integralmente dentro do widget reativo `UserListPage`.

### Create (Criar)

A inserção acontece dentro do método `_showFormDialog`. Quando o parâmetro `user` é nulo, o formulário entende que é um novo registro.

* **Método Utilizado:** `supabase.from('users').insert({ ... })`
* **Fluxo:** O banco de dados recebe o mapa com `name` e `email`, gerando o `id (uuid)` de forma nativa.

### Read (Ler em Tempo Real)

A leitura utiliza o recurso de Websockets (Realtime) do Supabase através de uma Stream.

* **Implementação:** `final _userStream = supabase.from('users').stream(primaryKey: ['id']);`
* **Renderização:** Um `StreamBuilder` escuta esta variável. Sempre que um dado muda no banco, a lista (`ListView.builder`) se redesenha automaticamente na tela, sem necessidade de atualizar manualmente.

### Update (Atualizar)

Se o método `_showFormDialog` receber um mapa `user` preenchido, o modal entra em modo de edição, pré-carregando os seletores `TextEditingController`.

* **Método Utilizado:** `supabase.from('users').update({ ... }).match({'id': user['id']})`
* **Fluxo:** Altera os campos correspondentes filtrando estritamente pelo ID do usuário selecionado.

### Delete (Deletar)

A exclusão é disparada direto no ícone de lixeira da lista.

* **Método Utilizado:**

```dart
Future<void> _deleteUser(String id) async {
  await supabase.from('users').delete().match({'id': id});
}

```

---

## 4. Componentes de Interface (UI)

* **UserListPage (StatefulWidget):** Controla o estado da tela principal, escuta a Stream do banco e renderiza os estados de carregamento (`CircularProgressIndicator`), lista vazia ou registros ativos.
* **_showFormDialog (Método Auxiliar):** Cria uma janela modal estilizada (`AlertDialog`) contendo dois campos de texto (`TextField`). Centraliza as ações de criação e edição para reaproveitamento de código de interface.

> **Nota de Segurança:** Este design foi projetado para prototipação rápida e testes. Em ambientes de produção, recomenda-se ativar o RLS (Row Level Security) no Supabase e implementar a autenticação de usuários (`Supabase.instance.client.auth`).
