import 'package:flutter/material.dart';

class AddTaskListDialog extends StatefulWidget {
  const AddTaskListDialog({Key? key, required this.callback, this.defaultText})
      : super(key: key);
  final Function(String) callback;
  final String? defaultText;

  @override
  State<AddTaskListDialog> createState() =>
      _AddTaskListDialogState(callback, defaultText);
}

class _AddTaskListDialogState extends State<AddTaskListDialog> {
  final myController = TextEditingController();

  Function(String) callback;
  final String? defaultText;
  late final String hintText;
  late final String labelText;

  _AddTaskListDialogState(this.callback, this.defaultText);

  @override
  void initState() {
    if (defaultText != null) {
      myController.text = defaultText!;
      hintText = "Edit task list";
      labelText = "Edit";
    } else {
      hintText = "Add task list";
      labelText = "Add";
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
              minLines: 1,
              maxLines: 1,
              maxLength: 35,
              controller: myController,
              decoration: InputDecoration(
                hintText: hintText,
                labelText: labelText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      15.0),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (myController.text.isNotEmpty) {
                  callback(myController.text);
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
