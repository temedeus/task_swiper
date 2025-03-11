import 'package:flutter/material.dart';
import '../../model/recurrence_rules.dart';
import 'recurrence_selector.dart'; // Import recurrence selector

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({Key? key, required this.callback, this.defaultText, this.defaultRecurrence})
      : super(key: key);

  final Future<Null> Function(String, RecurrenceRules?) callback;
  final String? defaultText;
  final RecurrenceRules? defaultRecurrence;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final TextEditingController myController = TextEditingController();
  RecurrenceRules? recurrenceData;
  bool isRecurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.defaultText != null) {
      myController.text = widget.defaultText!;
    }

    // Initialize recurrence settings
    if (widget.defaultRecurrence != null) {
      recurrenceData = widget.defaultRecurrence;
      isRecurring = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              maxLength: 100,
              controller: myController,
              decoration: InputDecoration(
                hintText: "Write your note here",
                labelText: "Note",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Toggle recurrence option
            SwitchListTile(
              title: const Text("Repeat Task"),
              value: isRecurring,
              onChanged: (value) {
                setState(() {
                  isRecurring = value;
                  if (!isRecurring) recurrenceData = null; // Reset when turned off
                });
              },
            ),

            // Show RecurrenceSelector only if recurrence is enabled
            if (isRecurring)
              RecurrenceSelector(
                initialRecurrence: recurrenceData,
                onRecurrenceChanged: (recurrence) {
                  setState(() {
                    recurrenceData = recurrence;
                  });
                },
              ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                if (myController.text.isNotEmpty) {
                  widget.callback(myController.text, recurrenceData);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
