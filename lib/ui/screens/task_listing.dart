import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/ui/dialogs/dismiss_task_dialog.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/ui/widgets/task_item.dart';

import '../dialogs/edit_task_dialog.dart';
import '../../model/task_list.dart';

class TaskListing extends StatefulWidget {
  TaskListing({Key? key}) : super(key: key);

  @override
  State<TaskListing> createState() => _TaskListingState();
}

class _TaskListingState extends State<TaskListing> {
  late DatabaseService _databaseService;
  List<Task> _tasks = [];
  TaskList? _taskList;

  _TaskListingState();

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedTaskListProvider>(
      builder: (context, selectedTaskListProvider, _) {
        final selectedTasklist = selectedTaskListProvider.selectedTasklist;
        if(selectedTasklist == null) {
          loadingIndicator();
        }
        final taskListId = selectedTasklist?.id;

        if (taskListId == null) {
          return loadingIndicator();
        }
        return FutureBuilder<List<Task>>(
          future: _databaseService.getTasks(taskListId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingIndicator();
            } else if (snapshot.hasError) {
              return const Text("Something went wrong :(");
            } else {
              _tasks = snapshot.data ?? [];
              _taskList = selectedTaskListProvider.selectedTasklist;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: buildTaskSlider(),
              );
            }
          },
        );
      },
    );
  }

  Center loadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  List<Widget> buildTaskSlider() {
    return [
      _tasks.isEmpty
          ? const Center(child: Text("No tasks"))
          : CarouselSlider(
              options:
                  CarouselOptions(height: 400.0, enableInfiniteScroll: false),
              items: _tasks.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return buildDismissableTask(context, i);
                  },
                );
              }).toList(),
            ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: () => showDialog<String>(
          context: context,
          builder: (BuildContext context) => buildDialog(),
        ),
        child: const Text('Add task'),
      )
    ];
  }

  Dismissible buildDismissableTask(BuildContext context, Task i) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.vertical,
      onUpdate: (details) {},
      confirmDismiss: (DismissDirection direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            if (direction == DismissDirection.up) {
              return DismissTaskDialog(
                  () => deleteTask(i),
                  "Complete task?",
                  "Are you sure you wish to complete task?",
                  "COMPLETE",
                  "CANCEL");
            } else {
              return DismissTaskDialog(() => deleteTask(i), "Delete task?",
                  "Are you sure you wish to delete task?", "DELETE", "CANCEL");
            }
          },
        );
      },
      child: TaskItem(i),
    );
  }

  deleteTask(i) async {
    await _databaseService.deleteTask(i.id!);

    setState(() {
      var newNotes = _tasks;
      newNotes.remove(i);
      _tasks = [...newNotes];
    });
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted'),
      ),
    );
  }

  buildDialog() {
    callback(String text) async {
      final _taskList = this._taskList;
      if (_taskList != null) {
        var taskListId = _taskList.id;
        var id = await _databaseService
            .createItem(Task(null, text, null, taskListId!));
        setState(() {
          _tasks = [Task(id, text, null, taskListId), ..._tasks];
        });
      }

      Navigator.pop(context);
    }

    return EditTaskDialog(
      callback: callback,
    );
  }
}
