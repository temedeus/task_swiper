enum DayOfWeek { mon, tue, wed, thu, fri, sat, sun }

extension DayOfWeekExtension on DayOfWeek {
  String get name => toString().split('.').last;

  static DayOfWeek fromString(String day) {
    return DayOfWeek.values.firstWhere((e) => e.name == day);
  }
}