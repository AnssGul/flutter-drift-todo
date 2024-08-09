import 'package:drift/drift.dart';
import 'package:drift/native.dart';
part 'app_database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category =>
      integer().nullable().references(TodoCategory, #id)();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

class TodoCategory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
}

@DriftDatabase(tables: [TodoItems, TodoCategory])
class AppDatabase extends _$AppDatabase {
  AppDatabase(NativeDatabase db) : super(db);

  @override
  int get schemaVersion => 1;

  Future<List<TodoItem>> getAllTodoItems() => select(todoItems).get();

  Stream<List<TodoItem>> watchAllTodoItems() => select(todoItems).watch();

  Future<void> insertTodoItem(TodoItemsCompanion todo) =>
      into(todoItems).insert(todo);

  Future<void> updateTodoItem(TodoItem todo) => update(todoItems).replace(todo);

  Future<void> deleteTodoItem(int id) =>
      (delete(todoItems)..where((tbl) => tbl.id.equals(id))).go();
}
