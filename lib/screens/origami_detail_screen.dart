import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/origami_instruction.dart';

class OrigamiDetailScreen extends StatelessWidget {
  final OrigamiInstruction instruction;

  const OrigamiDetailScreen({
    super.key,
    required this.instruction,
  });

  Future<void> _downloadInstructions(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/origami_${instruction.figureType}_${DateTime.now().millisecondsSinceEpoch}.txt');
      
      final content = '''
INSTRUCCIONES DE ORIGAMI - ${instruction.figureType}
======================================

PASOS:
${instruction.steps.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}

PLANTILLA:
${instruction.template}

REFERENCIAS:
${instruction.referenceImages.join('\n')}

Creado el: ${instruction.createdAt.toString()}
''';
      
      await file.writeAsString(content);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Instrucciones descargadas en: ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descargar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(instruction.figureType),
        backgroundColor: const Color.fromARGB(255, 45, 218, 200),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadInstructions(context),
            tooltip: 'Descargar instrucciones',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del dibujo original
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dibujo original:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: Image.network(
                          instruction.drawingImageUrl,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 64),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creado el: ${_formatDate(instruction.createdAt)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
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
                    ...instruction.steps.asMap().entries.map((entry) => 
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
                      instruction.template,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Referencias
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔍 Búsquedas recomendadas:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...instruction.referenceImages.map((ref) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search,
                              size: 16,
                              color: Color.fromARGB(255, 45, 218, 200),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ref,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Botón de descarga
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _downloadInstructions(context),
                icon: const Icon(Icons.download),
                label: const Text('Descargar Instrucciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}