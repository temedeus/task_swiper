import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:taskswiper/edit_task_dialog.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/task.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Swiper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Task Swiper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  List<Task> tasks = [Task(null, "Test", null), Task(null, "2", null)];

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DatabaseService _databaseService;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _databaseService.initializeDB().whenComplete(() async {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: buildTaskListing(context));
  }

  Column buildTaskListing(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CarouselSlider(
          options: CarouselOptions(height: 400.0, enableInfiniteScroll: false),
          items: widget.tasks.map((i) {
            return Builder(
              builder: (BuildContext context) {
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
                              color: Colors.black,
                              size: 30.0,
                            ),
                            onPressed: () {
                              setState(() {
                                var newNotes = widget.tasks;
                                newNotes.remove(i);
                                widget.tasks = [...newNotes];
                              });
                            },
                          ),
                          alignment: Alignment.topRight,
                        ),
                        Text(
                          i.task,
                          style: const TextStyle(fontSize: 16.0),
                        )
                      ],
                    ));
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

  buildDialog() {
    callback(String text) async {
      var id = await _databaseService.createItem(Task(null, text, null));
      setState(() {
        widget.tasks = [Task(id, text, null), ...widget.tasks];
      });
      Navigator.pop(context);
    }

    return EditTaskDialog(
      callback: callback,
    );
  }
}
