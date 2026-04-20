class UserModel {
  final String id;
  final String username;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id:        json['id'] as String,
        username:  json['username'] as String,
        fullName:  json['full_name'] as String? ?? '',
        role:      json['role'] as String? ?? 'user',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id':         id,
        'username':   username,
        'full_name':  fullName,
        'role':       role,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  bool get isAdmin    => role == 'admin';
  bool get isHelpdesk => role == 'helpdesk' || role == 'admin';
  bool get isUser     => role == 'user';
}
