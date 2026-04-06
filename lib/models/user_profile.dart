class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String username; // URL-safe username
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.username,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username,
        'photoURL': photoURL,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        uid: json['uid'],
        email: json['email'],
        displayName: json['displayName'],
        username: json['username'],
        photoURL: json['photoURL'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  // Generate URL-safe username from display name
  static String generateUsername(String displayName) {
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .replaceAll(RegExp(r'\s+'), '');
  }

  String get profileUrl => 'mylocus.life/$username';
}
