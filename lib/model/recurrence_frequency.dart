enum RecurrenceFrequency { daily, weekly }

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get name => toString().split('.').last;

  static RecurrenceFrequency fromString(String frequency) {
    return RecurrenceFrequency.values.firstWhere((e) => e.name == frequency);
  }
}

