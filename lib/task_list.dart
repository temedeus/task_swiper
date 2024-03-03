
class TaskList {
  final int? id;
  final String title;

  TaskList(this.id, this.title);

  @override
  String toString() {
    return 'TaskList{id: $id, title: $title}';
  }

  TaskList.fromMap(Map<String, dynamic> item):
        id=item["id"], title=item["title"];

  Map<String, dynamic> toMap(){
    return {'title':title, 'id':id};
  }
}