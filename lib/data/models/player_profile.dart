// lib/data/models/player_profile.dart

enum AuthProvider { google, apple, email }

class PlayerProfile {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? email;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  const PlayerProfile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.email,
    required this.provider,
    required this.createdAt,
    required this.lastSeenAt,
  });

  PlayerProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? email,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) =>
      PlayerProfile(
        userId: userId ?? this.userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        email: email ?? this.email,
        provider: provider ?? this.provider,
        createdAt: createdAt ?? this.createdAt,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (email != null) 'email': email,
        'provider': provider.name,
        'createdAt': createdAt.toIso8601String(),
        'lastSeenAt': lastSeenAt.toIso8601String(),
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        email: json['email'] as String?,
        provider: AuthProvider.values.byName(json['provider'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerProfile &&
          userId == other.userId &&
          displayName == other.displayName &&
          avatarUrl == other.avatarUrl &&
          email == other.email &&
          provider == other.provider &&
          createdAt == other.createdAt &&
          lastSeenAt == other.lastSeenAt;

  @override
  int get hashCode => Object.hash(
        userId, displayName, avatarUrl, email, provider, createdAt, lastSeenAt);
}
