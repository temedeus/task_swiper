import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/model/recurrence_rules.dart';
import 'package:taskswiper/model/recurrence_frequency.dart';
import 'package:taskswiper/model/day_of_week.dart';
import 'package:taskswiper/model/status.dart';
import 'package:taskswiper/service/database_service.dart';

class RecurrenceService {
  final DatabaseService _databaseService;

  RecurrenceService(this._databaseService);

  /// Check and reopen tasks based on recurrence rules
  /// Returns list of task texts that were reopened
  Future<List<String>> checkAndReopenTasks() async {
    final completedTasks = await _databaseService.getCompletedTasksWithRecurrence();
    final now = DateTime.now();
    final List<String> reopenedTaskTexts = [];

    for (final taskData in completedTasks) {
      final task = Task.fromMap(taskData);
      final updatedAt = task.updatedAt != null 
          ? DateTime.parse(task.updatedAt!) 
          : null;

      if (updatedAt == null) {
        continue; // Skip tasks without updatedAt
      }

      // Parse recurrence rule from the joined data
      final recurrence = _parseRecurrenceFromMap(taskData);
      if (recurrence == null) {
        continue;
      }

      // Check if task should be reopened
      if (shouldReopenTask(updatedAt, recurrence, now)) {
        // Reopen the task
        final reopenedTask = Task(
          task.id,
          task.task,
          Status.open,
          task.taskListId,
          createdAt: task.createdAt,
          updatedAt: now.toIso8601String(),
          recurrenceId: task.recurrenceId,
        );

        await _databaseService.updateTask(reopenedTask);
        reopenedTaskTexts.add(task.task);
      }
    }

    return reopenedTaskTexts;
  }

  /// Parse RecurrenceRules from the joined query result
  RecurrenceRules? _parseRecurrenceFromMap(Map<String, dynamic> map) {
    try {
      final frequencyStr = map['frequency'] as String?;
      if (frequencyStr == null) {
        return null;
      }

      final frequency = RecurrenceFrequencyExtension.fromString(frequencyStr);
      final interval = map['interval'] as int? ?? 1;
      
      List<DayOfWeek>? daysOfWeek;
      if (map['daysOfWeek'] != null) {
        try {
          final daysStr = map['daysOfWeek'] as String;
          final daysList = jsonDecode(daysStr) as List;
          daysOfWeek = daysList
              .map((day) => DayOfWeekExtension.fromString(day as String))
              .toList();
        } catch (e) {
          daysOfWeek = null;
        }
      }

      DateTime? endDate;
      if (map['endDate'] != null) {
        try {
          endDate = DateTime.parse(map['endDate'] as String);
        } catch (e) {
          endDate = null;
        }
      }

      final maxOccurrences = map['maxOccurrences'] as int?;
      final timeOfDay = map['timeOfDay'] as String?;

      return RecurrenceRules(
        id: map['recurrenceRuleId'] as int?,
        frequency: frequency,
        interval: interval,
        daysOfWeek: daysOfWeek,
        endDate: endDate,
        maxOccurrences: maxOccurrences,
        timeOfDay: timeOfDay,
      );
    } catch (e) {
      print('Error parsing recurrence rule: $e');
      return null;
    }
  }

  /// Determine if a task should be reopened based on recurrence rules
  bool shouldReopenTask(
      DateTime completedAt, RecurrenceRules rule, DateTime now) {
    // Check end date if set
    if (rule.endDate != null && now.isAfter(rule.endDate!)) {
      return false;
    }

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return _shouldReopenDaily(completedAt, rule, now);
      case RecurrenceFrequency.weekly:
        return _shouldReopenWeekly(completedAt, rule, now);
    }
  }

  /// Check if a daily recurring task should be reopened
  bool _shouldReopenDaily(
      DateTime completedAt, RecurrenceRules rule, DateTime now) {
    // Calculate the target date: interval days from completion
    final targetDate = completedAt.add(Duration(days: rule.interval));
    
    // Parse time of day (default to noon if not set)
    final timeOfDay = _parseTimeOfDay(rule.timeOfDay);
    final targetDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );

    // Task should be reopened if now is at or past the target date/time
    return now.isAfter(targetDateTime) || now.isAtSameMomentAs(targetDateTime);
  }

  /// Check if a weekly recurring task should be reopened
  bool _shouldReopenWeekly(
      DateTime completedAt, RecurrenceRules rule, DateTime now) {
    // Calculate base date: interval weeks from completion
    final baseDate = completedAt.add(Duration(days: rule.interval * 7));
    
    // Parse time of day (default to noon if not set)
    final timeOfDay = _parseTimeOfDay(rule.timeOfDay);

    // If daysOfWeek is set, find the earliest occurrence of any specified day
    if (rule.daysOfWeek != null && rule.daysOfWeek!.isNotEmpty) {
      // Find the earliest target date from the specified days
      DateTime? earliestTargetDate;
      for (final dayOfWeek in rule.daysOfWeek!) {
        final targetDate = _getNextOccurrenceOfDay(baseDate, dayOfWeek);
        if (earliestTargetDate == null || targetDate.isBefore(earliestTargetDate)) {
          earliestTargetDate = targetDate;
        }
      }
      
      if (earliestTargetDate != null) {
        final targetDateTime = DateTime(
          earliestTargetDate.year,
          earliestTargetDate.month,
          earliestTargetDate.day,
          timeOfDay.hour,
          timeOfDay.minute,
        );

        // Task should be reopened if now is at or past the target date/time
        return now.isAfter(targetDateTime) || now.isAtSameMomentAs(targetDateTime);
      }
      return false;
    } else {
      // No daysOfWeek set, use the same day as completion
      final targetDateTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );

      return now.isAfter(targetDateTime) || now.isAtSameMomentAs(targetDateTime);
    }
  }

  /// Get the next occurrence of a specific day of week from a base date
  DateTime _getNextOccurrenceOfDay(DateTime baseDate, DayOfWeek dayOfWeek) {
    final targetWeekday = _dayOfWeekToInt(dayOfWeek);
    final currentWeekday = baseDate.weekday;
    
    int daysToAdd = (targetWeekday - currentWeekday) % 7;
    if (daysToAdd == 0) {
      // Same day, check if we should use this week or next
      // For simplicity, if it's the same day, we'll use it
      daysToAdd = 0;
    }
    
    return baseDate.add(Duration(days: daysToAdd));
  }

  /// Convert DayOfWeek enum to int (Monday = 1, Sunday = 7)
  int _dayOfWeekToInt(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 1;
      case DayOfWeek.tue:
        return 2;
      case DayOfWeek.wed:
        return 3;
      case DayOfWeek.thu:
        return 4;
      case DayOfWeek.fri:
        return 5;
      case DayOfWeek.sat:
        return 6;
      case DayOfWeek.sun:
        return 7;
    }
  }

  /// Parse time of day string (HH:mm or HH:mm:ss) to TimeOfDay
  /// Defaults to noon (12:00) if not set
  TimeOfDay _parseTimeOfDay(String? timeOfDayStr) {
    if (timeOfDayStr == null || timeOfDayStr.isEmpty) {
      return const TimeOfDay(hour: 12, minute: 0); // Default to noon
    }

    try {
      final parts = timeOfDayStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      print('Error parsing timeOfDay: $e');
    }

    return const TimeOfDay(hour: 12, minute: 0); // Default to noon on error
  }
}

