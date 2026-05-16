class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.activityType,
    required this.passwordHash,
    this.pinHash = '',
    this.dailyGoal = 0,
    this.photoUrl,
  });

  final String uid;
  final String fullName;
  final String email;
  final String activityType;
  final int dailyGoal;
  final String passwordHash;
  final String pinHash;
  final String? photoUrl;

  String get firstName => fullName.trim().split(' ').first;
  String get initial => firstName.isEmpty ? 'S' : firstName[0].toUpperCase();

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? activityType,
    int? dailyGoal,
    String? passwordHash,
    String? pinHash,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      activityType: activityType ?? this.activityType,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      passwordHash: passwordHash ?? this.passwordHash,
      pinHash: pinHash ?? this.pinHash,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
      email: (json['email'] ?? json['phone'] ?? '') as String,
      activityType: json['activityType'] as String,
      dailyGoal: json['dailyGoal'] as int? ?? 0,
      passwordHash: json['passwordHash'] as String? ?? '',
      pinHash: json['pinHash'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'activityType': activityType,
      'dailyGoal': dailyGoal,
      'passwordHash': passwordHash,
      'pinHash': pinHash,
      'photoUrl': photoUrl,
    };
  }
}
