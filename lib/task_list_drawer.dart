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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _databaseService.initializeDB().whenComplete(() async {
      List<TaskList> taskLists = await _databaseService.getTaskLists();
      setState(() {
        _taskLists = [...taskLists];

        _isLoading = false;
      });
    });
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: Consumer<SelectedTaskListProvider>(
          builder: (context, selectedTaskListIdProvider, _) {
        return ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Task lists'),
            ),
            ...create()
          ],
        );
      }),
    );
  }

  Iterable<ListTile> create() {
    return _taskLists.map((i) {
      return ListTile(
          title: Text(i.title),
          onTap: () {
            _onItemTapped(0);
            Navigator.pop(context);
          });
    });
  }
}
