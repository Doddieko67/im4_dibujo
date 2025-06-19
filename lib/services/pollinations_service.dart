import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PollinationsService {
  static const String baseUrl = 'https://image.pollinations.ai/prompt';
  
  static Future<Uint8List?> generateImage({
    required String prompt,
    int width = 512,
    int height = 512,
    String model = 'flux',
    int seed = -1,
  }) async {
    try {
      // Construir la URL con los parámetros
      final encodedPrompt = Uri.encodeComponent(prompt);
      final url = Uri.parse('$baseUrl/$encodedPrompt?width=$width&height=$height&model=$model&seed=$seed');
      
      // Hacer la petición
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error al generar imagen: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error en Pollinations: $e');
      return null;
    }
  }
  
  static Future<List<Uint8List>> generateOrigamiStepImages(
    String figureType,
    List<String> steps,
  ) async {
    final List<Uint8List> images = [];
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final prompt = '''
Origami instruction step ${i + 1} for making a $figureType:
$step
Show clear paper folding diagram with fold lines and arrows.
Simple white paper on clean background.
Instructional origami diagram style.
''';
      
      print('Generando imagen para paso ${i + 1}...');
      final imageBytes = await generateImage(
        prompt: prompt,
        width: 512,
        height: 512,
      );
      
      if (imageBytes != null) {
        images.add(imageBytes);
      } else {
        // Si falla, usar una imagen vacía placeholder
        images.add(Uint8List(0));
      }
      
      // Pequeña pausa entre peticiones para no saturar
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    return images;
  }
  
  static Future<Uint8List?> generateOrigamiTemplateImage(
    String figureType,
    String description,
  ) async {
    final prompt = '''
Origami folding template/pattern for $figureType.
$description
Show paper with dotted fold lines, cut lines if needed.
Flat paper template view from above.
Clear instructional diagram with measurements.
''';
    
    return await generateImage(
      prompt: prompt,
      width: 768,
      height: 768,
    );
  }
}