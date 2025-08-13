import 'dart:async';
import 'package:flutter/material.dart';
import 'glass_card.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late final PageController _ctrl;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _index = (_index + 1) % 3;
      _ctrl.animateToPage(
        _index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView(
        controller: _ctrl,
        children: const [
          _BannerCard(
            title: 'Premium speed unlocked',
            subtitle: 'Try 7 days free — cancel anytime',
            icon: Icons.flash_on_rounded,
          ),
          _BannerCard(
            title: 'Stay private, stay free',
            subtitle: 'No logs • No limits on privacy',
            icon: Icons.lock_outline_rounded,
          ),
          _BannerCard(
            title: 'New servers live',
            subtitle: 'Lower ping in EU & US',
            icon: Icons.public_rounded,
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _BannerCard({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Opacity(opacity: 0.8, child: Text(subtitle, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
