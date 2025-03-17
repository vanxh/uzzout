class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? followerIds;
  final List<String>? followingIds;
  final int followersCount;
  final int followingCount;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
    this.followerIds,
    this.followingIds,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      followerIds:
          json['follower_ids'] != null
              ? List<String>.from(json['follower_ids'])
              : null,
      followingIds:
          json['following_ids'] != null
              ? List<String>.from(json['following_ids'])
              : null,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'follower_ids': followerIds,
      'following_ids': followingIds,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? followerIds,
    List<String>? followingIds,
    int? followersCount,
    int? followingCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followerIds: followerIds ?? this.followerIds,
      followingIds: followingIds ?? this.followingIds,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }
}
