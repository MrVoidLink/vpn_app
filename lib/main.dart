import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

import 'theme/app_theme.dart';
import 'services/locale_service.dart';

// صفحات
import 'ui/splash_screen.dart';
import 'ui/language_screen.dart';
import 'ui/start_screen.dart';
import 'ui/main_screen.dart';

// لیست زبان‌ها (ثابت خودمان)
import 'constants/app_locales.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleService.init(); // زبان ذخیره‌شده را لود می‌کند
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // با تغییر زبان، اپ زنده رفرش می‌شود
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleService.locale,
      builder: (_, loc, __) {
        return MaterialApp(
          title: 'VPN Client',
          debugShowCheckedModeBanner: false,

          // چندزبانه
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            LocaleNamesLocalizationsDelegate(), // نمایش نام بومی زبان‌ها
          ],
          supportedLocales: kSupportedLocales,
          locale: loc, // همان زبانی که کاربر انتخاب کرده

          // تم
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,

          // ناوبری
          home: const SplashScreen(),
          routes: {
            '/language': (_) => const LanguageScreen(),
            '/start': (_) => const StartScreen(),
            '/main': (_) => const MainScreen(),
          },
        );
      },
    );
  }
}
