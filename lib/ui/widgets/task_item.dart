import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskswiper/model/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;

  const TaskItem(this.task, {Key? key, this.onEditPressed, this.onDeletePressed}) : super(key: key);

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
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: onEditPressed,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: onDeletePressed,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10), // Adjust as needed
          SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Set the desired scrolling direction
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