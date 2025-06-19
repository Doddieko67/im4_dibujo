import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/gemini_service.dart';
import '../services/pollinations_service.dart';
import '../models/origami_instruction.dart';
import '../models/origami_step.dart';
import 'package:url_launcher/url_launcher.dart';

class OrigamiInstructionsScreen extends StatefulWidget {
  final String drawingPath;

  const OrigamiInstructionsScreen({
    super.key,
    required this.drawingPath,
  });

  @override
  State<OrigamiInstructionsScreen> createState() => _OrigamiInstructionsScreenState();
}

class _OrigamiInstructionsScreenState extends State<OrigamiInstructionsScreen> {
  bool isLoading = true;
  bool isGeneratingImages = false;
  String? error;
  String figureType = '';
  List<String> instructions = [];
  List<OrigamiStep> stepsWithImages = [];
  List<String> referenceImages = [];
  String template = '';
  Uint8List? templateImage;
  int currentImageStep = 0;
  int totalSteps = 0;
  
  @override
  void initState() {
    super.initState();
    _analyzeDrawing();
  }

  Future<void> _analyzeDrawing() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Leer la imagen del dibujo
      final file = File(widget.drawingPath);
      final imageBytes = await file.readAsBytes();

      // Analizar la imagen con Gemini
      print('🔍 Analizando imagen con Gemini...');
      figureType = await GeminiService.analyzeDrawing(imageBytes);
      print('🎯 Figura detectada: $figureType');
      
      // Generar instrucciones
      instructions = await GeminiService.generateOrigamiInstructions(
        imageBytes, 
        figureType,
      );
      
      // Generar descripciones para búsqueda de imágenes
      final descriptions = await GeminiService.generateImageDescriptions(figureType);
      referenceImages = descriptions;
      
      // Generar plantilla
      template = await GeminiService.generateOrigamiTemplate(figureType);

      setState(() {
        isLoading = false;
      });

      // Generar imágenes de los pasos automáticamente
      _generateStepImages();

    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error al analizar el dibujo: $e';
      });
    }
  }

  Future<void> _generateStepImages() async {
    if (instructions.isEmpty) return;
    
    setState(() {
      isGeneratingImages = true;
      currentImageStep = 0;
      totalSteps = instructions.length + 1; // +1 para la plantilla
    });

    try {
      // Inicializar lista de pasos sin imágenes
      final List<OrigamiStep> newSteps = [];
      for (int i = 0; i < instructions.length; i++) {
        newSteps.add(OrigamiStep(
          stepNumber: i + 1,
          instruction: instructions[i],
          image: null,
          hasImage: false,
        ));
      }
      
      setState(() {
        stepsWithImages = newSteps;
      });

      // Generar imágenes una por una
      for (int i = 0; i < instructions.length; i++) {
        setState(() {
          currentImageStep = i + 1;
        });

        final step = instructions[i];
        final prompt = '''
Origami instruction step ${i + 1} for making a $figureType:
$step
Show clear paper folding diagram with fold lines and arrows.
Simple white paper on clean background.
Instructional origami diagram style.
''';

        final imageBytes = await PollinationsService.generateImage(
          prompt: prompt,
          width: 512,
          height: 512,
        );

        if (imageBytes != null && imageBytes.isNotEmpty) {
          // Actualizar el paso con la imagen
          setState(() {
            stepsWithImages[i] = OrigamiStep(
              stepNumber: i + 1,
              instruction: instructions[i],
              image: imageBytes,
              hasImage: true,
            );
          });
        }

        // Pequeña pausa entre peticiones
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Generar imagen de la plantilla
      setState(() {
        currentImageStep = totalSteps;
      });
      
      final templateImg = await PollinationsService.generateOrigamiTemplateImage(
        figureType,
        template,
      );

      setState(() {
        templateImage = templateImg;
        isGeneratingImages = false;
        currentImageStep = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Imágenes generadas con éxito!')),
        );
      }
    } catch (e) {
      setState(() {
        isGeneratingImages = false;
        currentImageStep = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar imágenes: $e')),
        );
      }
    }
  }

  Future<void> _saveInstructions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Subir imagen a Firebase Storage
      final file = File(widget.drawingPath);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('drawings')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.png');
      
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Crear instrucción de origami
      final instruction = OrigamiInstruction(
        id: '',
        userId: user.uid,
        figureType: figureType,
        drawingImageUrl: downloadUrl,
        steps: instructions,
        referenceImages: referenceImages,
        template: template,
        createdAt: DateTime.now(),
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('origami_instructions')
          .add(instruction.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Instrucciones guardadas!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _downloadInstructions() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/origami_${figureType}_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final content = '''
INSTRUCCIONES DE ORIGAMI - $figureType
======================================

PASOS:
${instructions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

PLANTILLA:
$template

REFERENCIAS PARA BUSCAR EN INTERNET:
${referenceImages.join('\n')}

Generado el: ${DateTime.now().toString()}
''';
      
      await file.writeAsString(content);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Instrucciones descargadas en: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    }
  }

  Future<void> _searchImages(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.google.com/search?q=$encodedQuery&tbm=isch');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrucciones de Origami'),
        backgroundColor: const Color.fromARGB(255, 45, 218, 200),
        actions: [
          if (!isLoading && error == null) ...[
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: isGeneratingImages ? null : _generateStepImages,
              tooltip: 'Regenerar imágenes',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveInstructions,
              tooltip: 'Guardar instrucciones',
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadInstructions,
              tooltip: 'Descargar instrucciones',
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando tu dibujo con IA...'),
                  SizedBox(height: 8),
                  Text('Esto puede tomar unos segundos.'),
                ],
              ),
            )
          : isGeneratingImages
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('Generando imágenes paso a paso...'),
                      const SizedBox(height: 8),
                      if (totalSteps > 0) ...[
                        Text('Paso $currentImageStep de $totalSteps'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: currentImageStep / totalSteps,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color.fromARGB(255, 45, 218, 200),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text('Esto puede tomar 1-2 minutos.'),
                    ],
                  ),
                )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _analyzeDrawing,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del dibujo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tu dibujo:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: Image.file(File(widget.drawingPath)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Figura detectada: $figureType',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instrucciones paso a paso
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📋 Instrucciones paso a paso:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (stepsWithImages.isNotEmpty) ...[
                                // Mostrar pasos con imágenes
                                ...stepsWithImages.map((step) => 
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Color.fromARGB(255, 45, 218, 200),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${step.stepNumber}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                step.instruction,
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (step.hasImage && step.image != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            constraints: const BoxConstraints(maxHeight: 200),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.memory(
                                                step.image!,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Mostrar solo texto si no hay imágenes
                                ...instructions.asMap().entries.map((entry) => 
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(255, 45, 218, 200),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${entry.key + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Plantilla
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📄 Plantilla sugerida:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                template,
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (templateImage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(maxHeight: 300),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      templateImage!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Referencias con botones para buscar
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🔍 Buscar imágenes de referencia:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Toca en cualquier búsqueda para ver imágenes en Google:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...referenceImages.map((ref) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => _searchImages(ref),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color.fromARGB(255, 45, 218, 200),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.image_search,
                                            size: 20,
                                            color: Color.fromARGB(255, 45, 218, 200),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              ref,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.open_in_new,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveInstructions,
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 45, 218, 200),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _downloadInstructions,
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}