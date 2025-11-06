/// 用户账户模型（本地存储）
class UserAccount {
  final int? id;
  final String username;
  final String password; // 实际应用中应该加密存储
  final String? email;
  final String? avatar;
  final String? nickname;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserAccount({
    this.id,
    required this.username,
    required this.password,
    this.email,
    this.avatar,
    this.nickname,
    DateTime? createdAt,
    this.lastLoginAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'avatar': avatar,
      'nickname': nickname,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      email: map['email'] as String?,
      avatar: map['avatar'] as String?,
      nickname: map['nickname'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
    );
  }

  UserAccount copyWith({
    int? id,
    String? username,
    String? password,
    String? email,
    String? avatar,
    String? nickname,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
