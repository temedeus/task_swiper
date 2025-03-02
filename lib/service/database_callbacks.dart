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
}

Future<void> onUpgradeCallback(Database database, int oldVersion, int newVersion) async {
  if (oldVersion < 3) {
    // Add recurrence_id column to link tasks to recurrence rules
    await database.execute('ALTER TABLE task ADD COLUMN recurrence_id INTEGER');

    // Create recurrence_rules table
    await database.execute('''
      CREATE TABLE recurrence_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequency TEXT CHECK (frequency IN ('daily', 'weekly', 'monthly', 'custom')),
        interval INTEGER DEFAULT 1,
        days_of_week TEXT,  -- Comma-separated values (e.g., 'mon,wed')
        start_date DATETIME NOT NULL,
        end_date DATETIME,
        max_occurrences INTEGER,
        time_of_day TIME
      )
    ''');
  }
}
