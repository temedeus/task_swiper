import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditTaskDialog extends StatefulWidget {
  const EditTaskDialog({Key? key, required this.callback, this.defaultText})
      : super(key: key);
  final Function(String) callback;
  final String? defaultText;

  @override
  State<EditTaskDialog> createState() =>
      _EditTaskDialogState(callback, defaultText);
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  final myController = TextEditingController();

  Function(String) callback;
  final String? defaultText;

  _EditTaskDialogState(this.callback, this.defaultText);

  @override
  void initState() {
    if (defaultText != null) {
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
              maxLines: 5,
              maxLength: 100,
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  int newLines = newValue.text.split('\n').length;
                  if (newLines > 5) {
                    return oldValue;
                  } else {
                    return newValue;
                  }
                }),
              ],
              controller: myController,
              decoration: InputDecoration(
                hintText: "Write your note here",
                labelText: "Note",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
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
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
