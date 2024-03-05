import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DismissTaskDialog extends StatelessWidget {

  final VoidCallback callback;
  final String title;
  final String content;
  final String primary;
  final String cancel;

  DismissTaskDialog(this.callback, this.title, this.content, this.primary, this.cancel);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: <Widget>[
        ElevatedButton(
            onPressed: () async => callback(),
            child: Text(primary)),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancel),
        ),
      ],
    );;
  }
  
}