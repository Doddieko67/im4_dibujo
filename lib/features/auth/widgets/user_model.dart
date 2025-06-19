class UserModel {
  final String uid;
  final String username;
  final int points;
  final int level;
  final List<String> savedTutorials;

  // Constructor con parámetros requeridos y con llaves para claridad
  const UserModel({
    required this.uid,
    required this.username,
    required this.points,
    required this.level,
    required this.savedTutorials,
  });

  // Convierte el objeto a un Map para guardarlo o enviarlo
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'points': points,
        'level': level,
        'savedTutorials': savedTutorials,
      };

  // Crea una instancia a partir de un Map, con validaciones simples
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      points: map['points'] ?? 0,
      level: map['level'] ?? 0,
      savedTutorials: List<String>.from(map['savedTutorials'] ?? []),
    );
  }

  // Puedes agregar un método toString para facilitar la depuración
  @override
  String toString() {
    return 'UserModel(uid: $uid, username: $username, points: $points, level: $level, savedTutorials: $savedTutorials)';
  }

  // Opcional: método para copiar el objeto con algunos cambios (copyWith)
  UserModel copyWith({
    String? uid,
    String? username,
    int? points,
    int? level,
    List<String>? savedTutorials,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      points: points ?? this.points,
      level: level ?? this.level,
      savedTutorials: savedTutorials ?? this.savedTutorials,
    );
  }
}
