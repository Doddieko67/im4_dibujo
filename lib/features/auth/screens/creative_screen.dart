//Dibujo
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import '../../../screens/origami_instructions_screen.dart';

class CreativeScreen extends StatefulWidget {
  const CreativeScreen({super.key});

  @override
  State<CreativeScreen> createState() => _CreativeScreenState();
}

class _CreativeScreenState extends State<CreativeScreen> {
  final GlobalKey repaintKey = GlobalKey();
  List<DrawPoint?> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;
  bool isErasing = false;
  List<String> savedDrawings = [];

  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.brown,
  ];

  Future<void> saveDrawing() async {
    try {
      if (repaintKey.currentContext == null) {
        print("❌ repaintKey context es null");
        return;
      }

      final renderObject = repaintKey.currentContext!.findRenderObject();

      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        print("❌ RenderObject no es RenderRepaintBoundary");
        return;
      }

      final boundary = renderObject as RenderRepaintBoundary;

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
        return saveDrawing();
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final directory = await getApplicationDocumentsDirectory();
        final String savedPath =
            '${directory.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(savedPath);
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          setState(() {
            savedDrawings.add(savedPath);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Dibujo guardado!'),
              action: SnackBarAction(
                label: 'Analizar con IA',
                onPressed: () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrigamiInstructionsScreen(drawingPath: savedPath),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("⚠️ Error al guardar el dibujo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el dibujo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponte creativo'),
        backgroundColor: const Color.fromARGB(255, 45, 218, 200),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            tooltip: 'Ver dibujos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DrawingsGalleryScreen(drawings: savedDrawings),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar dibujo',
            onPressed: saveDrawing,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Limpiar lienzo',
            onPressed: () {
              setState(() {
                points.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanDown: (details) {
                  setState(() {
                    points.add(DrawPoint(
                      points: details.localPosition,
                      paint: Paint()
                        ..color = isErasing ? Colors.white : selectedColor
                        ..strokeWidth = isErasing ? strokeWidth * 2 : strokeWidth
                        ..strokeCap = StrokeCap.round
                        ..blendMode = isErasing ? BlendMode.clear : BlendMode.srcOver,
                      isEraser: isErasing,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    points.add(DrawPoint(
                      points: details.localPosition,
                      paint: Paint()
                        ..color = isErasing ? Colors.white : selectedColor
                        ..strokeWidth = isErasing ? strokeWidth * 2 : strokeWidth
                        ..strokeCap = StrokeCap.round
                        ..blendMode = isErasing ? BlendMode.clear : BlendMode.srcOver,
                      isEraser: isErasing,
                    ));
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    points.add(null);
                  });
                },
                child: RepaintBoundary(
                  key: repaintKey,
                  child: Container(
                    color: Colors.white,
                    child: CustomPaint(
                      painter: _DrawingPainter(points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: colors
                      .map(
                        (c) => GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = c;
                              isErasing = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                width:
                                    selectedColor == c && !isErasing ? 3 : 1,
                                color: Colors.black,
                              ),
                            ),
                            width: 30,
                            height: 30,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Grosor:'),
                    Slider(
                      value: strokeWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: strokeWidth.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          strokeWidth = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.brush),
                      label: const Text('Pincel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isErasing ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isErasing = false;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Borrador'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isErasing ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isErasing = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isErasing ? 'Modo borrador activo' : 'Modo pincel activo',
                  style: TextStyle(
                    color: isErasing ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DrawPoint {
  final Offset points;
  final Paint paint;
  final bool isEraser;

  DrawPoint({
    required this.points, 
    required this.paint,
    this.isEraser = false,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<DrawPoint?> points;

  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // Crear una capa para que BlendMode.clear funcione
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Dibujar fondo blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      if (current != null && next != null) {
        canvas.drawLine(current.points, next.points, current.paint);
      } else if (current != null && next == null) {
        canvas.drawPoints(ui.PointMode.points, [current.points], current.paint);
      }
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

class DrawingsGalleryScreen extends StatelessWidget {
  final List<String> drawings;

  const DrawingsGalleryScreen({super.key, required this.drawings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis dibujos')),
      body: drawings.isEmpty
          ? const Center(child: Text('No hay dibujos guardados.'))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: drawings.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrigamiInstructionsScreen(
                          drawingPath: drawings[index],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(drawings[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 45, 218, 200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.smart_toy,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
