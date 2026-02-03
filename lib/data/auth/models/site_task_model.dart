import 'package:app_bhb/data/auth/models/TaskItem.dart';

class SiteTask {
  List<TaskItem> items;

  SiteTask({
    required this.items,
  });

  Map<String, dynamic> toMap() => {
    'items': items.map((e) => e.toMap()).toList(),
  };

  factory SiteTask.fromMap(Map<String, dynamic> map) {
    return SiteTask(
      items: (map['items'] as List)
          .map((e) => TaskItem.fromMap(e))
          .toList(),
    );
  }
}

