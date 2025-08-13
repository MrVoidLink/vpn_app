import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart'; // برای دسترسی به BrandTheme

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ctrl = ThemeController.instance;

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandTheme>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Appearance (Theme & Brand)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // --- Theme Section ---
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  RadioListTile<AppThemePref>(
                    title: const Text('Dark'),
                    value: AppThemePref.dark,
                    groupValue: ctrl.preference,
                    onChanged: (v) async {
                      await ctrl.setPreference(v!);
                      setState(() {});
                    },
                  ),
                  RadioListTile<AppThemePref>(
                    title: const Text('Light'),
                    value: AppThemePref.light,
                    groupValue: ctrl.preference,
                    onChanged: (v) async {
                      await ctrl.setPreference(v!);
                      setState(() {});
                    },
                  ),
                  RadioListTile<AppThemePref>(
                    title: const Text('Follow system'),
                    value: AppThemePref.system,
                    groupValue: ctrl.preference,
                    onChanged: (v) async {
                      await ctrl.setPreference(v!);
                      setState(() {});
                    },
                  ),
                  RadioListTile<AppThemePref>(
                    title: const Text('Auto by time'),
                    subtitle: Text('Active: ${_fmt(ctrl.from)} → ${_fmt(ctrl.to)}'),
                    value: AppThemePref.timeBased,
                    groupValue: ctrl.preference,
                    onChanged: (v) async {
                      await ctrl.setPreference(v!);
                      setState(() {});
                    },
                  ),
                  if (ctrl.isTimeBased)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: ctrl.from,
                                );
                                if (picked != null) {
                                  await ctrl.setTimeRange(picked, ctrl.to);
                                  setState(() {});
                                }
                              },
                              child: Text('From: ${_fmt(ctrl.from)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: ctrl.to,
                                );
                                if (picked != null) {
                                  await ctrl.setTimeRange(ctrl.from, picked);
                                  setState(() {});
                                }
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
          ),

          const SizedBox(height: 16),

          // --- Brand Preview Section ---
          Text(
            'Brand',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // پیش‌نمایش گرادیان برند
                  Container(
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: brand?.primaryGradient as Gradient?,
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
                    children: [
                      _ColorChip(label: 'Neon Purple', color: kNeonPurple),
                      const SizedBox(width: 12),
                      _ColorChip(label: 'Neon Cyan', color: kNeonCyan),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Opacity(
                    opacity: 0.7,
                    child: Text(
                      'Dark-first • Neon #6C63FF & #00C2FF',
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    String hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
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
