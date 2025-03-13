import 'package:sqflite/sqflite.dart';
import '../model/status.dart';

Future<void> onCreateCallback(Database database, int version) async {
  // Create tables
  await database.execute(
    "CREATE TABLE taskList(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL)",
  );
  await database.execute(
    "CREATE TABLE task(id INTEGER PRIMARY KEY AUTOINCREMENT, "
        "task TEXT NOT NULL, status TEXT NOT NULL, taskListId INTEGER NOT NULL, "
        "FOREIGN KEY(taskListId) REFERENCES taskList(id))",
  );

  // Insert default task list
  int id = await database.rawInsert(
    "INSERT INTO taskList (title) VALUES ('Untitled list');",
  );

  // Insert default task
  await database.execute(
    "INSERT INTO task (task, status, taskListId) VALUES ('Start using Task Swiper!\n\n" +
        "Create new lists from the menu on the right.\n\n" +
        "+ Swipe task up or down to complete\n\n" +
        "', ?, ?);",
    [Status.open, id],
  );

  onUpgradeCallback(database, 0, version);
}

Future<void> onUpgradeCallback(Database database, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // Add recurrence_id column to link tasks to recurrence rules
    await database.execute('ALTER TABLE task ADD COLUMN recurrenceId INTEGER');

    // Create recurrence_rules.dart table
    await database.execute('''
      CREATE TABLE recurrenceRules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'monthly', 'custom')),
        interval INTEGER DEFAULT 1,
        daysOfWeek TEXT,  -- Comma-separated values (e.g., 'mon,wed')
        endDate DATETIME,
        maxOccurrences INTEGER,
        timeOfDay TIME
      )
    ''');
  }
}
