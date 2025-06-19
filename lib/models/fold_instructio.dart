import 'package:flutter/material.dart';

class FoldInstruction {
  final Offset start;
  final Offset end;
  final String hint;

  const FoldInstruction({
    required this.start,
    required this.end,
    required this.hint,
  });
}
