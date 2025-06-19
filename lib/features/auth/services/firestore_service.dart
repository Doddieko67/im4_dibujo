class UserModel {
  final String uid;
  final String username;
  final int points;
  final int level;
  final List<String> savedTutorials;
  final String? profileImage; // 👈 Este campo ahora permite null

  UserModel({
    required this.uid,
    required this.username,
    required this.points,
    required this.level,
    required this.savedTutorials,
    this.profileImage, // 👈 nullable
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      username: map['username'] as String,
      points: map['points'] as int,
      level: map['level'] as int,
      savedTutorials: List<String>.from(map['savedTutorials'] ?? []),
      profileImage: map['profileImage'], // puede ser null
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'points': points,
      'level': level,
      'savedTutorials': savedTutorials,
      'profileImage': profileImage, // puede ser null
    };
  }
}

extension UserModelCopy on UserModel {
  UserModel copyWith({
    String? username,
    int? points,
    int? level,
    List<String>? savedTutorials,
    String? profileImage,
  }) {
    return UserModel(
      uid: uid,
      username: username ?? this.username,
      points: points ?? this.points,
      level: level ?? this.level,
      savedTutorials: savedTutorials ?? this.savedTutorials,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
