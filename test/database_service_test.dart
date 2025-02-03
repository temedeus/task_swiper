import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taskswiper/model/status.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/model/task_list.dart';
import 'package:taskswiper/service/database_callbacks.dart';
import 'package:taskswiper/service/database_service.dart';

void main() {
  late Database database;
  late DatabaseService taskService;

  setUpAll(() async {
    sqfliteFfiInit();
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await onCreateCallback(database, 2);
    await onUpgradeCallback(database, 1, 2);
    taskService = DatabaseService();
    taskService.database = database;
  });

  group('DatabaseService Tests', () {
    test('Create and fetch TaskList', () async {
      final taskList = TaskList(null, 'Test Task List');
      final int id = await taskService.createTasklist(taskList);

      expect(id, isNotNull);

      final fetchedLists = await taskService.getTaskLists();
      expect(fetchedLists.length, equals(2));
      expect(fetchedLists.any((list) => list.title == 'Test Task List'), isTrue);
      expect(fetchedLists.any((list) => list.title == 'Untitled list'), isTrue);
    });

    test('Create and fetch Tasks', () async {
      final taskList = TaskList(null, 'New Task List');
      final taskListId = await taskService.createTasklist(taskList);

      final task = Task(null, 'Test Task', Status.open, taskListId);
      final taskId = await taskService.createItem(task);

      expect(taskId, isNotNull);

      final fetchedTasks = await taskService.getTasks(taskListId);
      expect(fetchedTasks.length, 1);
      expect(fetchedTasks.first.task, 'Test Task');
    });

    test('Update Task', () async {
      final taskList = TaskList(null, 'List for Update Test');
      final taskListId = await taskService.createTasklist(taskList);

      final task = Task(null, 'Task to Update', Status.open, taskListId);
      final taskId = await taskService.createItem(task);

      final updatedTask = Task(taskId, 'Updated Task', Status.completed, taskListId);
      final updateCount = await taskService.updateTask(updatedTask);

      expect(updateCount, 1);

      final fetchedTasks = await taskService.getTasks(taskListId);
      expect(fetchedTasks.first.task, 'Updated Task');
      expect(fetchedTasks.first.status, Status.completed);
    });

    test('Delete Task', () async {
      final taskList = TaskList(0, 'List for Delete Test');
      final taskListId = await taskService.createTasklist(taskList);

      final task = Task(0, 'Task to Delete', Status.open, taskListId);
      final taskId = await taskService.createItem(task);

      await taskService.deleteTask(taskId);

      final fetchedTasks = await taskService.getTasks(taskListId);
      expect(fetchedTasks, isEmpty);
    });

    test('Fetch Default TaskList', () async {
      final defaultList = await taskService.getDefaultTaskList();

      expect(defaultList, isA<TaskList>());
    });

    test('TaskList Completeness', () async {
      final taskList = TaskList(null, 'Completeness Test List');
      final taskListId = await taskService.createTasklist(taskList);

      final task1 = Task(null, 'Incomplete Task', Status.open, taskListId);
      final task2 = Task(null, 'Complete Task', Status.completed, taskListId);

      int task1id = await taskService.createItem(task1);
      await taskService.createItem(task2);

      final completeness = await taskService.getTaskListCompleteness();

      expect(completeness[taskListId], false);

      final updatedTask = Task(task1id, 'Now Complete', Status.completed, taskListId);
      await taskService.updateTask(updatedTask);

      final updatedCompleteness = await taskService.getTaskListCompleteness();
      expect(updatedCompleteness[taskListId], true);
    });
  });
}
