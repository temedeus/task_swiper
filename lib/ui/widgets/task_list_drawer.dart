import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/ui/dialogs/add_task_list_dialog.dart';

import '../../model/task_list.dart';
import '../../service/service_locator.dart';

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
    }).catchError((error) {
    });
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
                ...create(selectedTaskListIdProvider),
                SizedBox(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IntrinsicWidth(
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext) => buildDialog());
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

  buildDialog() {
    callback(String text) async {
      var id = await _databaseService.createTasklist(TaskList(null, text));
      setState(() {
        _taskLists = [..._taskLists, TaskList(id, text)];
      });

      Navigator.pop(context);
    }

    return AddTaskListDialog(callback: callback);
  }

  Iterable<ListTile> create(
      SelectedTaskListProvider selectedTaskListIdProvider) {
    return _taskLists.map((i) {
      return ListTile(
          title: Text(i.title),
          selected: i.id == selectedTaskListIdProvider.selectedTasklist?.id,
          onTap: () {
            selectedTaskListIdProvider.setSelectedTaskListId(i);
            Navigator.pop(context);
          });
    });
  }
}
