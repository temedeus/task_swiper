import 'package:flutter/material.dart';

import '../model/task_list.dart';

class SelectedTaskListProvider extends ChangeNotifier {
  TaskList? _selectedTasklist;

  TaskList? get selectedTasklist => _selectedTasklist;

  void setSelectedTaskListId(TaskList taskList) {
    _selectedTasklist = taskList;
    notifyListeners();
  }
}