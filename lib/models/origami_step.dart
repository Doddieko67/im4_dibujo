import 'dart:typed_data';

class OrigamiStep {
  final int stepNumber;
  final String instruction;
  final Uint8List? image;
  final bool hasImage;

  OrigamiStep({
    required this.stepNumber,
    required this.instruction,
    this.image,
    this.hasImage = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'instruction': instruction,
      'hasImage': hasImage,
      // Note: image bytes are not stored in Firestore due to size
    };
  }

  factory OrigamiStep.fromMap(Map<String, dynamic> map) {
    return OrigamiStep(
      stepNumber: map['stepNumber'] ?? 0,
      instruction: map['instruction'] ?? '',
      hasImage: map['hasImage'] ?? false,
    );
  }
}