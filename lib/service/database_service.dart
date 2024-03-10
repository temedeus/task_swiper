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

  DatabaseService._internal() {
    _initializeDB();
  }

  Future<void> _initializeDB() async {
    String path = await getDatabasesPath();
    _database = await openDatabase(
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
    return _database.insert('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> createTasklist(TaskList taskList) async {
    return _database.insert('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<void> deleteTasks(List<int> id) async {
    await _database.delete("task", where: "id IN (?)", whereArgs: [id]);
  }

  Future<void> deleteTasklist(int id) async {
    await _database.delete("taskList", where: "id = ?", whereArgs: [id]);
  }
}
