class OrigamiInstruction {
  final String id;
  final String userId;
  final String figureType;
  final String drawingImageUrl;
  final List<String> steps;
  final List<String> referenceImages;
  final String template;
  final DateTime createdAt;

  OrigamiInstruction({
    required this.id,
    required this.userId,
    required this.figureType,
    required this.drawingImageUrl,
    required this.steps,
    required this.referenceImages,
    required this.template,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'figureType': figureType,
      'drawingImageUrl': drawingImageUrl,
      'steps': steps,
      'referenceImages': referenceImages,
      'template': template,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory OrigamiInstruction.fromMap(Map<String, dynamic> map) {
    return OrigamiInstruction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      figureType: map['figureType'] ?? '',
      drawingImageUrl: map['drawingImageUrl'] ?? '',
      steps: List<String>.from(map['steps'] ?? []),
      referenceImages: List<String>.from(map['referenceImages'] ?? []),
      template: map['template'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}