class Event {
  final String id;
  final String categoryId;
  late String _name;
  String? description;
  int clickCount;
  final DateTime createdAt;
  final List<DateTime> logs;

  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;

  String get name => _name;
  set name(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('事件名称不能为空');
    }
    if (value.length > maxNameLength) {
      throw ArgumentError('事件名称不能超过$maxNameLength个字符');
    }
    _name = value.trim();
  }

  Event({
    required this.id,
    required this.categoryId,
    required String name,
    this.description,
    required this.clickCount,
    required this.createdAt,
    List<DateTime>? logs,
  }) : logs = logs ?? [] {
    this.name = name;
    if (description != null && description!.length > maxDescriptionLength) {
      throw ArgumentError('事件描述不能超过$maxDescriptionLength个字符');
    }
    if (clickCount < 0) {
      throw ArgumentError('点击次数不能为负数');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'click_count': clickCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      // 不在主表中存储日志，它们将单独存储在 event_logs 表中
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      clickCount: map['click_count'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      logs: (map['logs'] as List<dynamic>?)
              ?.map((timestamp) =>
                  DateTime.fromMillisecondsSinceEpoch(timestamp as int))
              .toList() ??
          [],
    );
  }
}

class EventLog {
  final String id;
  final DateTime timestamp;

  EventLog({required this.id, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {'id': id, 'timestamp': timestamp.toIso8601String()};
  }

  factory EventLog.fromMap(Map<String, dynamic> map) {
    return EventLog(id: map['id'], timestamp: DateTime.parse(map['timestamp']));
  }
}
