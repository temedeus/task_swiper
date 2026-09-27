---
name: taskswiper-recurrence
description: Manage and test recurrence logic in Task Swiper. Use for debugging task reopening, calculating next occurrence dates, and testing recurrence rule combinations.
 aliases: [recurrence, task-recurrence, repeat, recurring]
 on_include:
   - lib/model/recurrence_rules.dart
   - lib/model/recurrence_frequency.dart
   - lib/model/day_of_week.dart
   - lib/service/recurrence_service.dart
   - lib/model/task.dart
   - lib/model/status.dart
on_exclude:
   - .dart_tool/
   - build/
---

# TaskSwiper Recurrence Skill

You are an expert in Task Swiper's recurrence system. Help with recurrence logic, debugging, and testing.

## When to Use This Skill

- Working with `RecurrenceRules` or `RecurrenceService`
- Debugging why recurring tasks aren't reopening
- Testing new recurrence patterns (daily, weekly)
- Calculating next occurrence dates
- Validating time-of-day parsing
- Adding new recurrence frequency types

## Core Files

- `lib/service/recurrence_service.dart` - Main logic for checking and reopening tasks
- `lib/model/recurrence_rules.dart` - Data model for recurrence configuration
- `lib/model/recurrence_frequency.dart` - Enum: daily, weekly
- `lib/model/day_of_week.dart` - Enum: mon, tue, wed, thu, fri, sat, sun
- `lib/model/task.dart` - Task model with recurrenceId field

## Key Methods

### RecurrenceService
- `checkAndReopenTasks()` - Main entry point, returns list of reopened task texts
- `shouldReopenTask(completedAt, rule, now)` - Determines if task should reopen
- `_shouldReopenDaily()` - Daily recurrence logic
- `_shouldReopenWeekly()` - Weekly recurrence logic
- `_getNextOccurrenceOfDayAtTime()` - Calculate next occurrence of a specific day
- `_parseTimeOfDay()` - Parse HH:mm or HH:mm:ss strings

## Recurrence Rules Structure

```dart
RecurrenceRules({
  int? id,
  RecurrenceFrequency frequency,  // daily or weekly
  int interval,                    // default: 1 (every 1 day/week)
  List<DayOfWeek>? daysOfWeek,    // for weekly: which days
  DateTime? endDate,              // optional end date
  int? maxOccurrences,            // optional max repeats
  String? timeOfDay,              // HH:mm:ss format
})
```

## Common Tasks

### Test if a task should reopen
```dart
final service = RecurrenceService(databaseService);
final rule = RecurrenceRules(
  frequency: RecurrenceFrequency.daily,
  interval: 1,
  timeOfDay: '09:00:00',
);
final completedAt = DateTime(2024, 1, 1, 10, 0);
final now = DateTime(2024, 1, 2, 9, 0);
final shouldReopen = service.shouldReopenTask(completedAt, rule, now);
```

### Add a new recurrence frequency
1. Add enum value to `RecurrenceFrequency`
2. Add case to `shouldReopenTask()` switch statement
3. Create new method like `_shouldReopenDaily()` for the pattern

### Debug recurring task not reopening
1. Check `task.recurrenceId` is not null
2. Verify `recurrence_rules` row exists with matching id
3. Check `task.status == Status.completed`
4. Verify `task.updatedAt` is set
5. Trace through `shouldReopenTask()` logic

## Testing Tips

Use `RecurrenceService` directly with mock data:
```dart
final mockDb = DatabaseService();
// Don't initialize, just pass to service
final service = RecurrenceService(mockDb);

// Test with known dates
final rule = RecurrenceRules(
  frequency: RecurrenceFrequency.weekly,
  interval: 1,
  daysOfWeek: [DayOfWeek.mon, DayOfWeek.wed, DayOfWeek.fri],
  timeOfDay: '14:00',
);
```

## Gotchas

- Time comparisons use local time (`toLocal()`)
- Default time is noon (12:00) if not specified
- Weekly with no `daysOfWeek` uses the completion day
- Interval for weekly: 1 = first occurrence, 2 = add 1 week, etc.
- Month boundaries: Uses Duration(days: ...) which handles rollover
