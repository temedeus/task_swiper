import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskswiper/model/task.dart';

import '../model/task_list.dart';

class DatabaseService {
  Future<Database> initializeDB() async {
    String path = await getDatabasesPath();

    return openDatabase(
      join(path, 'task_database.db'),
      onCreate: (database, version) async {

       await database.execute(
          "CREATE TABLE taskList(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)",
        );
        await database.execute(
          "CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, " +
              "task TEXT NOT NULL, due TEXT, taskListId INTEGER NOT NULL, " +
              "FOREIGN KEY(taskListId) REFERENCES taskList(id))",
        );

       // Create default items.
        await database.execute(
          "INSERT INTO taskList (title) VALUES ('Untitled list');",
        );
      },
      version: 1,
    );
  }

  Future<int> createItem(Task task) async {
    final Database db = await initializeDB();
    return db.insert('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> createTasklist(TaskList taskList) async {
    final Database db = await initializeDB();
    return db.insert('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks(int taskListId) async {
    final db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query('task', where: "taskListId = ?", whereArgs: [taskListId]);
    return queryResult.map((e) => Task.fromMap(e)).toList();
  }

  Future<TaskList> getDefaultTaskList() async {
    final db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query('taskList');
    // TODO: default user settings
    return queryResult.map((e) => TaskList.fromMap(e)).toList().first;
  }

  Future<List<TaskList>> getTaskLists() async {
    final db = await initializeDB();
    final List<Map<String, Object?>> queryResult = await db.query('taskList');
    return queryResult.map((e) => TaskList.fromMap(e)).toList();
  }

  Future<void> deleteTask(int id) async {
    final db = await initializeDB();

    await db.delete("task", where: "id = ?", whereArgs: [id]);
  }
}
