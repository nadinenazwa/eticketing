class CommentModel {
  final String id;
  final String ticketId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  // Optional joined
  final String? authorName;

  const CommentModel({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.authorName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id:         json['id'] as String,
        ticketId:   json['ticket_id'] as String,
        authorId:   json['author_id'] as String,
        content:    json['content'] as String,
        createdAt:  DateTime.parse(json['created_at'] as String),
        authorName: json['profiles']?['full_name'] as String?,
      );
}
