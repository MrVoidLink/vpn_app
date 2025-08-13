import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ConnectState { disconnected, connecting, connected }

class AuroraConnectButton extends StatefulWidget {
  final double size; // ← می‌تونیم از بیرون کوچیک‌ترش کنیم (الان 190 در Main)
  final ConnectState state;
  final VoidCallback? onTap;

  const AuroraConnectButton({
    super.key,
    this.size = 220,
    required this.state,
    this.onTap,
  });

  @override
  State<AuroraConnectButton> createState() => _AuroraConnectButtonState();
}

class _AuroraConnectButtonState extends State<AuroraConnectButton>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spin.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final state = widget.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scale = 1.0 + (_breath.value * 0.02); // تنفس خیلی لطیف
    final coreFill = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.92); // لایت: روشن‌تر
    final coreBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06); // لایت: دور خط ظریف
    final textColor = isDark ? Colors.white : Colors.black87;
    final glowColor = state == ConnectState.connected ? kNeonCyan : kNeonPurple;
    final glowIntensity = state == ConnectState.connecting
        ? (isDark ? 0.50 : 0.28)
        : (isDark ? 0.35 : 0.22);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _breath]),
        builder: (_, __) {
          return Transform.scale(
            scale: scale,
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // گلو پس‌زمینه
                  _GlowCircle(
                    radius: size * 0.50,
                    color: glowColor,
                    intensity: glowIntensity,
                  ),

                  // هسته شیشه‌ای
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        width: size * 0.82,
                        height: size * 0.82,
                        decoration: BoxDecoration(
                          color: coreFill,
                          border: Border.all(color: coreBorder),
                          shape: BoxShape.circle,
                          boxShadow: isDark
                              ? null
                              : [
                            // در لایت برای مرزبندی بهتر
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              spreadRadius: 0,
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  // حلقه و اوربیترها
                  CustomPaint(
                    size: Size.square(size),
                    painter: _AuroraPainter(
                      phase: _spin.value,
                      state: state,
                      light: !isDark,
                    ),
                  ),

                  // برچسب وسط
                  _CenterLabel(
                    state: state,
                    color: textColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double phase; // 0..1
  final ConnectState state;
  final bool light;

  _AuroraPainter({required this.phase, required this.state, required this.light});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // حلقه گرادیانی
    final ring = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: const [kNeonPurple, kNeonCyan, kNeonPurple],
        stops: const [0, 0.5, 1],
        transform: GradientRotation(phase * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.9))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(c, r * 0.86, ring);

    // لایت: خط دور خیلی ظریف برای وضوح
    if (light) {
      final hair = Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(c, r * 0.86, hair);
    }

    // اسپینر connecting
    if (state == ConnectState.connecting) {
      final spinner = Paint()
        ..shader = SweepGradient(
          startAngle: phase * 2 * math.pi,
          endAngle: phase * 2 * math.pi + math.pi * 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            light ? Colors.black.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.86))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.86),
        phase * 2 * math.pi,
        math.pi * 0.9,
        false,
        spinner,
      );
    }

    // اوربیترها
    final orbitR = r * 0.70;
    for (var i = 0; i < 3; i++) {
      final ang = (phase + i / 3) * 2 * math.pi;
      final p = Offset(c.dx + orbitR * math.cos(ang), c.dy + orbitR * math.sin(ang));
      final dot = Paint()
        ..color = (light ? Colors.black : Colors.white).withValues(alpha: 0.70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(p, 3, dot);
    }

    // هایلایت شیشه
    final gloss = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: c.translate(0, -6), radius: r * 0.9),
        -math.pi * 0.85,
        math.pi * 0.35,
      );
    canvas.drawPath(path, gloss);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.state != state || oldDelegate.light != light;
}

class _GlowCircle extends StatelessWidget {
  final double radius;
  final Color color;
  final double intensity; // 0..1
  const _GlowCircle({required this.radius, required this.color, this.intensity = 0.35});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // بدون const
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: intensity),
        ),
      ),
    );
  }
}

class _CenterLabel extends StatelessWidget {
  final ConnectState state;
  final Color color;
  const _CenterLabel({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (state) {
      case ConnectState.disconnected:
        text = 'CONNECT';
        break;
      case ConnectState.connecting:
        text = 'CONNECTING…';
        break;
      case ConnectState.connected:
        text = 'DISCONNECT';
        break;
    }
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        fontSize: 14,
      ),
    );
  }
}
