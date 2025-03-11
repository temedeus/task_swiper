class RecurrenceRules {
  final int? id;
  final String frequency; // 'daily', 'weekly', 'monthly', 'custom'
  final int interval; // Defaults to 1
  final List<String>? daysOfWeek; // ['mon', 'wed'] if applicable
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

  RecurrenceRules.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        frequency = item["frequency"],
        interval = item["interval"] ?? 1,
        daysOfWeek = item["daysOfWeek"] != null
            ? (item["daysOfWeek"] as String).split(',')
            : null,
        endDate = item["endDate"] != null ? DateTime.parse(item["endDate"]) : null,
        maxOccurrences = item["maxOccurrences"],
        timeOfDay = item["timeOfDay"];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'frequency': frequency,
      'interval': interval,
      'daysOfWeek': daysOfWeek?.join(','),
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
      'timeOfDay': timeOfDay,
    };
  }
}
