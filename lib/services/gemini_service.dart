import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GenerativeModel? _model;
  static GenerativeModel? _imageModel;
  
  static GenerativeModel get model {
    if (_model == null) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
    return _model!;
  }

  static GenerativeModel get imageModel {
    if (_imageModel == null) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }
      _imageModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
    }
    return _imageModel!;
  }

  static Future<String> analyzeDrawing(Uint8List imageBytes) async {
    try {
      final prompt = '''
Analiza este dibujo simple y determina qué figura, animal u objeto está representado. 

Mira las formas básicas y líneas del dibujo. Puede ser:
- Animales (perro, gato, pájaro, pez, rana, etc.)
- Objetos (casa, árbol, flor, corazón, estrella, etc.)
- Formas geométricas (triángulo, cuadrado, círculo, etc.)

Responde ÚNICAMENTE con el nombre de la figura en español, sin explicaciones adicionales.
Ejemplos de respuestas válidas: "perro", "casa", "flor", "corazón", "pájaro"

Si realmente no puedes identificar nada, responde: "figura simple"
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final result = response.text?.trim() ?? 'figura simple';
      
      print('📝 Respuesta original de Gemini: "$result"');
      
      // Limpiar la respuesta para que sea solo el nombre de la figura
      final cleanResult = result.toLowerCase()
          .replaceAll(RegExp(r'[^\w\sáéíóúñ]'), '') // Remover puntuación
          .trim();
      
      print('✨ Respuesta limpia: "$cleanResult"');
      
      // Si está vacío o es muy genérico, usar "figura simple"
      if (cleanResult.isEmpty || 
          cleanResult.contains('no reconocida') || 
          cleanResult.contains('no se puede') ||
          cleanResult.length > 30) {
        return 'figura simple';
      }
      
      return cleanResult;
    } catch (e) {
      throw Exception('Error al analizar el dibujo: $e');
    }
  }

  static Future<Map<String, dynamic>> generateOrigamiInstructionsWithImages(
    Uint8List imageBytes,
    String figureType,
  ) async {
    try {
      final prompt = '''
Basándote en esta imagen de un dibujo que representa "$figureType", necesito que:

1. Generes instrucciones detalladas paso a paso para crear un origami de esta figura
2. Para cada paso importante, genera una imagen que muestre cómo debe verse el papel en ese momento

Responde ÚNICAMENTE con un JSON en el siguiente formato:
{
  "steps": [
    {
      "instruction": "Paso 1: Descripción detallada del primer paso",
      "generateImage": true,
      "imagePrompt": "Descripción detallada para generar la imagen del paso 1"
    },
    {
      "instruction": "Paso 2: Descripción detallada del segundo paso",
      "generateImage": true,
      "imagePrompt": "Descripción detallada para generar la imagen del paso 2"
    }
  ],
  "totalSteps": 8
}

Las instrucciones deben ser:
- Claras y precisas en español
- Entre 8-12 pasos
- Cada imagePrompt debe describir cómo se ve el papel de origami en ese paso específico
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text ?? '{}';
      
      try {
        return json.decode(responseText);
      } catch (e) {
        throw Exception('Error al parsear JSON: $responseText');
      }
    } catch (e) {
      throw Exception('Error al generar instrucciones: $e');
    }
  }

  static Future<List<String>> generateOrigamiInstructions(
    Uint8List imageBytes,
    String figureType,
  ) async {
    try {
      return await _generateSimpleInstructions(imageBytes, figureType);
    } catch (e) {
      throw Exception('Error al generar instrucciones: $e');
    }
  }

  static Future<List<String>> _generateSimpleInstructions(
    Uint8List imageBytes,
    String figureType,
  ) async {
    try {
      final prompt = '''
Basándote en esta imagen de un dibujo que representa "$figureType", 
genera instrucciones detalladas paso a paso para crear un origami de esta figura.

Responde con una lista numerada simple, sin formato JSON, algo así:

1. Toma una hoja cuadrada de papel
2. Dobla por la mitad en diagonal
3. Abre y dobla por la otra diagonal
...

Las instrucciones deben ser:
- Claras y precisas en español
- Entre 8-12 pasos
- Orientadas a principiantes
- Específicas para crear un origami de "$figureType"
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final responseText = response.text ?? '';
      
      // Parsear el texto simple a lista
      final lines = responseText.split('\n');
      final steps = <String>[];
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && RegExp(r'^\d+\.').hasMatch(trimmed)) {
          // Remover el número y punto del inicio
          final step = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          if (step.isNotEmpty) {
            steps.add(step);
          }
        }
      }
      
      return steps.isEmpty ? ['No se pudieron generar instrucciones'] : steps;
    } catch (e) {
      throw Exception('Error al generar instrucciones: $e');
    }
  }

  static Future<List<String>> generateImageDescriptions(
    String figureType,
  ) async {
    try {
      final prompt = '''
Genera 5 descripciones diferentes para buscar imágenes de referencia de origami de "$figureType".

Responde con una lista simple, sin JSON, algo así:

1. origami $figureType paso a paso tutorial
2. como hacer origami $figureType instrucciones
3. origami $figureType fácil principiantes
...

Usa español y que sean útiles para buscar imágenes de referencia.
''';

      final content = [
        Content.text(prompt)
      ];

      final response = await model.generateContent(content);
      final responseText = response.text ?? '';
      
      // Parsear el texto simple a lista
      final lines = responseText.split('\n');
      final descriptions = <String>[];
      
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && RegExp(r'^\d+\.').hasMatch(trimmed)) {
          // Remover el número y punto del inicio
          final desc = trimmed.replaceFirst(RegExp(r'^\d+\.\s*'), '');
          if (desc.isNotEmpty) {
            descriptions.add(desc);
          }
        }
      }
      
      // Si no encontramos descripciones, usar algunas por defecto
      if (descriptions.isEmpty) {
        return [
          'origami $figureType paso a paso tutorial',
          'como hacer origami $figureType instrucciones',
          'origami $figureType fácil principiantes',
          'diagrama origami $figureType',
          'tutorial origami $figureType español'
        ];
      }
      
      return descriptions;
    } catch (e) {
      // Devolver descripciones por defecto en caso de error
      return [
        'origami $figureType paso a paso tutorial',
        'como hacer origami $figureType instrucciones',
        'origami $figureType fácil principiantes',
        'diagrama origami $figureType',
        'tutorial origami $figureType español'
      ];
    }
  }

  static Future<String> generateOrigamiTemplate(
    String figureType,
  ) async {
    try {
      final prompt = '''
Genera una descripción detallada de una plantilla de origami para crear "$figureType".
La descripción debe incluir:
- Medidas recomendadas del papel
- Tipo de papel sugerido
- Marcas o líneas de referencia necesarias
- Consejos especiales para esta figura

Responde en español de forma clara y concisa.
''';

      final content = [
        Content.text(prompt)
      ];

      final response = await model.generateContent(content);
      return response.text ?? 'No se pudo generar la plantilla';
    } catch (e) {
      throw Exception('Error al generar plantilla: $e');
    }
  }
  
  static Future<Uint8List?> generateStepImage(String imagePrompt) async {
    try {
      final prompt = '''
Genera una imagen clara y simple que muestre: $imagePrompt

La imagen debe:
- Mostrar papel de origami en el estado descrito
- Ser clara y fácil de entender
- Mostrar las líneas de doblez si es necesario
- Tener un fondo simple
''';

      final content = [
        Content.text(prompt)
      ];

      final response = await imageModel.generateContent(content);
      
      // Buscar la primera parte de imagen en la respuesta
      if (response.candidates.isNotEmpty) {
        final candidate = response.candidates.first;
        if (candidate.content.parts.isNotEmpty) {
          for (final part in candidate.content.parts) {
            if (part is DataPart && part.mimeType.startsWith('image/')) {
              return part.bytes;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error al generar imagen: $e');
      return null;
    }
  }
}