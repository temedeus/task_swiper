import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';class SqliteService {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();

    return openDatabase(
      join(path, 'task_database.db'),
      onCreate: (database, version) async {
        await database.execute(
            "CREATE TABLE Task(id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT NOT NULL, duedate TEXT)",
        );
      },
      version: 1,
    );
  }
}