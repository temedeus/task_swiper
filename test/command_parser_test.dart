import 'package:flutter_test/flutter_test.dart';
import 'package:taskswiper/service/command_parser.dart';
import 'package:taskswiper/model/recurrence_frequency.dart';
import 'package:taskswiper/model/day_of_week.dart';

void main() {
  group('CommandParser', () {
    late CommandParser parser;

    setUp(() {
      parser = CommandParser();
    });

    group('Create Command', () {
      test('parses simple add command - English', () {
        final command = parser.parse('Add buy milk');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Buy milk');
        expect(command!.recurrence, isNull);
      });

      test('parses simple add command - Finnish', () {
        final command = parser.parse('Lisää osta maito');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Osta maito');
        expect(command!.recurrence, isNull);
      });

      test('parses create with please - English', () {
        final command = parser.parse('Please add buy eggs');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Buy eggs');
      });

      test('parses create with please - Finnish', () {
        final command = parser.parse('Voitko lisätä maidon');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Maidon');
      });

      test('parses natural phrasing - English', () {
        final command = parser.parse('I need to add a reminder to buy milk');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, contains('reminder'));
        expect(command!.title, contains('buy'));
        expect(command!.title, contains('milk'));
      });

      test('parses natural phrasing - Finnish', () {
        final command = parser.parse('Minun pitää lisätä muistutus ostaa leipä');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, contains('muistutus'));
      });

      test('parses create with "new task" - English', () {
        final command = parser.parse('New task call mom');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Call mom');
      });

      test('parses create with recurrence - English daily', () {
        final command = parser.parse('Add buy milk every day at 9 am');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Buy milk');
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.daily);
        expect(recurrence.timeOfDay, '09:00');
      });

      test('parses create with recurrence - English weekly', () {
        final command = parser.parse('Add workout every Monday at 14:00');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, 'Workout');
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.weekly);
        expect(recurrence.daysOfWeek, isNotNull);
        expect(recurrence.daysOfWeek!.length, 1);
        expect(recurrence.daysOfWeek!.first, DayOfWeek.mon);
        expect(recurrence.timeOfDay, '14:00');
      });

      test('parses create with recurrence - Finnish weekly', () {
        final command = parser.parse('Lisää harjoitus joka maanantai kello 15');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.weekly);
        expect(recurrence.daysOfWeek, isNotNull);
        expect(recurrence.daysOfWeek!.first, DayOfWeek.mon);
        expect(recurrence.timeOfDay, '15:00');
      });

      test('one-time task has no recurrence', () {
        final command = parser.parse('Create a task to buy milk');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.recurrence, isNull);
      });
    });

    group('Complete Command', () {
      test('parses mark as done - English', () {
        final command = parser.parse('Mark groceries as done');
        expect(command, isNotNull);
        expect(command!.type, CommandType.complete);
        expect(command!.title, 'Groceries');
      });

      test('parses mark as done - Finnish', () {
        final command = parser.parse('Merkitse ostokset tehtyksi');
        expect(command, isNotNull);
        expect(command!.type, CommandType.complete);
        expect(command!.title, 'Ostokset');
      });

      test('parses complete command - English', () {
        final command = parser.parse('Complete the report');
        expect(command, isNotNull);
        expect(command!.type, CommandType.complete);
        expect(command!.title, 'The report');
      });

      test('parses done command - English', () {
        final command = parser.parse('Done with meeting');
        expect(command, isNotNull);
        expect(command!.type, CommandType.complete);
        expect(command!.title, 'Meeting');
      });

      test('parses valmis command - Finnish', () {
        final command = parser.parse('Valmis palaverista');
        expect(command, isNotNull);
        expect(command!.type, CommandType.complete);
      });
    });

    group('Delete Command', () {
      test('parses delete command - English', () {
        final command = parser.parse('Delete old task');
        expect(command, isNotNull);
        expect(command!.type, CommandType.delete);
        expect(command!.title, 'Old task');
      });

      test('parses delete command - Finnish', () {
        final command = parser.parse('Poista vanha tehtävä');
        expect(command, isNotNull);
        expect(command!.type, CommandType.delete);
        expect(command!.title, 'Vanha tehtävä');
      });

      test('parses remove command - English', () {
        final command = parser.parse('Remove meeting');
        expect(command, isNotNull);
        expect(command!.type, CommandType.delete);
        expect(command!.title, 'Meeting');
      });

      test('parses trash command - English', () {
        final command = parser.parse('Trash this item');
        expect(command, isNotNull);
        expect(command!.type, CommandType.delete);
        expect(command!.title, 'This item');
      });
    });

    group('List Command', () {
      test('parses list tasks - English', () {
        final command = parser.parse('List tasks');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
        expect(command.filter, TaskFilter.open);
      });

      test('parses list tasks - Finnish', () {
        final command = parser.parse('Listaa tehtävät');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
        expect(command.filter, TaskFilter.open);
      });

      test('parses list open tasks - English', () {
        final command = parser.parse('List open tasks');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
        expect(command.filter, TaskFilter.open);
      });

      test('parses list completed tasks - English', () {
        final command = parser.parse('List completed tasks');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
        expect(command.filter, TaskFilter.completed);
      });

      test('parses list all tasks - English', () {
        final command = parser.parse('List all tasks');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
        expect(command.filter, TaskFilter.all);
      });

      test('parses show tasks - English', () {
        final command = parser.parse('Show my tasks');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
      });

      test('parses näytä tehtävät - Finnish', () {
        final command = parser.parse('Näytä tehtävät');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
      });

      test('parses what do I have - English', () {
        final command = parser.parse('What tasks do I have');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
      });

      test('parses mitä minulla on - Finnish', () {
        final command = parser.parse('Mitkä tehtävät minulla on');
        expect(command, isNotNull);
        expect(command!.type, CommandType.list);
      });
    });

    group('Update Command', () {
      test('parses change X to Y - English', () {
        final command = parser.parse('Change milk to buy eggs');
        expect(command, isNotNull);
        expect(command!.type, CommandType.update);
        expect(command.oldTitle, 'Milk');
        expect(command.newTitle, 'Buy eggs');
      });

      test('parses update X to Y - English', () {
        final command = parser.parse('Update meeting to team meeting');
        expect(command, isNotNull);
        expect(command!.type, CommandType.update);
        expect(command.oldTitle, 'Meeting');
        expect(command.newTitle, 'Team meeting');
      });

      test('parses muuta X Y:ksi - Finnish', () {
        final command = parser.parse('Muuta maito osta munia');
        expect(command, isNotNull);
        expect(command!.type, CommandType.update);
      });
    });

    group('Recurrence Parsing', () {
      test('parses daily recurrence - English', () {
        final command = parser.parse('Add task every day');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.daily);
      });

      test('parses weekly recurrence with day - English', () {
        final command = parser.parse('Add workout every Sunday');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.weekly);
        expect(recurrence.daysOfWeek, isNotNull);
        expect(recurrence.daysOfWeek!.contains(DayOfWeek.sun), isTrue);
      });

      test('parses weekly recurrence with multiple days - English', () {
        final command = parser.parse('Add meeting every Monday Wednesday Friday');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.weekly);
        expect(recurrence.daysOfWeek, isNotNull);
        expect(recurrence.daysOfWeek!.length, 3);
        expect(recurrence.daysOfWeek!.contains(DayOfWeek.mon), isTrue);
        expect(recurrence.daysOfWeek!.contains(DayOfWeek.wed), isTrue);
        expect(recurrence.daysOfWeek!.contains(DayOfWeek.fri), isTrue);
      });

      test('parses recurrence with time - English', () {
        final command = parser.parse('Add workout every day at 8am');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.timeOfDay, '08:00');
      });

      test('parses recurrence with time - Finnish', () {
        final command = parser.parse('Lisää harjoitus joka päivä kello 15');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.timeOfDay, '15:00');
      });

      test('parses Finnish recurrence with day - Finnish', () {
        final command = parser.parse('Lisää siivous joka sunnuntai kello 13');
        expect(command, isNotNull);
        final recurrence = command!.recurrence!;
        expect(recurrence.frequency, RecurrenceFrequency.weekly);
        expect(recurrence.daysOfWeek!.contains(DayOfWeek.sun), isTrue);
        expect(recurrence.timeOfDay, '13:00');
      });

      test('no recurrence for one-time task - English', () {
        final command = parser.parse('Create a task to buy milk');
        expect(command, isNotNull);
        expect(command!.recurrence, isNull);
      });

      test('no recurrence for one-time task - Finnish', () {
        final command = parser.parse('Luo tehtävä maidon ostamisesta');
        expect(command, isNotNull);
        expect(command!.recurrence, isNull);
      });
    });

    group('Natural Language', () {
      test('handles polite phrasing - English', () {
        final command = parser.parse('Can you please add buy milk');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title?.toLowerCase(), contains('buy'));
        expect(command!.title?.toLowerCase(), contains('milk'));
      });

      test('handles polite phrasing - Finnish', () {
        final command = parser.parse('Voitko ystävällisesti lisätä ostokset');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, contains('ostokset'));
      });

      test('handles natural phrasing with filler words - English', () {
        final command = parser.parse('I need to maybe add a reminder about milk');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
        expect(command!.title, isNotEmpty);
      });

      test('handles natural phrasing - Finnish', () {
        final command = parser.parse('Minun pitäisi ehkä lisätä muistutus');
        expect(command, isNotNull);
        expect(command!.type, CommandType.create);
      });
    });

    group('Edge Cases', () {
      test('returns null for empty input', () {
        final command = parser.parse('');
        expect(command, isNull);
      });

      test('returns null for only fillers', () {
        final command = parser.parse('please can you');
        expect(command, isNull);
      });

      test('returns null for unrecognized command', () {
        final command = parser.parse('The weather is nice today');
        expect(command, isNull);
      });
    });
  });
}
