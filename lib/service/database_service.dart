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
}
