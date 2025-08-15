import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Firebase options (توسط flutterfire ساخته شده)
import 'firebase_options.dart';

// Theme  ← با alias تا تداخل AppTheme برطرف شود
import 'theme/app_theme.dart' as design;

// Screens
import 'ui/splash_screen.dart';
import 'ui/language_screen.dart';
import 'ui/start_screen.dart';
// ← این دو تا را alias می‌کنیم تا تداخل اسم «MainScreen»/«SettingsScreen» قطع شود
import 'ui/main_screen.dart' as mainui;
import 'ui/settings_screen.dart' as settingsui;

// Services
import 'services/theme_service.dart';
import 'services/user_service.dart';
import 'services/device_identity_channel.dart'; // ⬅️ فقط از سرویس استفاده می‌کنیم
import 'services/device_id_store.dart'; // ⬅️ اضافه شد

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ ساخت یا خواندن شناسه پایدار قبل از بوت کاربر
  await DeviceIdStore.getOrCreate();

  // 2) ساخت/ورود کاربر مهمان + ثبت دستگاه
  await _bootstrapUser();

  // 3) Init theme preferences (dark/light/system/timeBased)
  await ThemeController.instance.init();

  // ✅ تست موقتی: از نیتیو claim بگیر و در کنسول Flutter چاپ کن
  try {
    final claim = await getDeviceClaim(); // از سرویس می‌آید
    debugPrint('DeviceClaim(F): $claim');
  } catch (e) {
    debugPrint('DeviceClaim(F) ERROR: $e');
  }

  runApp(const LoopaApp());
}

// ⬇️ تابع بوت کاربر (جمع‌آوری اطلاعات و صدا زدن UserService)
Future<void> _bootstrapUser() async {
  final pkg = await PackageInfo.fromPlatform();
  final di = DeviceInfoPlugin();

  final platform = Platform.isAndroid ? 'android' : 'ios';
  final model = Platform.isAndroid
      ? (await di.androidInfo).model ?? 'Android'
      : (await di.iosInfo).utsname.machine ?? 'iPhone';

  await UserService.instance.ensureGuestUser(
    language: 'fa',              // فعلاً پیش‌فرض؛ بعداً از prefs/lang واقعی می‌گیریم
    appVersion: pkg.version,     // مثل "1.0.0"
    platform: platform,
    deviceModel: model,
  );

  await UserService.instance.registerCurrentDevice();
}

class LoopaApp extends StatelessWidget {
  const LoopaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = ThemeController.instance;

    return AnimatedBuilder(
      animation: themeCtrl,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'loopa vpn',

          // تم‌ها ← با alias
          theme: design.AppTheme.light,
          darkTheme: design.AppTheme.dark,
          themeMode: themeCtrl.themeMode,

          // مسیرها ← استفاده از alias برای اسکرین‌ها
          routes: {
            '/language': (_) => const LanguageScreen(),
            '/start':    (_) => const StartScreen(),
            '/main':     (_) => const mainui.MainScreen(),
            '/settings': (_) => const settingsui.SettingsScreen(),
          },

          // خانه: اسپلش (خودش مقصد بعدی را تعیین می‌کند)
          home: const SplashScreen(),
        );
      },
    );
  }
}
