import 'package:taskswiper/model/recurrence_rules.dart';
import 'package:taskswiper/model/recurrence_frequency.dart';
import 'package:taskswiper/model/day_of_week.dart';

/// Parses natural language commands into structured AppCommand objects.
/// Supports English and Finnish.
/// Uses lightweight rule-based parsing that can be replaced with ML later.
class CommandParser {
  /// Parses a text command into an AppCommand.
  /// Returns null if the command cannot be understood.
  AppCommand? parse(String text) {
    final normalized = _normalize(text);
    
    // Try to detect the command type
    final commandType = _detectCommandType(normalized);
    
    switch (commandType) {
      case CommandType.create:
        return _parseCreateCommand(normalized);
      case CommandType.complete:
        return _parseCompleteCommand(normalized);
      case CommandType.delete:
        return _parseDeleteCommand(normalized);
      case CommandType.list:
        return _parseListCommand(normalized);
      case CommandType.update:
        return _parseUpdateCommand(normalized);
      case null:
        return null;
    }
  }

  /// Normalizes input text for parsing
  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        // Remove common polite fillers that don't affect meaning
        .replaceAll(RegExp(r'\b(please|kindly|can you|could you|would you|hey|hi|hello|okay|ok|siri|alexa)\b'), '')
        .trim();
  }

  /// Detects the type of command from normalized text
  CommandType? _detectCommandType(String text) {
    // Check for create/add commands
    if (_containsAny(text, _createKeywords)) return CommandType.create;
    
    // Check for complete/mark done commands
    if (_containsAny(text, _completeKeywords)) return CommandType.complete;
    
    // Check for delete/remove commands
    if (_containsAny(text, _deleteKeywords)) return CommandType.delete;
    
    // Check for list/show commands
    if (_containsAny(text, _listKeywords)) return CommandType.list;
    
    // Check for update/change commands
    if (_containsAny(text, _updateKeywords)) return CommandType.update;
    
    return null;
  }

  /// Helper to check if text contains any of the keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  // ========== Keyword Lists ==========
  
  // English + Finnish keywords for each command type
  static final List<String> _createKeywords = [
    // English
    'create', 'add', 'new ', 'make ', 'set ', 'remind', 'need to', 'should add',
    'please add', 'can you add', 'would you add',
    // Finnish
    'lisää', 'luo', 'uusi ', 'tee ', 'aseta ', 'muistuta', 'tarvitsee', 'pitää lisätä',
    'voitko lisätä', 'lisätä',
  ];

  static final List<String> _completeKeywords = [
    // English
    'mark ', 'mark', 'complete', 'done', 'finish', 'check ', 'cross ', 'tick',
    'as done', 'as complete', 'as finished', 'is done', 'is complete',
    'set as done', 'set as complete',
    // Finnish
    'merkitse', 'valmis', 'tehty', 'rasti', 'valmiiksi', 'suoritettu',
    'merkitse tehtyksi', 'aseta valmiiksi', 'on valmis', 'on tehty',
  ];

  static final List<String> _deleteKeywords = [
    // English
    'delete', 'remove', 'trash', 'erase', 'cancel', 'clear',
    'get rid of', 'do away with', 'eliminate',
    // Finnish
    'poista', 'heitä roskiin', 'tyhjennä', 'peruuta',
    'hävitä', 'poista tehtävä',
  ];

  static final List<String> _listKeywords = [
    // English
    'list', 'show ', 'display', 'view', 'see ', 'tell me',
    'what ', 'list ', 'show my', 'display my',
    // Finnish
    'listaa', 'näytä ', 'esitä', 'näytä minun', 'mitä',
    'mitkä', 'luettelo',
  ];

  static final List<String> _updateKeywords = [
    // English
    'change', 'update', 'edit', 'modify', 'fix',
    'alter', 'revise', 'amend',
    // Finnish
    'muuta', 'päivitä', 'muokkaa', 'korjaa',
    'muuttaa', 'tarkista',
  ];

  // ========== Command Parsers ==========

  AppCommand? _parseCreateCommand(String text) {
    // First, extract recurrence information from the original text
    final recurrence = _parseRecurrenceFromText(text);
    
    // Remove create keywords
    var taskText = _removeKeywords(text, _createKeywords);
    
    // If recurrence was detected, remove recurrence-related keywords
    if (recurrence != null) {
      taskText = _removeRecurrenceKeywords(taskText);
    }
    
    // Clean up the task text
    taskText = _cleanTaskText(taskText);
    
    if (taskText.isEmpty) {
      return null;
    }
    
    return AppCommand.create(
      title: _capitalize(taskText),
      recurrence: recurrence,
    );
  }

  AppCommand? _parseCompleteCommand(String text) {
    var taskText = _removeKeywords(text, _completeKeywords);
    
    // Remove 'as done', 'as complete', etc.
    taskText = taskText.replaceAll(RegExp(r'\s+as\s+(done|complete|finished|valmis|tehty|suoritettu)'), '');
    
    taskText = _cleanTaskText(taskText);
    
    if (taskText.isEmpty) {
      return null;
    }
    
    return AppCommand.complete(title: _capitalize(taskText));
  }

  AppCommand? _parseDeleteCommand(String text) {
    var taskText = _removeKeywords(text, _deleteKeywords);
    
    taskText = _cleanTaskText(taskText);
    
    if (taskText.isEmpty) {
      return null;
    }
    
    return AppCommand.delete(title: _capitalize(taskText));
  }

  AppCommand? _parseListCommand(String text) {
    TaskFilter filter = TaskFilter.open; // default
    
    // Check for filter keywords
    if (_containsAny(text, ['completed', 'done', 'finished', 'suoritettu', 'tehdyt', 'valmis'])) {
      filter = TaskFilter.completed;
    } else if (_containsAny(text, ['all', 'kaikki', 'every', 'joka', 'kaiken'])) {
      filter = TaskFilter.all;
    }
    
    return AppCommand.list(filter: filter);
  }

  AppCommand? _parseUpdateCommand(String text) {
    // Pattern 1: change X to Y (with connecting word)
    final changeMatch1 = RegExp(r'^(?:change|update|edit|modify|muuta|päivitä|muokkaa)\s+(.+?)\s+(?:to|into|seksi|kokonaan)\s+(.+?)$', caseSensitive: false)
        .firstMatch(text);
    
    // Pattern 2: Finnish muuta X Y (without connecting word)
    final changeMatch2 = RegExp(r'^(?:muuta|päivitä|muokkaa)\s+(.+?)\s+(.+)$', caseSensitive: false)
        .firstMatch(text);
    
    if (changeMatch1 != null) {
      return AppCommand.update(
        oldTitle: _capitalize(changeMatch1.group(1)!.trim()),
        newTitle: _capitalize(changeMatch1.group(2)!.trim()),
      );
    }
    
    if (changeMatch2 != null) {
      return AppCommand.update(
        oldTitle: _capitalize(changeMatch2.group(1)!.trim()),
        newTitle: _capitalize(changeMatch2.group(2)!.trim()),
      );
    }
    
    return null;
  }

  // ========== Recurrence Parsing ==========

  /// Parses recurrence information from text
  /// Returns RecurrenceRules if recurrence is detected, null otherwise
  RecurrenceRules? _parseRecurrenceFromText(String text) {
    // Check for explicit recurrence indicators
    if (!_containsAny(text, [
      'repeat', 'every', 'weekly', 'daily', 'monthly', 'each',
      'toista', 'joka', 'viikoittain', 'päivittäin', 'kuukausittain', 'joka kerta',
    ])) {
      return null; // No recurrence detected
    }
    
    RecurrenceFrequency? frequency;
    int interval = 1;
    List<DayOfWeek>? daysOfWeek;
    String? timeOfDay;
    
    // Determine frequency
    if (_containsAny(text, ['daily', 'every day', 'päivittäin', 'joka päivä'])) {
      frequency = RecurrenceFrequency.daily;
    } else if (_containsAny(text, ['weekly', 'every week', 'viikoittain', 'joka viikko']) ||
               _parseDaysOfWeek(text) != null) {
      // If days of week are mentioned, it's weekly
      frequency = RecurrenceFrequency.weekly;
      // Parse days of week
      daysOfWeek = _parseDaysOfWeek(text);
    } else {
      // Default to daily if recurrence is mentioned but no specific frequency
      frequency = RecurrenceFrequency.daily;
    }
    
    // Parse interval (every 2 days, every 3 weeks, etc.)
    final intervalMatch = RegExp(r'every\s+(\d+)\s+(day|week|month|päivä|viikko|kuukausi)', caseSensitive: false)
        .firstMatch(text);
    if (intervalMatch != null) {
      interval = int.parse(intervalMatch.group(1)!);
    }
    
    // Parse time of day
    timeOfDay = _parseTimeOfDay(text);
    
    return RecurrenceRules(
      frequency: frequency,
      interval: interval,
      daysOfWeek: daysOfWeek,
      timeOfDay: timeOfDay,
    );
  }

  /// Parses days of week from text
  List<DayOfWeek>? _parseDaysOfWeek(String text) {
    final dayMap = {
      'monday': DayOfWeek.mon,
      'mon': DayOfWeek.mon,
      'tuesday': DayOfWeek.tue,
      'tue': DayOfWeek.tue,
      'wednesday': DayOfWeek.wed,
      'wed': DayOfWeek.wed,
      'thursday': DayOfWeek.thu,
      'thu': DayOfWeek.thu,
      'friday': DayOfWeek.fri,
      'fri': DayOfWeek.fri,
      'saturday': DayOfWeek.sat,
      'sat': DayOfWeek.sat,
      'sunday': DayOfWeek.sun,
      'sun': DayOfWeek.sun,
      // Finnish
      'maanantai': DayOfWeek.mon,
      'ma': DayOfWeek.mon,
      'tiistai': DayOfWeek.tue,
      'ti': DayOfWeek.tue,
      'keskiviikko': DayOfWeek.wed,
      'ke': DayOfWeek.wed,
      'torstai': DayOfWeek.thu,
      'to': DayOfWeek.thu,
      'perjantai': DayOfWeek.fri,
      'pe': DayOfWeek.fri,
      'lauantai': DayOfWeek.sat,
      'la': DayOfWeek.sat,
      'sunnuntai': DayOfWeek.sun,
      'su': DayOfWeek.sun,
    };
    
    final days = <DayOfWeek>[];
    final lowerText = text.toLowerCase();
    for (final entry in dayMap.entries) {
      // Use word boundary regex to avoid substring matches
      if (RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false).hasMatch(lowerText)) {
        if (!days.contains(entry.value)) {
          days.add(entry.value);
        }
      }
    }
    
    return days.isNotEmpty ? days : null;
  }

  /// Parses time of day from text (HH:mm format)
  String? _parseTimeOfDay(String text) {
    // Pattern: at 1pm, at 13:00, at 1 pm, at 1:00pm, kello 13, kello 1
    final timeMatch = RegExp(r'(?:at|kello|\s)(\d{1,2})(?::(\d{2}))?\s*(am|pm|a\.m\.|p\.m\.)?', caseSensitive: false)
        .firstMatch(text);
    
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = timeMatch.group(2) ?? '00';
      final period = timeMatch.group(3)?.toLowerCase();
      
      int finalHour = hour;
      if (period == 'pm' || period == 'p.m.') {
        finalHour = hour % 12 + 12;
      } else if (period == 'am' || period == 'a.m.') {
        finalHour = hour % 12;
      }
      
      return '${finalHour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}';
    }
    
    return null;
  }

  // ========== Helper Methods ==========

  /// Removes keywords from text
  String _removeKeywords(String text, List<String> keywords) {
    // Sort keywords by length (longest first) to handle multi-word keywords first
    final sortedKeywords = [...keywords]..sort((a, b) => b.length.compareTo(a.length));
    
    var result = text;
    for (final kw in sortedKeywords) {
      // Escape the keyword for regex
      final escapedKw = RegExp.escape(kw);
      // Check if keyword contains only ASCII characters and no spaces
      final isAscii = RegExp(r'^[\x00-\x7F]+$').hasMatch(kw);
      final hasSpaces = kw.contains(' ');
      
      // Build the regex pattern
      String pattern;
      if (isAscii && !hasSpaces) {
        // Use word boundaries for ASCII single-word keywords
        pattern = '\\b' + escapedKw + '\\b';
      } else {
        // For non-ASCII or multi-word keywords, just match the keyword as-is
        pattern = escapedKw;
      }
      
      result = result.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    return result.trim();
  }

  /// Removes recurrence-related keywords from text
  String _removeRecurrenceKeywords(String text) {
    var result = text;
    
    // Remove recurrence keywords using regex with word boundaries
    final recurrencePatterns = [
      r'\brepeat(ing|s)?\b',
      r'\bevery\b',
      r'\beach\b',
      r'\bweekly\b',
      r'\bdaily\b',
      r'\bmonthly\b',
      r'\bon\b',
      r'\bat\b',
      r'\bday(s)?\b',
      r'\bweek(s)?\b',
      r'\bmonth(s)?\b',
      r'\bam\b',
      r'\bpm\b',
      r'\btoista\b',
      r'\bjoka\b',
      r'\bviikoittain\b',
      r'\bpäivittäin\b',
      r'\bkuukausittain\b',
      r'\bkello\b',
      r'\bpäivä\b',
      r'\bviikko\b',
      r'\bkuukausi\b',
    ];
    
    for (final pattern in recurrencePatterns) {
      result = result.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    
    // Remove time patterns like "9 am", "14:00", "at 1 pm", etc.
    // Match times like: 1am, 2pm, 14:00, 1:30pm, 9 am, etc.
    result = result.replaceAll(
      RegExp(r'\b(\d{1,2}(?::\d{2})?(?:\s*(?:am|pm|a\.m\.|p\.m\.))?)\b', caseSensitive: false),
      ''
    );
    
    // Clean up extra spaces
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    return result.trim();
  }

  /// Cleans up task text (removes extra words, punctuation)
  String _cleanTaskText(String text) {
    // Remove common articles, prepositions, and command-related words
    final stopWords = [
      'a', 'an', 'the', 'to', 'for', 'of', 'in', 'on', 'at',
      'task', 'tehtävä',
      'yksi', 'yhden', 'yhdellä', 'yhteen',
    ];
    
    var result = text;
    for (final word in stopWords) {
      result = result.replaceAll(RegExp('\\b' + RegExp.escape(word) + '\\b', caseSensitive: false), '');
    }
    
    // Clean up multiple spaces and punctuation
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    result = result.replaceAll(RegExp(r'[.,;:!?]'), '');
    result = result.trim();
    
    return result;
  }

  /// Capitalizes the first letter of a string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// Filter types for list commands
enum TaskFilter {
  open,
  completed,
  all,
  specificList,
}

/// Types of commands that can be parsed
enum CommandType {
  create,
  complete,
  delete,
  list,
  update,
}

/// Structured command for the app to execute
class AppCommand {
  final CommandType type;
  final String? title;
  final String? oldTitle;
  final String? newTitle;
  final TaskFilter? filter;
  final RecurrenceRules? recurrence;

  AppCommand._({
    required this.type,
    this.title,
    this.oldTitle,
    this.newTitle,
    this.filter,
    this.recurrence,
  });

  /// Create a new task
  factory AppCommand.create({
    required String title,
    RecurrenceRules? recurrence,
  }) {
    return AppCommand._(
      type: CommandType.create,
      title: title,
      recurrence: recurrence,
    );
  }

  /// Mark a task as complete
  factory AppCommand.complete({required String title}) {
    return AppCommand._(
      type: CommandType.complete,
      title: title,
    );
  }

  /// Delete a task
  factory AppCommand.delete({required String title}) {
    return AppCommand._(
      type: CommandType.delete,
      title: title,
    );
  }

  /// List tasks with optional filter
  factory AppCommand.list({TaskFilter filter = TaskFilter.open}) {
    return AppCommand._(
      type: CommandType.list,
      filter: filter,
    );
  }

  /// Update a task
  factory AppCommand.update({required String oldTitle, required String newTitle}) {
    return AppCommand._(
      type: CommandType.update,
      oldTitle: oldTitle,
      newTitle: newTitle,
    );
  }

  @override
  String toString() {
    return 'AppCommand{type: $type, title: $title, oldTitle: $oldTitle, newTitle: $newTitle, filter: $filter, recurrence: $recurrence}';
  }
}
