import 'package:flutter/material.dart';

class SwitchWrapper extends StatefulWidget {
  final ValueChanged<bool>? onChanged;
  final String title;

  const SwitchWrapper({Key? key, this.onChanged, required this.title}) : super(key: key);

  @override
  _SwitchWrapperState createState() => _SwitchWrapperState();
}

class _SwitchWrapperState extends State<SwitchWrapper> {
  bool _switchValue = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Switch(
            value: _switchValue,
            onChanged: (value) {
              setState(() {
                _switchValue = value;
              });
              widget.onChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }
}