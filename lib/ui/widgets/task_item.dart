import 'package:flutter/material.dart';
import 'package:taskswiper/model/status.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/ui/widgets/actionable_icon_button.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onReopenTaskPressed;

  const TaskItem(this.task,
      {Key? key, this.onEditPressed, this.onDeletePressed, this.onReopenTaskPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(15.0),
      decoration: buildBoxDecoration(),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildButtonRow(),
              const SizedBox(height: 10),
              Text(
                task.task,
                style: TextStyle(
                  fontSize: calculateFontSize(task.task.length),
                  color: task.status == Status.completed
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ],
          ),
          if (task.status == Status.completed)
            buildReopenTaskButton(),
           if (task.status == Status.completed)
            buildCompletedWatermark(),
        ],
      ),
    );
  }

  double calculateFontSize(int textLength) {
    if (textLength <= 10) {
      return 50.0; // Very short text
    } else if (textLength <= 20) {
      return 40.0; // Short text
    } else if (textLength <= 40) {
      return 30.0; // Medium text
    } else {
      return 16.0; // Long text
    }
  }

  Positioned buildReopenTaskButton() {
    return Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton(
                onPressed:  onReopenTaskPressed,
                child: const Text('Reopen task'),
              ),
            ),
          );
  }

  Positioned buildCompletedWatermark() {
    return Positioned.fill(
            child: FittedBox(
              fit: BoxFit.none,
              child: Transform.rotate(
                angle: -45 * 3.1415926535 / 180,
                child: Text(
                  "COMPLETED",
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
  }

  BoxDecoration buildBoxDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[200]!,
          Colors.grey[100]!,
          Colors.grey[200]!,
        ],
        stops: const [0.1, 0.5, 0.9],
      ),
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Row buildButtonRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            ActionableIconButton(
              Icons.edit,
              onEditPressed!,
              disabled: task.status == Status.completed,
            ),
            ActionableIconButton(
              Icons.delete,
              onDeletePressed!,
              disabled: task.status == Status.completed,
            ),
          ],
        ),
      ],
    );
  }

  Row buildUncompleteButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            ActionableIconButton(
              Icons.edit,
              onEditPressed!,
              disabled: task.status == Status.completed,
            ),
            ActionableIconButton(
              Icons.delete,
              onDeletePressed!,
              disabled: task.status == Status.completed,
            ),
          ],
        ),
      ],
    );
  }
}
