class Task {
  final int? id;
  final String task;
  final int taskListId;

  Task(this.id, this.task, this.taskListId);

  @override
  String toString() {
    return 'Task{id: $id, task: $task, $taskListId: $taskListId}';
  }

  Task.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        task = item["task"],
        taskListId = item["taskListId"];

  Map<String, dynamic> toMap() {
    return {'task': task, 'id': id, 'taskListId': taskListId};
  }
}
