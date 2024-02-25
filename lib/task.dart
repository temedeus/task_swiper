
class Task {
  final int? id;
  final String task;
  final DateTime? due;

  Task(this.id, this.task, this.due);

  @override
  String toString() {
    return 'Task{id: $id, task: $task, due: $due}';
  }

  Task.fromMap(Map<String, dynamic> item):
        id=item["id"], task=item["task"], due= item["due"] == null ? null : DateTime.tryParse(item["due"]);

  Map<String, dynamic> toMap(){
    return {'task':task,'due': due?.toString(), 'id':id};
  }
}