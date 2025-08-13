import 'dart:ui';
import 'package:flutter/material.dart';

class GlowBlob extends StatelessWidget {
  final Offset offset;
  final double size;
  final Color color;
  final double opacity;
  const GlowBlob({
    super.key,
    required this.offset,
    required this.size,
    required this.color,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
