import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/task.dart';

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
        ? const Text("Loading")
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CarouselSlider(
                options:
                    CarouselOptions(height: 400.0, enableInfiniteScroll: false),
                items: _tasks.map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return buildTaskItem(context, i);
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
                child: const Text('Add note'),
              ),
            ],
          );
  }

  Container buildTaskItem(BuildContext context, Task i) {
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.all(15.0),
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[200]!,
              Colors.grey[100]!,
              Colors.grey[200]!,
            ],
            stops: [0.1, 0.5, 0.9],
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.black45,
                  size: 30.0,
                ),
                onPressed: () async {
                  await _databaseService.deleteTask(i.id!);

                  setState(() {
                    var newNotes = _tasks;
                    newNotes.remove(i);
                    _tasks = [...newNotes];
                  });
                },
              ),
              alignment: Alignment.topRight,
            ),
            Text(
              i.task,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
              ),
            )
          ],
        ));
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
