import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/ui/dialogs/add_task_list_dialog.dart';
import 'package:taskswiper/ui/widgets/actionable_icon_button.dart';
import 'package:taskswiper/ui/widgets/separator.dart';

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
    return Drawer(
      child: Consumer<SelectedTaskListProvider>(
          builder: (context, selectedTaskListIdProvider, _) {
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
                child: const Text('Task lists'),
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
                    child: const Row(
                      children: [
                        Text("Add tasklist"),
                        Icon(Icons.add),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SeparatorWithLabel(label: "Completed"),
            ...createTaskListItems(true, selectedTaskListIdProvider),
            const SeparatorWithLabel(label: "General"),
            SizedBox(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => AboutDialog(
                                children: [
                                  Image.asset('assets/logo.png'),
                                ],
                              ));
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: const Row(
                      children: [
                        Text("About"),
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(Icons.info_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
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
