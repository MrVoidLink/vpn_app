import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/bottom_sheet_scaffold.dart';
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
      builder: (_) => const _SettingsSheetBody(),
    );
  }
}

class _SettingsSheetBody extends StatefulWidget {
  const _SettingsSheetBody();

  @override
  State<_SettingsSheetBody> createState() => _SettingsSheetBodyState();
}

class _SettingsSheetBodyState extends State<_SettingsSheetBody> {
  // Quiet hours فقط UI (لوکال)
  TimeOfDay _from = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _to   = const TimeOfDay(hour: 8,  minute: 0);

  final ctrl = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    const Gradient brandGradient = AppGradients.primaryGlow;

    return BottomSheetScaffold(
      title: 'Settings',
      childrenBuilder: (ctx) => [
        // -------- Theme mode --------
        GlassCard(
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                RadioListTile<AppThemePref>(
                  title: const Text('Dark'),
                  value: AppThemePref.dark,
                  groupValue: ctrl.preference,
                  onChanged: (v) async {
                    await ctrl.setPreference(v!);
                    setS(() {}); setState(() {});
                  },
                ),
                RadioListTile<AppThemePref>(
                  title: const Text('Light'),
                  value: AppThemePref.light,
                  groupValue: ctrl.preference,
                  onChanged: (v) async {
                    await ctrl.setPreference(v!);
                    setS(() {}); setState(() {});
                  },
                ),
                RadioListTile<AppThemePref>(
                  title: const Text('Follow system'),
                  value: AppThemePref.system,
                  groupValue: ctrl.preference,
                  onChanged: (v) async {
                    await ctrl.setPreference(v!);
                    setS(() {}); setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // -------- Brand preview --------
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Brand colors', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Container(
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: brandGradient,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'loopa vpn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _ColorChip(label: 'Primary',   color: AppColors.primary),
                  SizedBox(width: 12),
                  _ColorChip(label: 'Secondary', color: AppColors.secondary),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // -------- Quiet hours (UI-only) --------
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quiet hours', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _from,
                        );
                        if (picked != null) setState(() => _from = picked);
                      },
                      child: Text('From: ${_fmt(_from)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _to,
                        );
                        if (picked != null) setState(() => _to = picked);
                      },
                      child: Text('To: ${_fmt(_to)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Opacity(
                opacity: 0.7,
                child: Text(
                  'Only visual here; no persistence.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
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
    final int rgb = color.value & 0x00FFFFFF;
    final String hex = '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label\n$hex',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
