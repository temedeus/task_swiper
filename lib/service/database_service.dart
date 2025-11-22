import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:taskswiper/model/task.dart';
import '../model/status.dart';
import '../model/task_list.dart';
import '../model/recurrence_rules.dart';
import 'database_callbacks.dart';
import 'dart:convert';

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
      onCreate: (db, version) => onCreateCallback(db, version),
      onUpgrade: (db, oldVersion, newVersion) =>
          onUpgradeCallback(db, oldVersion, newVersion),
      version: version,
    );
  }

  Future<int> createItem(Task task) async {
    final now = DateTime.now().toIso8601String();
    final taskMap = task.toMap();
    // Set createdAt if not already set, always set updatedAt
    if (taskMap['createdAt'] == null) {
      taskMap['createdAt'] = now;
    }
    taskMap['updatedAt'] = now;
    return database.insert('task', taskMap,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Task task) async {
    final now = DateTime.now().toIso8601String();
    final taskMap = task.toMap();
    // Preserve createdAt if it exists, always update updatedAt
    if (taskMap['createdAt'] == null) {
      // If updating and createdAt is null, try to get it from the database
      final existing = await database.query('task', 
          columns: ['createdAt'], 
          where: "id = ?", 
          whereArgs: [task.id!]);
      if (existing.isNotEmpty && existing.first['createdAt'] != null) {
        taskMap['createdAt'] = existing.first['createdAt'];
      } else {
        taskMap['createdAt'] = now;
      }
    }
    taskMap['updatedAt'] = now;
    return database.update('task', taskMap,
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
      print('Error retrieving task list completeness: $e');
    }

    return completenessMap;
  }

  Future<void> deleteTask(int id) async {
    await database.delete("task", where: "id = ?", whereArgs: [id]);
  }

  Future<void> deleteTasksByTaskList(int taskListId) async {
    await database.delete("task", where: "taskListId = ?", whereArgs: [taskListId]);
  }

  Future<void> deleteTasklist(int id) async {
    await database.delete("taskList", where: "id = ?", whereArgs: [id]);
  }

  Future<int> saveRecurrenceRule(RecurrenceRules recurrence) async {
    return await database.insert('recurrenceRules', recurrence.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<RecurrenceRules?> getRecurrenceRule(int recurrenceId) async {
    final List<Map<String, Object?>> queryResult = await database
        .query('recurrenceRules', where: "id = ?", whereArgs: [recurrenceId]);
    if (queryResult.isNotEmpty) {
      return RecurrenceRules.fromMap(queryResult.first);
    }
    return null;
  }

  /// Get all completed tasks that have recurrence rules
  Future<List<Map<String, dynamic>>> getCompletedTasksWithRecurrence() async {
    final List<Map<String, dynamic>> queryResult = await database.rawQuery('''
      SELECT t.*, r.id as recurrenceRuleId, r.frequency, r.interval, r.daysOfWeek, r.endDate, 
             r.maxOccurrences, r.timeOfDay
      FROM task t
      INNER JOIN recurrenceRules r ON t.recurrenceId = r.id
      WHERE t.status = ?
    ''', [Status.completed]);
    
    return queryResult;
  }
}
