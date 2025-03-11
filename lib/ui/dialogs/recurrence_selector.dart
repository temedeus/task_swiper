import 'package:flutter/material.dart';
import 'package:taskswiper/model/recurrence_rules.dart';

class RecurrenceSelector extends StatefulWidget {
  final Function(RecurrenceRules?) onRecurrenceChanged;
  final RecurrenceRules? initialRecurrence;

  const RecurrenceSelector({Key? key, required this.onRecurrenceChanged, this.initialRecurrence})
      : super(key: key);

  @override
  State<RecurrenceSelector> createState() => _RecurrenceSelectorState();
}

class _RecurrenceSelectorState extends State<RecurrenceSelector> {
  String? frequency;
  int interval = 1;
  List<String> selectedDays = [];
  TimeOfDay? selectedTime;

  final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
        DropdownButtonFormField<String>(
          value: frequency,
          hint: const Text("Repeat Task"),
          items: ['Daily', 'Weekly', 'Monthly', 'Custom'].map((String value) {
            return DropdownMenuItem<String>(
              value: value.toLowerCase(),
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              frequency = value;
              if (value != 'weekly') selectedDays.clear();
            });
            updateRecurrence();
          },
        ),
        if (frequency == 'weekly') ...[
          Wrap(
            spacing: 8.0,
            children: weekdays.map((day) {
              bool isSelected = selectedDays.contains(day.toLowerCase());
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedDays.add(day.toLowerCase());
                    } else {
                      selectedDays.remove(day.toLowerCase());
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
          TextButton(
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
            child: Text(selectedTime == null ? "Pick Time" : "Time: ${selectedTime!.format(context)}"),
          ),
        ],
      ],
    );
  }
}
