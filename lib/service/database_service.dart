import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskswiper/model/task.dart';

import '../model/status.dart';
import '../model/task_list.dart';
import 'database_callbacks.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  static final int version = 2;
  factory DatabaseService() {
    return _instance;
  }

  late final Database database;

  DatabaseService._internal();

  Future<void> initializeDB() async {
    String path = await getDatabasesPath();
    database = await openDatabase(
      join(path, 'task_database.db'),
      onCreate: (db, version) => onCreateCallback(db, version), // Use onCreateCallback
      onUpgrade: (db, oldVersion, newVersion) =>
          onUpgradeCallback(db, oldVersion, newVersion), // Use onUpgradeCallback
      version: version,
    );
  }

  Future<int> createItem(Task task) async {
    return database.insert('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Task task) async {
    return database.update('task', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
        where: "id = ?",
        whereArgs: [task.id!]);
  }

  Future<int> createTasklist(TaskList taskList) async {
    return database.insert('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTasklist(TaskList taskList) async {
    return database.update('taskList', taskList.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
        where: "id = ?",
        whereArgs: [taskList.id!]);
  }

  Future<List<Task>> getTasks(int taskListId) async {
    final List<Map<String, Object?>> queryResult = await database
        .query('task', where: "taskListId = ?", whereArgs: [taskListId]);
    return queryResult.map((e) => Task.fromMap(e)).toList();
  }

  Future<TaskList> getDefaultTaskList() async {
    final List<Map<String, Object?>> queryResult =
        await database.query('taskList');
    // TODO: default user settings
    return TaskList.fromMap(queryResult.first);
  }

  Future<List<TaskList>> getTaskLists() async {
    final List<Map<String, Object?>> queryResult =
        await database.query('taskList');
    return queryResult.map((e) => TaskList.fromMap(e)).toList();
  }

  Future<Map<int, bool>> getTaskListCompleteness() async {
    Map<int, bool> completenessMap = {};

    try {
      final List<Map<String, dynamic>> results = await database.rawQuery('''
      SELECT tl.id, 
             CASE 
               WHEN COUNT(t.id) = 0 THEN 0 
               ELSE MIN(CASE WHEN t.status = '${Status.open}' THEN 0 ELSE 1 END) 
             END AS completeness
      FROM taskList tl
      LEFT JOIN task t ON tl.id = t.taskListId
      GROUP BY tl.id
    ''');

      for (final result in results) {
        completenessMap[result['id'] as int] = (result['completeness'] == 1);
      }
    } catch (e) {
      // Handle error
      print('Error retrieving task list completeness: $e');
    }

    return completenessMap;
  }

  Future<void> deleteTask(int id) async {
    await database.delete("task", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteTasksByTaskList(int taskListId) async {
    await database
        .delete("task", where: "taskListId = ?", whereArgs: [taskListId]);
  }

  Future<void> deleteTasklist(int id) async {
    await database.delete("taskList", where: "id = ?", whereArgs: [id]);
  }
}
