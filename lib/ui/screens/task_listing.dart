import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/service_locator.dart';
import 'package:taskswiper/ui/widgets/task_item.dart';

import '../../model/status.dart';
import '../../model/task_list.dart';
import '../dialogs/confirm_dialog.dart';
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
    bool allTasksCompleted = _tasks.every((task) => task.status == Status.closed);
    String statusText = allTasksCompleted ? "All tasks completed!" : "No tasks";
    return  [
      _tasks.isEmpty || allTasksCompleted
          ? Center(child: Text(statusText))
          : CarouselSlider(
              options:
                  CarouselOptions(height: 400.0, enableInfiniteScroll: false),
              items: sortedTasks()
                  .where((task) => task.status == Status.open)
                  .map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return buildDismissableTask(context, i);
                  },
                );
              }).toList(),
            ),
      buildAddTaskButton()
    ];
  }

  ElevatedButton buildAddTaskButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20),
      ),
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => buildDialog(context),
      ),
      child: const Text('Add task'),
    );
  }

  List<Task> sortedTasks() {
    List<Task> sorted = [..._tasks];
    sorted.sort((a, b) {
      if (a.status == Status.open && b.status != Status.open) {
        return -1;
      } else if (a.status != Status.open && b.status == Status.open) {
        return 1;
      } else {
        return 0;
      }
    });

    return sorted;
  }

  Dismissible buildDismissableTask(BuildContext context, Task i) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.vertical,
      onUpdate: (details) {},
      confirmDismiss: (DismissDirection direction) async {
        closeTask(i);
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
              return ConfirmDialog(() {
                deleteTask(i);
                Navigator.pop(context);
              }, "DELETE TASK", "Are you sure you wish to delete task?",
                  "DELETE", "CANCEL");
            },
          )
        },
      ),
    );
  }

  closeTask(Task i) async {
    late Task newTask;
    var updatedTasks = _tasks.map((existingTask) {
      if (existingTask.id == i.id) {
        newTask = Task(
          i.id,
          i.task,
          Status.closed,
          i.taskListId,
        );
        return newTask;
      } else {
        return existingTask;
      }
    }).toList();

    await _databaseService.updateTask(newTask);

    setState(() {
      _tasks = [...updatedTasks];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task completed!'),
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
          var id = await _databaseService
              .createItem(Task(null, text, Status.open, taskListId!));
          setState(() {
            _tasks = [Task(id, text, Status.open, taskListId), ..._tasks];
          });
        }
      } else {
        var updatedTasks = _tasks.map((existingTask) {
          if (existingTask.id == task.id) {
            return Task(
              existingTask.id,
              text,
              existingTask.status,
              task.taskListId,
            );
          } else {
            return existingTask;
          }
        }).toList();

        await _databaseService
            .updateTask(Task(task.id, text, Status.open, task.taskListId));
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
