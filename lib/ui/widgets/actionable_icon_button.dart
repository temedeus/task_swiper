import 'package:flutter/material.dart';

class ActionableIconButton extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onPressed;
  final bool disabled;

  const ActionableIconButton(this.iconData, this.onPressed,
      {Key? key, this.disabled = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(iconData),
      color: disabled ? Colors.white70 : Colors.black,
      onPressed: disabled ? null : onPressed,
    );
  }
}
