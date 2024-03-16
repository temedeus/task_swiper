import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SeparatorWithLabel extends StatelessWidget {
  final String label;

  const SeparatorWithLabel({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
        ),
      ],
    );
  }
}