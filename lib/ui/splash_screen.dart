import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  /// زمان نمایش اسپلش (پیش‌فرض 1 دقیقه)
  final Duration duration;

  const SplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _timer;
  String _nextRoute = '/language'; // مقدار پیش‌فرض: بار اول

  static const _localeKey = 'app_locale'; // مطابق locale_service.dart

  @override
  void initState() {
    super.initState();

    // انیمیشن
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack));

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _fadeCtrl.forward();
      _scaleCtrl.forward();
    });

    // تعیین مسیر بعد از اسپلش بر اساس ذخیره بودن زبان
    _resolveNextRoute().then((_) {
      // ناوبری بعد از مدت مشخص
      _timer = Timer(widget.duration, () {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(_nextRoute);
      });
    });
  }

  Future<void> _resolveNextRoute() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final code = sp.getString(_localeKey);
      // اگر زبان ست شده بود → برو main؛ وگرنه language
      _nextRoute = (code != null && code.isNotEmpty) ? '/main' : '/language';
    } catch (_) {
      _nextRoute = '/language';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تم تیره ثابت
    const bgTop = Color(0xFF0F1220);
    const bgBottom = Color(0xFF0A0D18);
    const neonPurple = Color(0xFF6C63FF);
    const neonCyan = Color(0xFF00C2FF);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bgTop, bgBottom],
              ),
            ),
          ),

          const _GlowBlob(
            offset: Offset(-140, -120),
            size: 280,
            color: neonPurple,
            opacity: 0.20,
          ),
          const _GlowBlob(
            offset: Offset(160, 220),
            size: 260,
            color: neonCyan,
            opacity: 0.18,
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [neonPurple, neonCyan],
                        ).createShader(rect),
                        child: const Text(
                          'loopa vpn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Colors.white, // توسط ShaderMask پوشانده می‌شود
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Opacity(
                        opacity: 0.78,
                        child: Text(
                          'One loop. Endless connection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
            child: const Opacity(
              opacity: 0.5,
              child: Text(
                'v1.0.0',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// گلوب محو پس‌زمینه
class _GlowBlob extends StatelessWidget {
  final Offset offset;
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
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
            color: color.withOpacity(opacity),
          ),
        ),
      ),
    );
  }
}
