import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_app/services/user_service.dart'; // برای saveUserLanguage

// 🔧 فقط این تابع اضافه شد
Future<void> saveUserLanguage(String code) async {
  // ذخیره لوکال برای دفعات بعد
  final sp = await SharedPreferences.getInstance();
  await sp.setString('app_language', code);

  // ذخیره در فایراستور
  await UserService.instance.setLanguage(code);
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'code': 'en', 'label': 'English'},
      {'code': 'fa', 'label': 'فارسی'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select language"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          return ListTile(
            title: Text(lang['label']!),
            onTap: () async {
              // ذخیره در Firestore + SharedPreferences
              await saveUserLanguage(lang['code']!);

              // هدایت به صفحه اصلی
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/main');
              }
            },
          );
        },
      ),
    );
  }
}
