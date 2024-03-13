import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/ui/dialogs/add_task_list_dialog.dart';

import '../../model/task_list.dart';
import '../../service/service_locator.dart';
import '../dialogs/dismiss_task_dialog.dart';

class TaskListDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListDrawerState();
}

class _TaskListDrawerState extends State<TaskListDrawer> {
  // TODO: refactor database handling up one level from here.
  late DatabaseService _databaseService;
  List<TaskList> _taskLists = [];

  @override
  void initState() {
    super.initState();
    _databaseService = locator<DatabaseService>();

    _databaseService.getTaskLists().then((taskLists) {
      setState(() {
        _taskLists = List<TaskList>.from(taskLists);
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
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text('Task lists'),
              ),
            ),
            ...createTaskListItems(selectedTaskListIdProvider),
            SizedBox(
              child: Align(
                alignment: Alignment.centerLeft,
                child: IntrinsicWidth(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext) => buildCreateTasklistDialog());
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
          ],
        );
      }),
    );
  }

  buildCreateTasklistDialog() {
    callback(String text) async {
      var id = await _databaseService.createTasklist(TaskList(null, text));
      setState(() {
        _taskLists = [..._taskLists, TaskList(id, text)];
      });

      Navigator.pop(context);
    }

    return AddTaskListDialog(callback: callback);
  }

  Iterable<Widget> createTaskListItems(
      SelectedTaskListProvider selectedTaskListProvider) {
    return _taskLists.map((i) {
      return Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text(i.title),
              selected: i.id == selectedTaskListProvider.selectedTasklist?.id,
              onTap: () {
                selectedTaskListProvider.setSelectedTaskListId(i);
                Navigator.pop(context);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              // Handle edit button tap here
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => buildDeleteTasklistConfirmationDialog(
                      i, selectedTaskListProvider));
            },
          ),
        ],
      );
    });
  }

  Widget buildDeleteTasklistConfirmationDialog(
      TaskList taskList, SelectedTaskListProvider selectedTaskListIdProvider) {
    return DismissTaskDialog(() {
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

    List<TaskList> newTaskLists = List.from(_taskLists);
    newTaskLists.remove(taskList);

    setState(() {
      _taskLists = newTaskLists;
    });

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task list "$taskListTitle" deleted'),
      ),
    );
  }
}
