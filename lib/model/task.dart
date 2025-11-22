class Task {
  final int? id;
  final String task;
  final String status;
  final int taskListId;
  final int? recurrenceId;
  final String? createdAt;
  final String? updatedAt;

  Task(
      this.id,
      this.task,
      this.status,
      this.taskListId, {
        this.createdAt,
        this.updatedAt,
        this.recurrenceId,
      });

  @override
  String toString() {
    return 'Task{id: $id, task: $task, status: $status, taskListId: $taskListId, recurrenceId: $recurrenceId, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  Task.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        task = item["task"],
        status = item["status"],
        taskListId = item["taskListId"],
        recurrenceId = item["recurrenceId"],
        createdAt = item["createdAt"],
        updatedAt = item["updatedAt"];

  // To map, include createdAt and updatedAt
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'status': status,
      'taskListId': taskListId,
      'recurrenceId': recurrenceId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
