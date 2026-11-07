class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isError': isError,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedTimestamp;
    final rawTimestamp = map['timestamp'];
    if (rawTimestamp is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp != null && rawTimestamp.runtimeType.toString().contains('Timestamp')) {
      // Handles Firestore Timestamp dynamically
      parsedTimestamp = (rawTimestamp as dynamic).toDate() as DateTime;
    } else {
      parsedTimestamp = DateTime.now();
    }

    return ChatMessage(
      id: docId ?? map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: map['text']?.toString() ?? '',
      isUser: map['isUser'] == true,
      timestamp: parsedTimestamp,
      isError: map['isError'] == true,
    );
  }
}
