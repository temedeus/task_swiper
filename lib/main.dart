import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/recurrence_service.dart';
import 'package:taskswiper/service/service_locator.dart';
import 'package:taskswiper/ui/screens/task_listing.dart';
import 'package:taskswiper/ui/widgets/task_list_drawer.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Swiper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
          create: (context) => SelectedTaskListProvider(),
          child: MyHomePage(title: 'Task Swiper')),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    locator<DatabaseService>().initializeDB().whenComplete(
          () async {
            // Check for tasks that should be reopened
            await _checkAndNotifyRecurrence();
            
            setState(
              () {
                isReady = true;
              },
            );
          },
        );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Check for recurrence when app comes back to foreground
    if (state == AppLifecycleState.resumed && isReady) {
      _checkAndNotifyRecurrence();
    }
  }

  /// Check for tasks that should be reopened and show notification
  Future<void> _checkAndNotifyRecurrence() async {
    final recurrenceService = locator<RecurrenceService>();
    final reopenedTasks = await recurrenceService.checkAndReopenTasks();
    
    // Show notification if tasks were reopened
    if (reopenedTasks.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
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
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: isReady
            ? TaskListing()
            : Center(
                child: Text("Starting up..."),
              ),
        drawer: TaskListDrawer());
  }
}
