class NotificationReply {
  int id;
  String reply;

  Map<String, dynamic> toMap() {
    return {'id': id, 'reply': reply};
  }

  factory NotificationReply.fromMap(Map<String, dynamic> map) {
    return NotificationReply(
      id: map['id'] as int,
      reply: map['reply'] as String,
    );
  }

  NotificationReply({required this.id, required this.reply});
}
