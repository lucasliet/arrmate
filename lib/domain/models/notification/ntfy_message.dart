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
    return NtfyMessage(
      id: json['id'] as String? ?? '',
      time: json['time'] as int? ?? 0,
      event: json['event'] as String? ?? 'message',
      topic: json['topic'] as String? ?? '',
      title: json['title'] as String?,
      message: json['message'] as String?,
      priority: json['priority'] as int?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      click: json['click'] as String?,
    );
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
