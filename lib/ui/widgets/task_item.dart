import 'package:flutter/material.dart';
import 'package:taskswiper/model/task.dart';
import 'package:taskswiper/ui/widgets/actionable_icon_button.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final bool completed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const TaskItem(this.task, this.completed,
      {Key? key, this.onEditPressed, this.onDeletePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  ActionableIconButton(Icons.edit, onEditPressed!),
                  ActionableIconButton(Icons.delete, onDeletePressed!),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              task.task,
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black87,
              ),
            ),
          )
        ],
      ),
    );
  }
}
