import 'dart:convert';

import 'package:taskswiper/model/recurrence_frequency.dart';

import 'day_of_week.dart';

class RecurrenceRules {
  final int? id;
  final RecurrenceFrequency frequency;
  final int interval;
  final List<DayOfWeek>? daysOfWeek;
  final DateTime? endDate;
  final int? maxOccurrences;
  final String? timeOfDay; // Stored as HH:mm:ss

  RecurrenceRules({
    this.id,
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek,
    this.endDate,
    this.maxOccurrences,
    this.timeOfDay,
  });

  @override
  String toString() {
    return 'RecurrenceRules{id: $id, frequency: $frequency, interval: $interval, '
        'daysOfWeek: $daysOfWeek, endDate: $endDate, '
        'maxOccurrences: $maxOccurrences, timeOfDay: $timeOfDay}';
  }

  // From map, handle frequency as enum and daysOfWeek as JSON string of enum names
  RecurrenceRules.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        frequency = RecurrenceFrequencyExtension.fromString(item["frequency"]),
        interval = item["interval"] ?? 1,
        daysOfWeek = item["daysOfWeek"] != null
            ? (jsonDecode(item["daysOfWeek"]) as List)
            .map((day) => DayOfWeekExtension.fromString(day as String))
            .toList()
            : null,
        endDate = item["endDate"] != null ? DateTime.parse(item["endDate"]) : null,
        maxOccurrences = item["maxOccurrences"],
        timeOfDay = item["timeOfDay"];

  // To map, convert frequency to string and daysOfWeek to JSON string of enum names
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'frequency': frequency.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek != null
          ? jsonEncode(daysOfWeek?.map((e) => e.name).toList())
          : null,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'timeOfDay': timeOfDay,
    };
  }
}
