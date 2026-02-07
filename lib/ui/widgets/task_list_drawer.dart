import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/providers/language_provider.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/ui/dialogs/add_task_list_dialog.dart';
import 'package:taskswiper/ui/widgets/about_app_dialog.dart';
import 'package:taskswiper/ui/widgets/actionable_icon_button.dart';
import 'package:taskswiper/ui/widgets/separator.dart';

import '../../model/status.dart';
import '../../model/task_list.dart';
import '../../service/service_locator.dart';
import '../dialogs/confirm_dialog.dart';

class TaskListDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListDrawerState();
}

class _TaskListDrawerState extends State<TaskListDrawer> {
  // TODO: refactor database handling up one level from here.
  late DatabaseService _databaseService;
  List<TaskList> _openTasklists = [];
  List<TaskList> _closedTasklists = [];

  @override
  void initState() {
    super.initState();
    _databaseService = locator<DatabaseService>();

    _databaseService.getTaskLists().then((taskLists) {
      _databaseService.getTaskListCompleteness().then((taskListCompleteness) {
        Map<int, bool> _taskListCompleteness = taskListCompleteness;

        List<TaskList> openTasklists = [];
        List<TaskList> closedTasklists = [];

        for (var taskList in taskLists) {
          if (_taskListCompleteness[taskList.id] == false) {
            openTasklists.add(taskList);
          } else {
            closedTasklists.add(taskList);
          }
        }

        setState(() {
          _openTasklists = List<TaskList>.from(openTasklists);
          _closedTasklists = List<TaskList>.from(closedTasklists);
        });
      });
    }).catchError((error) {});
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Drawer(
      child: Consumer<SelectedTaskListProvider>(
          builder: (context, selectedTaskListIdProvider, _) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 100,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[400]!,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(localizations.taskLists),
              ),
            ),
            ...createTaskListItems(false, selectedTaskListIdProvider),
            SizedBox(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              buildEditTasklistDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: Row(
                      children: [
                        Text(localizations.addTasklist),
                        const Icon(Icons.add),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SeparatorWithLabel(label: localizations.completed),
            ...createTaskListItems(true, selectedTaskListIdProvider),
            SeparatorWithLabel(label: localizations.general),
            // Language selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    localizations.language,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  DropdownButton<Locale>(
                    value: languageProvider.locale,
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('fi'),
                        child: Text('Suomi'),
                      ),
                    ],
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        languageProvider.setLocale(newLocale);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Export / Import tasks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ElevatedButton(
                onPressed: () => _exportTasks(context, selectedTaskListIdProvider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    const Text('Export tasks'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: ElevatedButton(
                onPressed: () => _importTasks(context, selectedTaskListIdProvider),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.upload),
                    const SizedBox(width: 8),
                    const Text('Import tasks'),
                  ],
                ),
              ),
            ),
            SizedBox(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      selectedTaskListIdProvider.deselectSelectedTaskList();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: Row(
                      children: [
                        Text(localizations.showUncompleted),
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.list),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              AboutAppDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: buildAboutButton(localizations),
                  ),
                ),
              ),
            ),
          ],
        );
          },
        );
      }),
    );
  }

  Row buildAboutButton(AppLocalizations localizations) {
    return Row(
      children: [
        Text(localizations.about),
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Icon(Icons.info_outline),
        ),
      ],
    );
  }

  Future<void> _exportTasks(
      BuildContext context, SelectedTaskListProvider selectedTaskListProvider) async {
    final taskList = selectedTaskListProvider.selectedTasklist;
    if (taskList == null || taskList.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a task list first')),
      );
      return;
    }

    try {
      final tasks = await _databaseService.getTasks(taskList.id!);
      final exportData = tasks.map((t) => t.toMap()).toList();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);

      // Get the appropriate directory (Downloads on desktop, Documents on mobile)
      Directory? directory;
      if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For desktop platforms, try to get Downloads directory
        final downloadsPath = Platform.environment['HOME'] ?? 
                              Platform.environment['USERPROFILE'] ?? '';
        if (downloadsPath.isNotEmpty) {
          directory = Directory('$downloadsPath/Downloads');
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final filename = 'task_swiper_export_${taskList.title.replaceAll(RegExp(r'[^\w\s-]'), '_')}_$timestamp.json';
      final file = File('${directory.path}/$filename');

      await file.writeAsString(jsonStr);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tasks exported to: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting tasks: $e')),
      );
    }
  }

  Future<void> _importTasks(
      BuildContext context, SelectedTaskListProvider selectedTaskListProvider) async {
    final taskList = selectedTaskListProvider.selectedTasklist;
    if (taskList == null || taskList.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a task list first')),
      );
      return;
    }

    try {
      // Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final jsonData = jsonDecode(jsonStr) as List;
      
      int importedCount = 0;

      for (final item in jsonData) {
        final taskMap = item as Map<String, dynamic>;
        final task = Task(
          null, // New task, no ID
          taskMap['task'] as String? ?? '',
          taskMap['status'] as String? ?? Status.open,
          taskList.id!,
          recurrenceId: taskMap['recurrenceId'] as int?,
        );
        await _databaseService.createItem(task);
        importedCount++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $importedCount task(s)')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing tasks: $e')),
      );
    }
  }

  buildEditTasklistDialog({TaskList? taskList}) {
    callback(String text) async {
      if (taskList == null) {
        // Create a new task list
        var id = await _databaseService.createTasklist(TaskList(null, text));
        setState(() {
          _openTasklists = [..._openTasklists, TaskList(id, text)];
        });
      } else {
        late TaskList taskListToUpdate;
        var updatedTaskLists = _openTasklists.map((existingTaskList) {
          if (existingTaskList.id == taskList.id) {
            taskListToUpdate = TaskList(
              existingTaskList.id,
              text,
            );
            return taskListToUpdate;
          } else {
            return existingTaskList;
          }
        }).toList();

        await _databaseService.updateTasklist(taskListToUpdate);
        setState(() {
          _openTasklists = updatedTaskLists;
        });
      }
      Navigator.pop(context);
      Navigator.of(context);
    }

    return AddTaskListDialog(callback: callback, defaultText: taskList?.title);
  }

  Iterable<Widget> createTaskListItems(
      bool isClosed, SelectedTaskListProvider selectedTaskListProvider) {
    var items = isClosed ? _closedTasklists : _openTasklists;
    return items.map((taskList) {
      return Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text(taskList.title),
              selected:
                  taskList.id == selectedTaskListProvider.selectedTasklist?.id,
              onTap: () {
                selectedTaskListProvider.setSelectedTaskListId(taskList);
                Navigator.pop(context);
              },
            ),
          ),
          ActionableIconButton(
            Icons.edit,
            () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      buildEditTasklistDialog(taskList: taskList));
            },
            disabled: isClosed,
          ),
          ActionableIconButton(
              Icons.delete,
              () => showDialog(
                  context: context,
                  builder: (context) => buildDeleteTasklistConfirmationDialog(
                      taskList, selectedTaskListProvider)))
        ],
      );
    });
  }

  Widget buildDeleteTasklistConfirmationDialog(
      TaskList taskList, SelectedTaskListProvider selectedTaskListIdProvider) {
    return ConfirmDialog(() {
      deleteTasklist(taskList, selectedTaskListIdProvider);
    }, "DELETE TASKLIST", "Are you sure you wish to delete task list?",
        "DELETE", "CANCEL");
  }

  deleteTasklist(TaskList taskList,
      SelectedTaskListProvider selectedTaskListProvider) async {
    await _databaseService.deleteTasksByTaskList(taskList.id!);

    final id = taskList.id;
    final taskListTitle = taskList.title;

    await _databaseService.deleteTasklist(id!);
    selectedTaskListProvider.deselectSelectedTaskList();

    List<TaskList> updatedOpenTaskLists = List.from(_openTasklists);
    List<TaskList> updatedClosedTaskLists = List.from(_closedTasklists);

    updatedOpenTaskLists.remove(taskList);
    updatedClosedTaskLists.remove(taskList);

    setState(() {
      _openTasklists = updatedOpenTaskLists;
      _closedTasklists = updatedClosedTaskLists;
    });

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task list "$taskListTitle" deleted'),
      ),
    );
  }
}
