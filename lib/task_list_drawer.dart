import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/task_list.dart';

class TaskListDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TaskListDrawerState();
}

class _TaskListDrawerState extends State<TaskListDrawer> {
  late DatabaseService _databaseService;
  List<TaskList> _taskLists = [];
  late SelectedTaskListProvider _selectedTaskListProvider;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _databaseService.initializeDB().whenComplete(() async {
      List<TaskList> taskLists = await _databaseService.getTaskLists();
      setState(() {
        _taskLists = [...taskLists];
      });
      _selectedTaskListProvider = Provider.of<SelectedTaskListProvider>(context, listen: false);
      _selectedTaskListProvider.setSelectedTaskListId(_taskLists.first);
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Task lists'),
            ),
            ...create(selectedTaskListIdProvider),
            IconButton(
              icon: const Icon(Icons.add),
              alignment: Alignment.centerLeft,
              tooltip: 'Add tasklist',
              onPressed: () {

              },
            ),
          ],
        );
      }),
    );
  }

  Iterable<ListTile> create(SelectedTaskListProvider selectedTaskListIdProvider) {
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
