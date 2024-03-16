import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskswiper/model/task.dart';

import '../model/task_list.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  late final Database _database;

  DatabaseService._internal();

  Future<void> initializeDB() async {
    String path = await getDatabasesPath();
    _database = await openDatabase(
      join(path, 'task_database.db'),
      onCreate: (database, version) async {
        await database.execute(
          "CREATE TABLE taskList(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)",
        );
        await database.execute(
          "CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, " +
              "task TEXT NOT NULL, taskListId INTEGER NOT NULL, " +
              "FOREIGN KEY(taskListId) REFERENCES taskList(id))",
        );

        // Create default items.
        int id = await database.rawInsert(
          "INSERT INTO taskList (title) VALUES ('Untitled list');",
        );

        // Create default items.
        await database.execute(
          "INSERT INTO task (task, taskListId) VALUES ('Start using Task Swiper!\n\n " +
              "Create new lists from the menu on the right.\n\n"
              "Swipe task up to complete\n\n" +
              "Swipe task down to delete\n\n"
            "', ?);", [id]
        );
      },
      version: 1,
    );
  }

  Future<int> createItem(Task task) async {
    return _database.insert('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Task task) async {
    return _database.update('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, where: "id = ?", whereArgs: [task.id!]);
  }

  Future<int> createTasklist(TaskList taskList) async {
    return _database.insert('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTasklist(TaskList taskList) async {
    return _database.update('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace, where: "id = ?", whereArgs: [taskList.id!]);
  }

  Future<List<Task>> getTasks(int taskListId) async {
    final List<Map<String, Object?>> queryResult = await _database
        .query('task', where: "taskListId = ?", whereArgs: [taskListId]);
    return queryResult.map((e) => Task.fromMap(e)).toList();
  }

  Future<TaskList> getDefaultTaskList() async {
    final List<Map<String, Object?>> queryResult =
        await _database.query('taskList');
    // TODO: default user settings
    return TaskList.fromMap(queryResult.first);
  }

  Future<List<TaskList>> getTaskLists() async {
    final List<Map<String, Object?>> queryResult =
        await _database.query('taskList');
    return queryResult.map((e) => TaskList.fromMap(e)).toList();
  }

  Future<void> deleteTask(int id) async {
    await _database.delete("task", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteTasksByTaskList(int taskListId) async {
    await _database.delete("task", where: "taskListId = ?", whereArgs: [taskListId]);
  }

  Future<void> deleteTasklist(int id) async {
    await _database.delete("taskList", where: "id = ?", whereArgs: [id]);
  }
}
