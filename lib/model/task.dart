class Task {
  final int? id;
  final String task;
  final DateTime? due;
  final int taskListId;

  Task(this.id, this.task, this.due, this.taskListId);

  @override
  String toString() {
    return 'Task{id: $id, task: $task, due: $due, $taskListId: $taskListId}';
  }

  Task.fromMap(Map<String, dynamic> item)
      : id = item["id"],
        task = item["task"],
        due = item["due"] == null ? null : DateTime.tryParse(item["due"]),
        taskListId = item["taskListId"];

  Map<String, dynamic> toMap() {
    return {'task': task, 'due': due?.toString(), 'id': id, 'taskListId': taskListId};
  }
}
