class Task {
  final int? id;
  final String task;
  final String status;
  final int taskListId;
  final int? recurrenceId;

  Task(this.id, this.task, this.status, this.taskListId, {this.recurrenceId});

  @override
  String toString() {
    return 'Task{id: $id, task: $task, status: $status, taskListId: $taskListId, recurrenceId: $recurrenceId}';
  }

  Task.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        task = item["task"],
        status = item["status"],
        taskListId = item["taskListId"],
        recurrenceId = item["recurrence_id"];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'status': status,
      'taskListId': taskListId,
      'recurrence_id': recurrenceId,
    };
  }
}
