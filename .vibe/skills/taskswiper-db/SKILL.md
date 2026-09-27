---
name: taskswiper-db
description: Database operations and testing for Task Swiper's SQLite database. Use for querying, inserting, updating tasks and task lists, testing migrations, and debugging data issues.
 aliases: [database, db, sqlite, persistence, storage]
 on_include:
   - lib/service/database_service.dart
   - lib/service/database_callbacks.dart
   - lib/model/task.dart
   - lib/model/task_list.dart
   - lib/model/recurrence_rules.dart
   - lib/service/service_locator.dart
 on_exclude:
   - .dart_tool/
   - build/
---

# TaskSwiper Database Skill

You are an expert in Task Swiper's SQLite database layer. Help with queries, schema, and data operations.

## When to Use This Skill

- Working with `DatabaseService`
- Writing or debugging SQL queries
- Adding new tables or columns
- Testing database migrations
- Debugging data persistence issues
- Importing/exporting data

## Database Schema

### Tables

**taskList**
- `id` INTEGER PRIMARY KEY
- `name` TEXT
- `createdAt` TEXT

**task**
- `id` INTEGER PRIMARY KEY
- `task` TEXT
- `status` TEXT (see `Status` enum: open, completed)
- `taskListId` INTEGER (FK to taskList)
- `recurrenceId` INTEGER (FK to recurrenceRules)
- `createdAt` TEXT (ISO8601)
- `updatedAt` TEXT (ISO8601)

**recurrenceRules**
- `id` INTEGER PRIMARY KEY
- `frequency` TEXT (daily, weekly)
- `interval` INTEGER (default: 1)
- `daysOfWeek` TEXT (JSON array of DayOfWeek enum names)
- `endDate` TEXT (ISO8601 date)
- `maxOccurrences` INTEGER
- `timeOfDay` TEXT (HH:mm:ss)

## Core Methods

### DatabaseService

**Initialization**
- `initializeDB()` - Opens database, creates tables if needed
- Schema version: 2 (defined in `version` static field)

**CRUD Operations**
- `createItem(Task task)` - Insert new task, sets createdAt/updatedAt
- `updateTask(Task task)` - Update task, preserves createdAt, updates updatedAt
- `createTasklist(TaskList taskList)` - Insert task list
- `updateTasklist(TaskList taskList)` - Update task list
- `deleteTask(int id)` - Delete task by id
- `deleteTasklist(int id)` - Delete task list by id
- `deleteTasksByTaskList(int taskListId)` - Delete all tasks in a list

**Queries**
- `getTasks(int taskListId)` - Get all tasks for a list
- `getDefaultTaskList()` - Get first task list (for legacy support)
- `getTaskLists()` - Get all task lists
- `getTaskListCompleteness()` - Returns Map<int, bool> of listId -> isComplete
- `getRecurrenceRule(int recurrenceId)` - Get recurrence rule by id
- `getCompletedTasksWithRecurrence()` - JOIN query for completed tasks with recurrence

**Recurrence Rules**
- `saveRecurrenceRule(RecurrenceRules recurrence)` - Insert recurrence rule

## Schema & Migrations

Schema is defined in `lib/service/database_callbacks.dart`:
- `onCreateCallback(db, version)` - Creates all tables
- `onUpgradeCallback(db, oldVersion, newVersion)` - Handles migrations

### Current Schema (version 2)

See `database_callbacks.dart` for exact SQL. Key points:
- Foreign keys: task.recurrenceId -> recurrenceRules.id, task.taskListId -> taskList.id
- No ON DELETE CASCADE (manual cleanup in `deleteTasksByTaskList`)

## Common Tasks

### Run a custom query
```dart
final results = await database.rawQuery('''
  SELECT t.*, r.frequency, r.interval
  FROM task t
  LEFT JOIN recurrenceRules r ON t.recurrenceId = r.id
  WHERE t.taskListId = ?
  ORDER BY t.updatedAt DESC
''', [taskListId]);
```

### Add a new column
1. Add column to model's `toMap()` and `fromMap()`
2. Add column to CREATE TABLE statement in `database_callbacks.dart`
3. Add migration in `onUpgradeCallback` for existing databases
4. Increment version number in `DatabaseService.version`

### Debug data issues
```dart
// Check what's in the database
final allTasks = await database.query('task');
print('All tasks: $allTasks');

final allRecurrence = await database.query('recurrenceRules');
print('All recurrence rules: $allRecurrence');
```

### Test with fresh database
```dart
// In tests, use in-memory database
final db = await database.openInMemory();
// Or use a test path
final testPath = join(await getDatabasesPath(), 'test_task_database.db');
```

## Joins and Complex Queries

The app uses raw SQL for complex queries:

```dart
// Example: getCompletedTasksWithRecurrence()
final results = await database.rawQuery('''
  SELECT t.*, r.id as recurrenceRuleId, r.frequency, r.interval, 
         r.daysOfWeek, r.endDate, r.maxOccurrences, r.timeOfDay
  FROM task t
  INNER JOIN recurrenceRules r ON t.recurrenceId = r.id
  WHERE t.status = ?
''', [Status.completed]);
```

Note: Column names from joined tables are prefixed (e.g., `recurrenceRuleId` from `r.id`).

## Gotchas

- `daysOfWeek` stored as JSON string: `jsonEncode(days.map((e) => e.name).toList())`
- Dates stored as ISO8601 strings in UTC
- `createdAt` and `updatedAt` managed automatically by service methods
- No transaction support in current queries (each operation is standalone)
- Foreign key constraints exist but no CASCADE delete
