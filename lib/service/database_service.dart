import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskswiper/task.dart';

class DatabaseService {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();

    return openDatabase(
      join(path, 'task_database.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE Task(id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT NOT NULL, due TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<int> createItem(Task task) async {
    final Database db = await initializeDB();
    return db.insert('Task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks() async {
    final db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query('Task');
    return queryResult.map((e) => Task.fromMap(e)).toList();
  }

  Future<void> deleteTask(int id) async {
    final db = await initializeDB();

    await db.delete("Task", where: "id = ?", whereArgs: [id]);
  }
}
