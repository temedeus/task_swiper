
class Task {
  final int? id;
  final String task;
  final DateTime? due;

  Task(this.id, this.task, this.due);

  Task.fromMap(Map<String, dynamic> item):
        id=item["id"], task=item["task"], due= DateTime.tryParse(item["due"]);

  Map<String, dynamic> toMap(){
    return {'task':task,'due': due?.toString(), 'id':id};
  }
}