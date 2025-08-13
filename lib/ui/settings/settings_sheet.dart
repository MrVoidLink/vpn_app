import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SettingsSheet {
  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 0.54)
          : Colors.black.withValues(alpha: 0.20),
      builder: (_) => const _GlassSheet(child: SettingsPanel()),
    );
  }
}

class _GlassSheet extends StatelessWidget {
  final Widget child;
  const _GlassSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      builder: (context, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)  // دارک: شیشه تیره
                    : Colors.white.withValues(alpha: 0.85), // لایت: شیشه روشن
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: const [
                  _SheetGrabber(),
                  SettingsPanel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 44, height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white24 : Colors.black26,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// پنل واقعی تنظیمات (Theme + Brand)
class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key});
  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final ctrl = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandTheme>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // عنوان
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded),
              SizedBox(width: 8),
              Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ),

        // --- Theme ---
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              RadioListTile<AppThemePref>(
                title: const Text('Dark'),
                value: AppThemePref.dark,
                groupValue: ctrl.preference,
                onChanged: (v) async { await ctrl.setPreference(v!); setState(() {}); },
              ),
              RadioListTile<AppThemePref>(
                title: const Text('Light'),
                value: AppThemePref.light,
                groupValue: ctrl.preference,
                onChanged: (v) async { await ctrl.setPreference(v!); setState(() {}); },
              ),
              RadioListTile<AppThemePref>(
                title: const Text('Follow system'),
                value: AppThemePref.system,
                groupValue: ctrl.preference,
                onChanged: (v) async { await ctrl.setPreference(v!); setState(() {}); },
              ),
              RadioListTile<AppThemePref>(
                title: const Text('Auto by time'),
                subtitle: Text('Active: ${_fmt(ctrl.from)} → ${_fmt(ctrl.to)}'),
                value: AppThemePref.timeBased,
                groupValue: ctrl.preference,
                onChanged: (v) async { await ctrl.setPreference(v!); setState(() {}); },
              ),
              if (ctrl.isTimeBased)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: ctrl.from);
                            if (picked != null) { await ctrl.setTimeRange(picked, ctrl.to); setState(() {}); }
                          },
                          child: Text('From: ${_fmt(ctrl.from)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: ctrl.to);
                            if (picked != null) { await ctrl.setTimeRange(ctrl.from, picked); setState(() {}); }
                          },
                          child: Text('To: ${_fmt(ctrl.to)}'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- Brand preview (نمایشی)
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Brand', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: brand?.primaryGradient ??
                      const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        colors: [kNeonPurple, kNeonCyan],
                      ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'loopa vpn',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _ColorChip(label: 'Neon Purple', color: kNeonPurple),
                  SizedBox(width: 12),
                  _ColorChip(label: 'Neon Cyan', color: kNeonCyan),
                ],
              ),
              const SizedBox(height: 8),
              const Opacity(
                opacity: 0.7,
                child: Text('Dark-first • Neon #6C63FF & #00C2FF', textAlign: TextAlign.start),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmt(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text(
          '$label\n$hex',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
