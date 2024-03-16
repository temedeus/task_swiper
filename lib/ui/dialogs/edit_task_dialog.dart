import 'package:flutter/material.dart';

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({Key? key, required this.callback, this.defaultText}) : super(key: key);
  final Function(String) callback;
  final String? defaultText;

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState(callback, defaultText);
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final myController = TextEditingController();

  Function(String) callback;
  final String? defaultText;

  _EditTaskDialogState(this.callback, this.defaultText);

  @override
  void initState() {
    if(defaultText != null) {
      myController.text = defaultText!;
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
              minLines: 5,
              maxLines: 5,
              controller: myController,
              decoration: const InputDecoration(
                  hintText: "Write your note here",
                  labelText: "Note",
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
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
