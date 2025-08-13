import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NeonPulseButton extends StatelessWidget {
  final AnimationController controller;
  final VoidCallback onPressed;
  final Widget child;
  const NeonPulseButton({
    super.key,
    required this.controller,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        final spread = lerpDouble(8, 22, t)!;
        final blur = lerpDouble(12, 28, t)!;
        final color = Color.lerp(kNeonPurple, kNeonCyan, t)!;

        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: blur,
                spreadRadius: spread * 0.2,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(26),
              backgroundColor: const Color(0xFF1A1E3F),
              foregroundColor: Colors.white,
            ),
            onPressed: onPressed,
            child: child,
          ),
        );
      },
    );
  }
}
