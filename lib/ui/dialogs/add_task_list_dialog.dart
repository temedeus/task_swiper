import 'package:flutter/material.dart';

class AddTaskListDialog extends StatefulWidget {
  const AddTaskListDialog({Key? key, required this.callback}) : super(key: key);
  final Function(String) callback;

  @override
  State<AddTaskListDialog> createState() => _AddTaskListDialogState(callback);
}

class _AddTaskListDialogState extends State<AddTaskListDialog> {
  final myController = TextEditingController();

  Function(String) callback;

  _AddTaskListDialogState(this.callback);

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
              minLines: 1,
              maxLines: 1,
              controller: myController,
              decoration: const InputDecoration(
                  hintText: "Add task list",
                  labelText: "Add",
                  border: OutlineInputBorder()),
            ),
            TextButton(
              onPressed: () {
                if(myController.text.isNotEmpty) {
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
