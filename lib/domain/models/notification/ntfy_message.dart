import 'package:equatable/equatable.dart';

class NtfyMessage extends Equatable {
  final String id;
  final int time;
  final String event;
  final String topic;
  final String? title;
  final String? message;
  final int? priority;
  final List<String>? tags;
  final String? click;

  const NtfyMessage({
    required this.id,
    required this.time,
    required this.event,
    required this.topic,
    this.title,
    this.message,
    this.priority,
    this.tags,
    this.click,
  });

  factory NtfyMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id == null || id is! String || id.isEmpty) {
      throw FormatException('NtfyMessage: missing or invalid "id" field');
    }

    final time = json['time'];
    if (time == null || time is! int) {
      throw FormatException('NtfyMessage: missing or invalid "time" field');
    }

    final event = json['event'];
    if (event == null || event is! String || event.isEmpty) {
      throw FormatException('NtfyMessage: missing or invalid "event" field');
    }

    final topic = json['topic'];
    if (topic == null || topic is! String || topic.isEmpty) {
      throw FormatException('NtfyMessage: missing or invalid "topic" field');
    }

    List<String>? tags;
    final rawTags = json['tags'];
    if (rawTags != null) {
      if (rawTags is List) {
        tags = rawTags.whereType<String>().toList();
      } else {
        throw FormatException('NtfyMessage: "tags" field must be a list');
      }
    }

    return NtfyMessage(
      id: id,
      time: time,
      event: event,
      topic: topic,
      title: json['title'] as String?,
      message: json['message'] as String?,
      priority: json['priority'] as int?,
      tags: tags,
      click: json['click'] as String?,
    );
  }

  static NtfyMessage? tryParse(Map<String, dynamic> json) {
    try {
      return NtfyMessage.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'event': event,
      'topic': topic,
      if (title != null) 'title': title,
      if (message != null) 'message': message,
      if (priority != null) 'priority': priority,
      if (tags != null) 'tags': tags,
      if (click != null) 'click': click,
    };
  }

  bool get isMessage => event == 'message';
  bool get isOpen => event == 'open';
  bool get isKeepalive => event == 'keepalive';

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(time * 1000);

  @override
  List<Object?> get props => [id, time, event, topic, title, message];
}
