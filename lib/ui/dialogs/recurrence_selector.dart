import 'package:flutter/material.dart';
import 'package:taskswiper/model/day_of_week.dart';
import 'package:taskswiper/model/recurrence_frequency.dart';
import 'package:taskswiper/model/recurrence_rules.dart';

class RecurrenceSelector extends StatefulWidget {
  final Function(RecurrenceRules?) onRecurrenceChanged;
  final RecurrenceRules? initialRecurrence;
  /// When true, the time selector is shown with error styling (time is required for recurrence).
  final bool showTimeError;

  const RecurrenceSelector({
    Key? key,
    required this.onRecurrenceChanged,
    this.initialRecurrence,
    this.showTimeError = false,
  }) : super(key: key);

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  RecurrenceFrequency? frequency;
  int interval = 1;
  List<DayOfWeek> selectedDays = [];
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecurrence != null) {
      frequency = widget.initialRecurrence!.frequency;
      interval = widget.initialRecurrence!.interval ?? 1;
      selectedDays = widget.initialRecurrence!.daysOfWeek ?? [];
      selectedTime = widget.initialRecurrence!.timeOfDay != null
          ? TimeOfDay(
        hour: int.parse(widget.initialRecurrence!.timeOfDay!.split(':')[0]),
        minute: int.parse(widget.initialRecurrence!.timeOfDay!.split(':')[1]),
      )
          : null;
    }
  }

  void updateRecurrence() {
    if (frequency == null) {
      widget.onRecurrenceChanged(null);
      return;
    }

    RecurrenceRules updatedRecurrence = RecurrenceRules(
      frequency: frequency!,
      interval: interval,
      daysOfWeek: selectedDays.isNotEmpty ? selectedDays: null,
      timeOfDay: selectedTime != null
          ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}'
          : null,
    );

    widget.onRecurrenceChanged(updatedRecurrence);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<RecurrenceFrequency>(
          value: frequency,
          hint: const Text("Repeat Task"),
          items: RecurrenceFrequency.values.map((RecurrenceFrequency value) {
            return DropdownMenuItem<RecurrenceFrequency>(
              value: value,
              child: Text(capitalizeFirstLetter(value.name)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              frequency = value;
              if (value != RecurrenceFrequency.weekly) selectedDays.clear();
            });
            updateRecurrence();
          },
        ),
        if (frequency == RecurrenceFrequency.weekly) ...[
          Wrap(
            spacing: 8.0,
            children: DayOfWeek.values.map((day) {
              bool isSelected = selectedDays.contains(day);
              return FilterChip(
                label: Text(capitalizeFirstLetter(day.name)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  });
                  updateRecurrence();
                },
              );
            }).toList(),
          ),
        ],
        if (frequency != null) ...[
          TextFormField(
            decoration: const InputDecoration(labelText: "Repeat Every (days/weeks/months)"),
            keyboardType: TextInputType.number,
            initialValue: interval.toString(),
            onChanged: (value) {
              setState(() {
                interval = int.tryParse(value) ?? 1;
              });
              updateRecurrence();
            },
          ),
          Container(
            decoration: widget.showTimeError
                ? BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.error, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: TextButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: selectedTime ?? TimeOfDay.now(),
                );
                if (pickedTime != null) {
                  setState(() {
                    selectedTime = pickedTime;
                  });
                  updateRecurrence();
                }
              },
              child: Text(
                selectedTime == null ? "Pick Time (required)" : "Time: ${selectedTime!.format(context)}",
                style: widget.showTimeError && selectedTime == null
                    ? TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500)
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }

}
