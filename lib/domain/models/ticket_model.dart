class TicketModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String createdBy;
  final String? assignedTo;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined fields
  final String? creatorName;
  final String? assigneeName;

  const TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdBy,
    this.assignedTo,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.creatorName,
    this.assigneeName,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
        id:            json['id'] as String,
        title:         json['title'] as String,
        description:   json['description'] as String? ?? '',
        status:        json['status'] as String? ?? 'open',
        priority:      json['priority'] as String? ?? 'medium',
        createdBy:     json['created_by'] as String,
        assignedTo:    json['assigned_to'] as String?,
        attachmentUrl: json['attachment_url'] as String?,
        createdAt:     DateTime.parse(json['created_at'] as String),
        updatedAt:     DateTime.parse(json['updated_at'] as String),
        creatorName:   json['profiles']?['full_name'] as String?,
        assigneeName:  json['assignee']?['full_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title':          title,
        'description':    description,
        'status':         status,
        'priority':       priority,
        'created_by':     createdBy,
        'assigned_to':    assignedTo,
        'attachment_url': attachmentUrl,
      };

  TicketModel copyWith({
    String? status,
    String? assignedTo,
    String? priority,
  }) =>
      TicketModel(
        id:            id,
        title:         title,
        description:   description,
        status:        status ?? this.status,
        priority:      priority ?? this.priority,
        createdBy:     createdBy,
        assignedTo:    assignedTo ?? this.assignedTo,
        attachmentUrl: attachmentUrl,
        createdAt:     createdAt,
        updatedAt:     DateTime.now(),
        creatorName:   creatorName,
        assigneeName:  assigneeName,
      );
}
