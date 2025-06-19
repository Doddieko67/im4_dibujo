/// Modelo que representa un tutorial de origami
class OrigamiModel {
  final String id;
  final String title;
  final String videoUrl;
  final String difficulty; // "Fácil", "Media", "Difícil"

  OrigamiModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.difficulty,
  });

  /// Devuelve los puntos según la dificultad del tutorial
  int get difficultyPoints {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return 10;
      case 'media':
        return 20;
      case 'difícil':
        return 40;
      default:
        return 0;
    }
  }

  /// Convierte un mapa de Firestore a un objeto OrigamiModel
  factory OrigamiModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OrigamiModel(
      id: documentId,
      title: map['title'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      difficulty: map['difficulty'] ?? 'Fácil',
    );
  }

  /// Convierte el modelo a un mapa para subirlo a Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoUrl': videoUrl,
      'difficulty': difficulty,
    };
  }

  /// Devuelve un emoji según dificultad (para interfaz)
  String get difficultyEmoji {
    switch (difficulty.toLowerCase()) {
      case 'fácil':
        return '🟢';
      case 'media':
        return '🟡';
      case 'difícil':
        return '🔴';
      default:
        return '⚪';
    }
  }
}
