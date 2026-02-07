import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/model/recurrence_rules.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/recurrence_service.dart';
import 'package:taskswiper/service/service_locator.dart';
import 'package:taskswiper/ui/widgets/task_item.dart';
import 'package:taskswiper/ui/widgets/task_list_selector.dart';

import '../../model/status.dart';
import '../../model/task_list.dart';
import '../dialogs/edit_task_dialog.dart';

class TaskListing extends StatefulWidget {
  TaskListing({Key? key}) : super(key: key);

  @override
  State<TaskListing> createState() => _TaskListingState();
}

class _TaskListingState extends State<TaskListing> with WidgetsBindingObserver {
  late DatabaseService _databaseService;
  List<Task> _tasks = [];
  TaskList? _taskList;
  bool _showCompleted = false;
  bool _initialSetup = true;
  int _refreshKey = 0; // Used to force FutureBuilder refresh

  _TaskListingState();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _databaseService = locator<DatabaseService>();
    _databaseService.getDefaultTaskList().then((taskList) {
      setState(() {
        _taskList = taskList;
      });
    }).catchError((error) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh tasks when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _refreshKey++; // Force FutureBuilder to refresh
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectedTaskListProvider>(
      builder: (context, selectedTaskListProvider, _) {
        final selectedTasklist = selectedTaskListProvider.selectedTasklist;
        _taskList = (selectedTasklist == null || selectedTasklist.id == null) &&
                _initialSetup
            ? _taskList
            : selectedTasklist;

        if (_initialSetup) {
          _initialSetup = false;
        }

        if (_taskList == null || _taskList?.id == null) {
          return const TaskListSelector();
        }
        final taskListId = _taskList?.id;

        return FutureBuilder<List<Task>>(
          future: _databaseService.getTasks(taskListId!),
          key: ValueKey('$_showCompleted-$_refreshKey'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loadingIndicator();
            } else if (snapshot.hasError) {
              return const Center(child: Text("Something went wrong :("));
            } else {
              _tasks = snapshot.data ?? [];

              bool allTasksCompleted = _tasks.isNotEmpty &&
                  _tasks.every((task) => task.status == Status.completed);

              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  buildSwitchWrapper("Show completed", allTasksCompleted),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: buildTaskSlider(allTasksCompleted),
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

  List<Widget> buildTaskSlider(allTasksCompleted) {
    Iterable<Task> tasksToShow = allTasksCompleted || _showCompleted
        ? sortedTasks()
        : sortedTasks().where((task) => task.status == Status.open);
    return [
      _tasks.isEmpty
          ? Center(child: Text("No tasks"))
          : CarouselSlider(
              options:
                  CarouselOptions(height: 400.0, enableInfiniteScroll: false),
              items: tasksToShow.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return buildDismissableTaskItem(context, i);
                  },
                );
              }).toList(),
            ),
      buildAddTaskButton()
    ];
  }

  Widget buildSwitchWrapper(String title, bool disabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Switch(
            value: _showCompleted,
            onChanged: disabled
                ? null
                : (value) {
                    setState(() {
                      _showCompleted = value;
                    });
                  },
          ),
        ],
      ),
    );
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
      }

      return 0;
    });

    return sorted;
  }

  buildDialog(context, {Task? task}) {
    Future<RecurrenceRules?> getRecurrenceFuture() async {
      if (task?.recurrenceId != null) {
        return await _databaseService.getRecurrenceRule(task!.recurrenceId!);
      }
      return null;
    }

    // Callback function to handle task creation or update
    callback(String text, RecurrenceRules? recurrence) async {
      final _taskList = this._taskList;
      if (_taskList != null) {
        int? recurrenceId;
        if (recurrence != null) {
          recurrenceId = await _databaseService.saveRecurrenceRule(recurrence);
        }
        var taskListId = _taskList.id;

        if (task == null) {
          // Create new task
          await _databaseService.createItem(
            Task(null, text, Status.open, taskListId!,
                recurrenceId: recurrenceId),
          );
        } else {
          await _databaseService.updateTask(Task(
            task.id,
            text,
            task.status,
            task.taskListId,
            createdAt: task.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            recurrenceId: recurrenceId ?? task.recurrenceId,
          ));
        }

        // Refresh the FutureBuilder by incrementing the refresh key
        // This forces the FutureBuilder to rebuild with fresh data from the database
        setState(() {
          _refreshKey++;
        });
      }
    }

    return FutureBuilder<RecurrenceRules?>(
      future: getRecurrenceFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return EditTaskDialog(
            callback: callback,
            defaultText: task?.task,
            defaultRecurrence: snapshot.data,
          );
        } else {
          return EditTaskDialog(
            callback: callback,
            defaultText: task?.task,
            defaultRecurrence: null,
          );
        }
      },
    );
  }

  Dismissible buildDismissableTaskItem(BuildContext context, Task i) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.vertical,
      confirmDismiss: (DismissDirection direction) async {
        if (i.status == Status.open) {
          closeTask(i);
          return true;
        }
        return false;
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
          await _databaseService.deleteTask(i.id!),
          setState(() {
            _tasks.remove(i);
          }),
        },
        onReopenTaskPressed: i.status == Status.completed 
            ? reopenTaskCallback(i) 
            : null,
      ),
    );
  }

  reopenTaskCallback(Task task) {
    callback() async {
      late Task _task;
      var updatedTasks = _tasks.map((existingTask) {
        if (existingTask.id == task.id) {
          _task = Task(
            existingTask.id,
            existingTask.task,
            Status.open,
            existingTask.taskListId,
            createdAt: existingTask.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            recurrenceId: existingTask.recurrenceId,
          );
          return _task;
        } else {
          return existingTask;
        }
      }).toList();

      await _databaseService.updateTask(_task);
      
      // Refresh the task list to ensure statuses are correct
      final taskListId = _taskList?.id;
      if (taskListId != null) {
        final refreshedTasks = await _databaseService.getTasks(taskListId);
        setState(() {
          _tasks = refreshedTasks;
          _refreshKey++; // Force FutureBuilder to refresh
        });
      } else {
        setState(() {
          _tasks = updatedTasks;
          _refreshKey++; // Force FutureBuilder to refresh
        });
      }
    }

    return callback;
  }

  closeTask(Task i) async {
    late Task newTask;
    var updatedTasks = _tasks.map((existingTask) {
      if (existingTask.id == i.id) {
        newTask = Task(
          i.id,
          i.task,
          Status.completed,
          i.taskListId,
          createdAt: existingTask.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
          recurrenceId: existingTask.recurrenceId,
        );
        return newTask;
      } else {
        return existingTask;
      }
    }).toList();

    await _databaseService.updateTask(newTask);

    // Check for tasks that should be reopened
    final recurrenceService = locator<RecurrenceService>();
    final reopenedTasks = await recurrenceService.checkAndReopenTasks();

    // Refresh tasks if any were reopened
    if (reopenedTasks.isNotEmpty) {
      final taskListId = _taskList?.id;
      if (taskListId != null) {
        final refreshedTasks = await _databaseService.getTasks(taskListId);
        setState(() {
          _tasks = refreshedTasks;
        });
      }
    } else {
      setState(() {
        _tasks = [...updatedTasks];
      });
    }

    // Show completion notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task completed!'),
      ),
    );

    // Show notification if tasks were reopened
    if (reopenedTasks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reopenedTasks.length == 1
                  ? 'Task reopened: ${reopenedTasks.first}'
                  : '${reopenedTasks.length} tasks have been reopened',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
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
}
