import 'origami_step.dart';

class OrigamiFigure {
  final String title;
  final String description;
  final List<OrigamiStep> steps;

  OrigamiFigure({
    required this.title,
    required this.description,
    required this.steps,
  });
}
