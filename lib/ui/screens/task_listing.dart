import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/service_locator.dart';
import 'package:taskswiper/ui/widgets/task_item.dart';

import '../../model/task_list.dart';
import '../dialogs/dismiss_task_dialog.dart';
import '../dialogs/edit_task_dialog.dart';

class TaskListing extends StatefulWidget {
  TaskListing({Key? key}) : super(key: key);

  @override
  State<TaskListing> createState() => _TaskListingState();
}

class _TaskListingState extends State<TaskListing> {
  // TODO: refactor database handling up one level from here.
  late DatabaseService _databaseService;
  List<Task> _tasks = [];
  TaskList? _taskList;

  _TaskListingState();

  @override
  void initState() {
    super.initState();
    _databaseService = locator<DatabaseService>();
    _databaseService.getDefaultTaskList().then((taskList) {
      setState(() {
        _taskList = taskList;
      });
    }).catchError((error) {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedTaskListProvider>(
      builder: (context, selectedTaskListProvider, _) {
        final selectedTasklist = selectedTaskListProvider.selectedTasklist;
        _taskList = (selectedTasklist == null || selectedTasklist.id == null)
            ? _taskList
            : selectedTasklist;

        if (_taskList == null || _taskList?.id == null) {
          return const Center(
              child: Text("Please select or create new task list!"));
        }
        final taskListId = _taskList?.id;

        return FutureBuilder<List<Task>>(
          future: _databaseService.getTasks(taskListId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingIndicator();
            } else if (snapshot.hasError) {
              return const Center(child: Text("Something went wrong :("));
            } else {
              _tasks = snapshot.data ?? [];
              _taskList = selectedTaskListProvider.selectedTasklist;

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: buildTaskSlider(),
                      ),
                    ),
                  ),
                ],
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
          builder: (BuildContext context) => buildDialog(context),
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
        deleteTask(i);
        return true;
      },
      child: TaskItem(
        i,
        onEditPressed: () async => {
          await showDialog<String>(
            context: context,
            builder: (BuildContext context) => buildDialog(context, task: i),
          ),
        },
        onDeletePressed: () async => {
          await showDialog(
            context: context,
            builder: (BuildContext context) {
              return DismissTaskDialog(() {
                deleteTask(i);
                Navigator.pop(context);
              }, "COMPLETE TASK", "Are you sure you wish to complete task?",
                  "COMPLETE", "CANCEL");
            },
          )
        },
      ),
    );
  }

  deleteTask(i) async {
    await _databaseService.deleteTask(i.id!);

    setState(() {
      var newNotes = _tasks;
      newNotes.remove(i);
      _tasks = [...newNotes];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted'),
      ),
    );
  }

  buildDialog(context, {Task? task}) {
    callback(String text) async {
      if (task == null) {
        final _taskList = this._taskList;
        if (_taskList != null) {
          var taskListId = _taskList.id;
          var id =
              await _databaseService.createItem(Task(null, text, taskListId!));
          setState(() {
            _tasks = [Task(id, text, taskListId), ..._tasks];
          });
        }
      } else {
        var updatedTasks = _tasks.map((existingTask) {
          if (existingTask.id == task.id) {
            return Task(
              existingTask.id,
              text,
              task.taskListId,
            );
          } else {
            return existingTask;
          }
        }).toList();

        await _databaseService.updateTask(Task(task.id, text, task.taskListId));
        setState(() {
          _tasks = updatedTasks;
        });
      }

      Navigator.pop(context);
    }

    return EditTaskDialog(
      callback: callback,
      defaultText: task?.task,
    );
  }
}
