import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/model/task_list.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/service_locator.dart';

import '../../model/status.dart';

class TaskListSelector extends StatelessWidget {
  const TaskListSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final databaseService = locator<DatabaseService>();
    final selectedTaskListProvider = Provider.of<SelectedTaskListProvider>(context);

    return FutureBuilder<List<TaskList>>(
      future: databaseService.getTaskLists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong :("));
        } else {
          final taskLists = snapshot.data ?? [];
          
          // Get task counts for each task list
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getTaskListCounts(databaseService, taskLists),
            builder: (context, countsSnapshot) {
              if (countsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (countsSnapshot.hasError) {
                return const Center(child: Text("Something went wrong :("));
              } else {
                final taskListCounts = countsSnapshot.data ?? [];
                
                // Filter to only show task lists with uncompleted tasks
                final taskListsWithOpenTasks = taskListCounts
                    .where((item) => item['openCount'] > 0)
                    .toList();
                
                if (taskListsWithOpenTasks.isEmpty) {
                  // Check if there are task lists but all are complete
                  if (taskLists.isNotEmpty) {
                    return const Center(
                        child: Text("Well done, every thing is complete!"));
                  } else {
                    return const Center(
                        child: Text("Please select or create new task list!"));
                  }
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: taskListsWithOpenTasks.length,
                  itemBuilder: (context, index) {
                    final item = taskListsWithOpenTasks[index];
                    final taskList = item['taskList'] as TaskList;
                    final openCount = item['openCount'] as int;
                    final totalCount = item['totalCount'] as int;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(taskList.title),
                        subtitle: Text('$openCount out of $totalCount tasks open'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          selectedTaskListProvider.setSelectedTaskListId(taskList);
                        },
                      ),
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getTaskListCounts(
      DatabaseService databaseService, List<TaskList> taskLists) async {
    final List<Map<String, dynamic>> results = [];
    
    for (final taskList in taskLists) {
      if (taskList.id != null) {
        final tasks = await databaseService.getTasks(taskList.id!);
        final openCount = tasks.where((task) => task.status == Status.open).length;
        final totalCount = tasks.length;
        
        results.add({
          'taskList': taskList,
          'openCount': openCount,
          'totalCount': totalCount,
        });
      }
    }
    
    return results;
  }
}

