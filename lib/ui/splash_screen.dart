import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // تست طولانی
  static const int kDisplaySeconds = 120; // 2 دقیقه
  static const double kLogoSize = 360;
  static const double kTopOffset = 72;

  late final AnimationController _ac;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _ac, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
    _next();
  }

  Future<void> _next() async {
    await Future.delayed(const Duration(seconds: kDisplaySeconds));
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('selected_language');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, savedLang == null ? '/language' : '/main');
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // رنگ‌های لوگو
    const cyan   = Color(0xFF00E5FF);
    const purple = Color(0xFF8752FF);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // هاله‌ها (پحو‌تر از قبل)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.27,
            left: MediaQuery.of(context).size.width * 0.20,
            child: _GlowBlob(color: cyan.withOpacity(0.18), size: 440),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            right: MediaQuery.of(context).size.width * 0.18,
            child: _GlowBlob(color: purple.withOpacity(0.18), size: 420),
          ),

          Center(
            child: Transform.translate(
              offset: const Offset(0, -kTopOffset),
              child: ScaleTransition(
                scale: Tween(begin: 0.94, end: 1.0).animate(_scale),
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: kLogoSize,
                        height: kLogoSize,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      // متن گرادیانی کم‌رنگ با سایه نرم
                      const _GradientTitle(
                        text: 'loopa vpn',
                        from: Color(0xCC00E5FF), // CC = opacity ~ 80%
                        to:   Color(0xCC8752FF),
                        fontSize: 44,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

// متن گرادیانی + سایه نرم
class _GradientTitle extends StatelessWidget {
  final String text;
  final Color from;
  final Color to;
  final double fontSize;

  const _GradientTitle({
    required this.text,
    required this.from,
    required this.to,
    this.fontSize = 42,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [from, to],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    // برای سایه‌ی زیر متن یک بار متن را تیره می‌کشیم، بعد روی آن گرادیان می‌گذاریم
    return Stack(
      alignment: Alignment.center,
      children: [
        // سایه نرم
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.black.withOpacity(0.65),
            shadows: const [
              Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black54),
            ],
          ),
        ),
        // متن گرادیانی فِید
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) =>
              gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }
}
