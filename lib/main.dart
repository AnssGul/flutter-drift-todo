import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'database/app_database.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drift Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late AppDatabase _database;
  late Future<void> _databaseInitialization;
  late Stream<List<TodoItem>> _todosStream;

  @override
  void initState() {
    super.initState();
    _databaseInitialization = _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    _database = AppDatabase(NativeDatabase(file));
    _todosStream = _database.watchAllTodoItems();
  }

  Future<void> _addTodo() async {
    final newTodo = TodoItemsCompanion(
      title: Value('New Task'),
      content: Value('Task content goes here'),
      createdAt: Value(DateTime.now()),
    );
    await _database.insertTodoItem(newTodo);
  }

  Future<void> _editTodo(int id) async {
    final todo = await _database.getAllTodoItems();
    final updatedTodo = todo.firstWhere((t) => t.id == id).copyWith(
          title: 'Updated Task',
          content: 'Updated content',
        );
    await _database.updateTodoItem(updatedTodo);
  }

  Future<void> _deleteTodo(int id) async {
    await _database.deleteTodoItem(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drift Example'),
      ),
      body: FutureBuilder<void>(
        future: _databaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          return StreamBuilder<List<TodoItem>>(
            stream: _todosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final todos = snapshot.data ?? [];
              return ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return ListTile(
                    title: Text(todo.title),
                    subtitle: Text(todo.content),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editTodo(todo.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteTodo(todo.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: Icon(Icons.add),
      ),
    );
  }
}
