import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: 'https://djpvbatvxmiqoprbrfde.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcHZiYXR2eG1pcW9wcmJyZmRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5MzEzNzIsImV4cCI6MjA5NTUwNzM3Mn0.WKS12sS9tOflA1S61TUYpHOPMshEuV-bZ976GZZXXEc',
  );

  runApp(const MyApp());
}

// Atalho para acessar o cliente do Supabase de qualquer lugar
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase CRUD',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const UserListPage(),
    );
  }
}

// --- TELA PRINCIPAL (READ & DELETE) ---
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  // Stream para atualizar a lista em tempo real
  final _userStream = supabase.from('users').stream(primaryKey: ['id']);

  // Função para DELETAR
  Future<void> _deleteUser(String id) async {
    await supabase.from('users').delete().match({'id': id});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuários (Supabase)')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('Nenhum usuário encontrado.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user['name'] ?? ''),
                subtitle: Text(user['email'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão EDITAR
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showFormDialog(context, user: user),
                    ),
                    // Botão DELETAR
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteUser(user['id']),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- DIÁLOGO PARA CRIAR / EDITAR (CREATE & UPDATE) ---
  void _showFormDialog(BuildContext context, {Map<String, dynamic>? user}) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: isEditing ? user['name'] : '');
    final emailController = TextEditingController(text: isEditing ? user['email'] : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Usuário' : 'Novo Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final email = emailController.text;

              if (isEditing) {
                // OPERAÇÃO: UPDATE
                await supabase
                    .from('users')
                    .update({'name': name, 'email': email})
                    .match({'id': user['id']});
              } else {
                // OPERAÇÃO: CREATE
                await supabase
                    .from('users')
                    .insert({'name': name, 'email': email});
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }
}