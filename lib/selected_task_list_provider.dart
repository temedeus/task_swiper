import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/task_list.dart';

class SelectedTaskListProvider extends ChangeNotifier {
  late TaskList _selectedTasklist;

  TaskList get selectedTasklist => _selectedTasklist;

  void setSelectedTaskListId(TaskList taskList) {
    _selectedTasklist = taskList;
    notifyListeners();
  }
}