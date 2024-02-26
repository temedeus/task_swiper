import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:taskswiper/dismiss_task_dialog.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/task.dart';
import 'package:taskswiper/task_item.dart';

import 'edit_task_dialog.dart';

class TaskListing extends StatefulWidget {
  TaskListing({Key? key}) : super(key: key);

  @override
  State<TaskListing> createState() => _TaskListingState();
}

class _TaskListingState extends State<TaskListing> {
  late DatabaseService _databaseService;
  bool _isLoading = true;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _databaseService.initializeDB().whenComplete(() async {
      List<Task> tasks = await _databaseService.getTasks();
      setState(() {
        _tasks = [...tasks];
        _isLoading = false;
      });
    });
  }

  _TaskListingState();

  @override
  build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: buildTaskSlider(),
          );
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
      var id = await _databaseService.createItem(Task(null, text, null));
      setState(() {
        _tasks = [Task(id, text, null), ..._tasks];
      });
      Navigator.pop(context);
    }

    return EditTaskDialog(
      callback: callback,
    );
  }
}
