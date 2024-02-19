
class Task {
  final String task;
  final DateTime? due;

  Task(this.task, this.due);

  Task.fromMap(Map<String, dynamic> item):
        task=item["task"], due= DateTime.tryParse(item["due"]);

  Map<String, Object> toMap(){
    return {'task':task,'due': due.toString()};
  }
}