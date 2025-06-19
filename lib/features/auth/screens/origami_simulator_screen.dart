import 'package:flutter/material.dart';
import '/models/origami_figure.dart';

class OrigamiSimulatorScreen extends StatefulWidget {
  final OrigamiFigure figure;

  const OrigamiSimulatorScreen({super.key, required this.figure});

  @override
  State<OrigamiSimulatorScreen> createState() => _OrigamiSimulatorScreenState();
}

class _OrigamiSimulatorScreenState extends State<OrigamiSimulatorScreen> {
  int currentStep = 0;

  void _nextStep() {
    if (currentStep < widget.figure.steps.length - 1) {
      setState(() => currentStep++);
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.figure.steps[currentStep];

    return Scaffold(
      appBar: AppBar(title: Text(widget.figure.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: null, // TODO: Implement CustomPainter
                  child: Container(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(step.instruction, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Anterior'),
                ),
                ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Siguiente'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
