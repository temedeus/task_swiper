---
name: taskswiper-export
description: Data export and import functionality for Task Swiper. Use for working with export/import features, file formats, and data migration.
 aliases: [export, import, backup, restore, migration, data-transfer]
 on_include:
   - lib/service/database_service.dart
   - lib/model/task.dart
   - lib/model/task_list.dart
   - lib/model/recurrence_rules.dart
   - lib/main.dart
   - lib/ui/
 on_exclude:
   - .dart_tool/
   - build/
---

# TaskSwiper Export Skill

You are an expert in Task Swiper's data export and import system. Help with data migration, backup/restore, and file-based data operations.

## When to Use This Skill

- Working on export functionality
- Working on import functionality
- Testing data migration
- Debugging export/import issues
- Adding new export formats
- Handling file I/O operations

## Current Export/Import Status

Based on the codebase inspection, export/import functionality appears to be **partially implemented**:
- `file_picker` and `path_provider` dependencies are in `pubspec.yaml`
- No dedicated export service found in current code
- Likely needs implementation or is in early stages

## Dependencies Available

From `pubspec.yaml`:
```yaml
  file_picker: ^6.1.1        # For picking files
  path_provider: ^2.1.1     # For getting app directories
  path: ^1.8.0              # For path manipulation
```

## Potential Implementation Approach

### Export Service Structure

A dedicated export service could be created:

```dart
// lib/service/export_service.dart
class ExportService {
  final DatabaseService _databaseService;
  
  ExportService(this._databaseService);
  
  // Export all data to JSON file
  Future<File> exportAllData({required String directoryPath}) async {
    final data = await _collectAllData();
    final json = jsonEncode(data);
    final file = File('$directoryPath/taskswiper_export_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    return file;
  }
  
  // Import from JSON file
  Future<void> importData(File file) async {
    final json = await file.readAsString();
    final data = jsonDecode(json) as Map<String, dynamic>;
    await _restoreAllData(data);
  }
}
```

### Export Data Structure

```json
{
  "version": 1,
  "exportedAt": "2024-01-15T10:30:00.000Z",
  "taskLists": [
    {
      "id": 1,
      "name": "Personal",
      "createdAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "tasks": [
    {
      "id": 1,
      "task": "Buy groceries",
      "status": "open",
      "taskListId": 1,
      "recurrenceId": null,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "recurrenceRules": [
    {
      "id": 1,
      "frequency": "daily",
      "interval": 1,
      "daysOfWeek": null,
      "endDate": null,
      "maxOccurrences": null,
      "timeOfDay": "09:00:00"
    }
  ]
}
```

## Common Tasks

### Implement basic export

```dart
Future<Map<String, dynamic>> _collectAllData() async {
  final taskLists = await _databaseService.getTaskLists();
  final allTasks = <Task>[];
  
  for (final list in taskLists) {
    final tasks = await _databaseService.getTasks(list.id!);
    allTasks.addAll(tasks);
  }
  
  // Get all recurrence rules that are referenced
  final recurrenceIds = allTasks
      .where((t) => t.recurrenceId != null)
      .map((t) => t.recurrenceId!)
      .toSet();
  
  final recurrenceRules = <RecurrenceRules>[];
  for (final id in recurrenceIds) {
    final rule = await _databaseService.getRecurrenceRule(id);
    if (rule != null) {
      recurrenceRules.add(rule);
    }
  }
  
  return {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'taskLists': taskLists.map((e) => e.toMap()).toList(),
    'tasks': allTasks.map((e) => e.toMap()).toList(),
    'recurrenceRules': recurrenceRules.map((e) => e.toMap()).toList(),
  };
}
```

### Implement basic import

```dart
Future<void> _restoreAllData(Map<String, dynamic> data) async {
  final version = data['version'] as int? ?? 1;
  
  // Handle different versions if needed
  switch (version) {
    case 1:
      await _importVersion1(data);
      break;
    default:
      throw Exception('Unsupported export version: $version');
  }
}

Future<void> _importVersion1(Map<String, dynamic> data) async {
  final taskListsData = data['taskLists'] as List? ?? [];
  final tasksData = data['tasks'] as List? ?? [];
  final recurrenceRulesData = data['recurrenceRules'] as List? ?? [];
  
  // First, import recurrence rules (tasks may reference them)
  for (final ruleData in recurrenceRulesData) {
    final rule = RecurrenceRules.fromMap(ruleData as Map<String, dynamic>);
    // Use replace to handle existing IDs
    await _databaseService.database.insert(
      'recurrenceRules',
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Then import task lists
  for (final listData in taskListsData) {
    final list = TaskList.fromMap(listData as Map<String, dynamic>);
    await _databaseService.createTasklist(list);
  }
  
  // Finally import tasks
  for (final taskData in tasksData) {
    final task = Task.fromMap(taskData as Map<String, dynamic>);
    await _databaseService.createItem(task);
  }
}
```

### Pick export file location

```dart
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

// Let user choose directory
final directory = await FilePicker.platform.getDirectoryPath();

// Or use default documents directory
final dir = await getApplicationDocumentsDirectory();
final exportPath = dir.path;
```

### Export file naming

```dart
String generateExportFilename() {
  final now = DateTime.now();
  final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
  return 'taskswiper_backup_${formatter.format(now)}.json';
}
```

## File Formats

### JSON (Recommended)
- Human-readable
- Easy to debug
- Good for manual editing
- Standard format for data interchange

### Custom Binary
- Smaller file size
- Not human-readable
- Faster to parse
- Harder to debug

## Testing Export/Import

### Round-trip test

```dart
Future<void> testExportImportRoundTrip() async {
  // Create test data
  final taskList = TaskList(null, 'Test List');
  final listId = await _databaseService.createTasklist(taskList);
  
  final task = Task(null, 'Test task', Status.open, listId);
  await _databaseService.createItem(task);
  
  // Export
  final exportService = ExportService(_databaseService);
  final tempDir = await getTemporaryDirectory();
  final exportFile = await exportService.exportAllData(
    directoryPath: tempDir.path,
  );
  
  // Clear database
  await _databaseService.deleteTasklist(listId);
  
  // Import
  await exportService.importData(exportFile);
  
  // Verify
  final restoredLists = await _databaseService.getTaskLists();
  assert(restoredLists.length == 1);
  assert(restoredLists.first.name == 'Test List');
  
  final restoredTasks = await _databaseService.getTasks(restoredLists.first.id!);
  assert(restoredTasks.length == 1);
  assert(restoredTasks.first.task == 'Test task');
}
```

## Error Handling

```dart
try {
  await exportService.importData(file);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Import successful!')),
  );
} on FormatException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Invalid file format: ${e.message}')),
  );
} on Exception catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Import failed: ${e.toString()}')),
  );
}
```

## UI Integration

### Export button in settings

```dart
ListTile(
  leading: Icon(Icons.download),
  title: Text('Export Data'),
  onTap: () async {
    try {
      final exportService = locator<ExportService>();
      final directory = await FilePicker.platform.getDirectoryPath();
      if (directory != null) {
        final file = await exportService.exportAllData(directoryPath: directory);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  },
)
```

### Import button in settings

```dart
ListTile(
  leading: Icon(Icons.upload),
  title: Text('Import Data'),
  onTap: () async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        final exportService = locator<ExportService>();
        await exportService.importData(file);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data imported successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: ${e.toString()}')),
      );
    }
  },
)
```

## Gotchas

- **ID conflicts**: Use `ConflictAlgorithm.replace` or handle duplicates
- **Version compatibility**: Always include version in export, handle old versions
- **File permissions**: On mobile, need proper permissions for file access
- **Large exports**: Consider compression for large datasets
- **Character encoding**: Ensure UTF-8 encoding for special characters
- **Date formats**: Use ISO8601 for date strings
- **Null handling**: Some fields may be null in older exports

## Future Enhancements

1. **Selective export**: Export specific task lists instead of all data
2. **Incremental backup**: Track changes for incremental exports
3. **Cloud sync**: Google Drive, iCloud, Dropbox integration
4. **Scheduled backups**: Automatic periodic backups
5. **Multiple formats**: CSV, XML options
6. **Encryption**: Password-protect sensitive data
7. **Preview**: Show preview before import
8. **Conflict resolution**: UI for handling duplicate items
