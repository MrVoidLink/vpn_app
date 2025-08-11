import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import '../services/locale_service.dart';
import '../constants/app_locales.dart'; // ← اضافه

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;

  List<Locale> get _allLocales => kSupportedLocales; // ← اینجا

  @override
  Widget build(BuildContext context) {
    final localeNames = LocaleNames.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Select language')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _allLocales.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final loc = _allLocales[i];
                  final code = loc.languageCode;
                  final label = localeNames?.nameOf(code) ?? code;

                  final selected = _selected == code;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // اگر warning با withOpacity می‌دهد، فعلاً نادیده بگیر؛ هشداره
                    tileColor: selected
                        ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.12)
                        : null,
                    title: Text(label),
                    subtitle: Text(code),
                    trailing:
                    selected ? const Icon(Icons.check_circle) : null,
                    onTap: () => setState(() => _selected = code),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () async {
                  await LocaleService.setLocale(_selected!);
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushReplacementNamed('/start');
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
