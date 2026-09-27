import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/model/status.dart';
import 'package:taskswiper/model/recurrence_rules.dart';
import 'package:taskswiper/model/recurrence_frequency.dart';
import 'package:taskswiper/model/day_of_week.dart';
import 'package:taskswiper/service/database_service.dart';
import 'package:taskswiper/service/command_parser.dart';
import 'package:taskswiper/service/voice_service.dart';
import 'package:taskswiper/providers/selected_task_list_provider.dart';

/// Main handler for processing voice commands and executing task actions.
/// Works with CommandParser and VoiceService to provide a complete
/// voice command interface for Task Swiper.
/// 
/// Architecture:
/// Speech-to-text → CommandParser → structured AppCommand → app action
class TaskAiHandler {
  final VoiceService _voice;
  final CommandParser _parser;
  final DatabaseService _db;
  final BuildContext _context;

  TaskAiHandler({
    required VoiceService voice,
    CommandParser? parser,
    required DatabaseService db,
    required BuildContext context,
  })  : _voice = voice,
        _parser = parser ?? CommandParser(),
        _db = db,
        _context = context;

  /// Main entry point: listen and handle voice command
  Future<void> handleVoiceCommand() async {
    // 1. Listen for voice input
    final text = await _voice.listen();
    if (text == null || text.isEmpty) {
      await _voice.speak("I didn't hear anything. Try again.");
      return;
    }

    // 2. Parse command using CommandParser
    final command = _parser.parse(text);
    if (command == null) {
      await _voice.speak("Sorry, I didn't understand that. Try: Add buy milk, or List tasks.");
      return;
    }

    // 3. Handle based on command type
    switch (command.type) {
      case CommandType.create:
        await _handleCreate(command);
        break;
      case CommandType.complete:
        await _handleComplete(command);
        break;
      case CommandType.delete:
        await _handleDelete(command);
        break;
      case CommandType.list:
        await _handleList(command);
        break;
      case CommandType.update:
        await _handleUpdate(command);
        break;
    }
  }

  // ========== HANDLERS ==========

  /// Get the current task list ID from the provider
  int? _getCurrentTaskListId() {
    final provider = Provider.of<SelectedTaskListProvider>(_context, listen: false);
    return provider.selectedTasklist?.id;
  }

  /// Handle CREATE command
  Future<void> _handleCreate(AppCommand command) async {
    if (command.title == null || command.title!.isEmpty) {
      await _voice.speak("What task would you like to add?");
      return;
    }

    final taskListId = _getCurrentTaskListId();
    if (taskListId == null) {
      await _voice.speak("No task list selected");
      return;
    }
    
    // Create the task with optional recurrence
    final task = Task(
      null,
      command.title!,
      Status.open,
      taskListId,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
      recurrenceId: null, // Will be set if recurrence is implemented
    );

    await _db.createItem(task);
    
    // If recurrence was specified, confirm it
    if (command.recurrence != null) {
      await _voice.speak("Added: ${command.title!} with recurrence. Recurrence: ${_describeRecurrence(command.recurrence!)}");
    } else {
      await _voice.speak("Added: ${command.title!}");
    }
  }

  /// Describe recurrence for speech
  String _describeRecurrence(RecurrenceRules recurrence) {
    final parts = <String>[];
    
    switch (recurrence.frequency) {
      case RecurrenceFrequency.daily:
        parts.add('every ${recurrence.interval} day');
        break;
      case RecurrenceFrequency.weekly:
        parts.add('every ${recurrence.interval} week');
        if (recurrence.daysOfWeek != null && recurrence.daysOfWeek!.isNotEmpty) {
          parts.add('on ${recurrence.daysOfWeek!.map((d) => _dayOfWeekToString(d)).join(", ")}');
        }
        break;
    }
    
    if (recurrence.timeOfDay != null) {
      parts.add('at ${recurrence.timeOfDay}');
    }
    
    return parts.join(' ');
  }

  String _dayOfWeekToString(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon: return 'Monday';
      case DayOfWeek.tue: return 'Tuesday';
      case DayOfWeek.wed: return 'Wednesday';
      case DayOfWeek.thu: return 'Thursday';
      case DayOfWeek.fri: return 'Friday';
      case DayOfWeek.sat: return 'Saturday';
      case DayOfWeek.sun: return 'Sunday';
    }
    return 'Unknown';
  }

  /// Handle COMPLETE command
  Future<void> _handleComplete(AppCommand command) async {
    if (command.title == null || command.title!.isEmpty) {
      await _voice.speak("Which task would you like to mark as complete?");
      return;
    }

    final taskListId = _getCurrentTaskListId();
    if (taskListId == null) {
      await _voice.speak("No task list selected");
      return;
    }
    final tasks = await _db.getTasks(taskListId);
    final matchingTask = _findBestMatch(command.title!, tasks);
    
    if (matchingTask == null) {
      await _voice.speak("I couldn't find a task matching ${command.title!}");
      return;
    }

    final updatedTask = Task(
      matchingTask.id,
      matchingTask.task,
      Status.completed,
      matchingTask.taskListId,
      createdAt: matchingTask.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      recurrenceId: matchingTask.recurrenceId,
    );

    await _db.updateTask(updatedTask);
    await _voice.speak("Marked ${matchingTask.task} as complete");
  }

  /// Handle DELETE command
  Future<void> _handleDelete(AppCommand command) async {
    if (command.title == null || command.title!.isEmpty) {
      await _voice.speak("Which task would you like to delete?");
      return;
    }

    final taskListId = _getCurrentTaskListId();
    if (taskListId == null) {
      await _voice.speak("No task list selected");
      return;
    }
    final tasks = await _db.getTasks(taskListId);
    final matchingTask = _findBestMatch(command.title!, tasks);
    
    if (matchingTask == null) {
      await _voice.speak("I couldn't find a task matching ${command.title!}");
      return;
    }

    await _db.deleteTask(matchingTask.id!);
    await _voice.speak("Deleted ${matchingTask.task}");
  }

  /// Handle UPDATE command
  Future<void> _handleUpdate(AppCommand command) async {
    if (command.oldTitle == null || command.newTitle == null) {
      await _voice.speak("I need both the old and new task names to update.");
      return;
    }

    final taskListId = _getCurrentTaskListId();
    if (taskListId == null) {
      await _voice.speak("No task list selected");
      return;
    }
    final tasks = await _db.getTasks(taskListId);
    final matchingTask = _findBestMatch(command.oldTitle!, tasks);
    
    if (matchingTask == null) {
      await _voice.speak("I couldn't find a task matching ${command.oldTitle!}");
      return;
    }

    final updatedTask = Task(
      matchingTask.id,
      command.newTitle!,
      matchingTask.status,
      matchingTask.taskListId,
      createdAt: matchingTask.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      recurrenceId: matchingTask.recurrenceId,
    );

    await _db.updateTask(updatedTask);
    await _voice.speak("Updated ${matchingTask.task} to ${command.newTitle!}");
  }

  /// Handle LIST command
  Future<void> _handleList(AppCommand command) async {
    final taskListId = _getCurrentTaskListId();
    if (taskListId == null) {
      await _voice.speak("No task list selected");
      return;
    }
    final allTasks = await _db.getTasks(taskListId);

    List<Task> filteredTasks;

    switch (command.filter) {
      case TaskFilter.open:
        filteredTasks = allTasks.where((t) => t.status == Status.open).toList();
        break;
      case TaskFilter.completed:
        filteredTasks = allTasks.where((t) => t.status == Status.completed).toList();
        break;
      case TaskFilter.all:
        filteredTasks = allTasks;
        break;
      case TaskFilter.specificList:
        // Would need to extract list name and get that list's tasks
        filteredTasks = allTasks;
        break;
      case null:
        // Default to open tasks
        filteredTasks = allTasks.where((t) => t.status == Status.open).toList();
        break;
    }

    if (filteredTasks.isEmpty) {
      final message = _getEmptyMessage(command.filter);
      await _voice.speak(message);
      return;
    }

    // Format and speak the list
    final speechText = _formatTaskListSpeech(filteredTasks, command.filter);
    await _voice.speak(speechText);

    // Show in UI
    _showTaskListDialog(filteredTasks, command.filter);
  }

  // ========== HELPERS ==========

  /// Find best matching task from text
  Task? _findBestMatch(String searchText, List<Task> tasks) {
    if (tasks.isEmpty) return null;
    
    // Try exact match first
    for (final task in tasks) {
      if (task.task.toLowerCase() == searchText.toLowerCase()) {
        return task;
      }
    }
    
    // Try substring match
    for (final task in tasks) {
      if (task.task.toLowerCase().contains(searchText.toLowerCase())) {
        return task;
      }
    }
    
    // Use word similarity
    try {
      return tasks.firstWhere(
        (task) => _calculateMatchScore(task.task, searchText) > 0.5,
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate match score between two strings (0-1)
  double _calculateMatchScore(String taskText, String searchText) {
    final taskWords = taskText.toLowerCase().split(RegExp(r'\W+'));
    final searchWords = searchText.toLowerCase().split(RegExp(r'\W+'));
    
    if (searchWords.isEmpty) return 0.0;
    
    final matchingWords = taskWords.where((word) => searchWords.contains(word)).length;
    final score = matchingWords / searchWords.length;
    
    return score.clamp(0.0, 1.0);
  }

  /// Get empty list message based on filter
  String _getEmptyMessage(TaskFilter? filter) {
    switch (filter) {
      case TaskFilter.open:
        return "You have no open tasks";
      case TaskFilter.completed:
        return "You have no completed tasks";
      case TaskFilter.all:
        return "You have no tasks";
      default:
        return "No tasks found";
    }
  }

  /// Format task list for speech
  String _formatTaskListSpeech(List<Task> tasks, TaskFilter? filter) {
    final count = tasks.length;
    final filterName = _getFilterName(filter);
    
    if (count == 0) {
      return _getEmptyMessage(filter);
    }

    // Limit to first 5 tasks for speech
    final taskNames = tasks.take(5).map((t) => t.task).join(", ");
    
    if (count > 5) {
      return "You have $count $filterName tasks. First five: $taskNames, and ${count - 5} more.";
    } else if (count == 1) {
      return "You have 1 $filterName task: $taskNames.";
    } else {
      return "You have $count $filterName tasks: $taskNames.";
    }
  }

  /// Get filter name for speech
  String _getFilterName(TaskFilter? filter) {
    switch (filter) {
      case TaskFilter.open:
        return "open";
      case TaskFilter.completed:
        return "completed";
      case TaskFilter.all:
        return "total";
      default:
        return "";
    }
  }

  /// Show task list in dialog
  void _showTaskListDialog(List<Task> tasks, TaskFilter? filter) {
    final filterName = _getFilterName(filter);
    final title = filterName.isEmpty ? "Tasks" : "$filterName Tasks";
    
    showDialog(
      context: _context,
      builder: (context) => AlertDialog(
        title: Text("$title (${tasks.length})"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.task),
                trailing: Text(_getStatusText(task.status)),
                onTap: () => Navigator.of(context).pop(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  /// Get status text for display
  String _getStatusText(String status) {
    switch (status) {
      case Status.open:
        return "Open";
      case Status.completed:
        return "Done";
      default:
        return status;
    }
  }
}
