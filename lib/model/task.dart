class Task {
  final int? id;
  final String task;
  final String status;
  final int taskListId;

  Task(this.id, this.task, this.status, this.taskListId);

  @override
  String toString() {
    return 'Task{id: $id, task: $task, status: $status, taskListId: $taskListId}';
  }

  Task.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        task = item["task"],
        status = item["status"],
        taskListId = item["taskListId"];

  Map<String, dynamic> toMap() {
    return {'task': task, 'id': id, 'status': status, 'taskListId': taskListId};
  }
}
