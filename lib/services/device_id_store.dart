import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdStore {
  static const _k = 'device_id_initial';

  /// اگر وجود داشت همون رو می‌ده؛ وگرنه می‌سازه و ذخیره می‌کنه.
  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_k);
    if (existing != null && existing.isNotEmpty) return existing;

    // (اختیاری) اگر قبلاً کلید قدیمی داشتی اینجا مایگریت کن:
    // final legacy = prefs.getString('legacy_device_id');
    // if (legacy != null && legacy.isNotEmpty) { await prefs.setString(_k, legacy); return legacy; }

    final id = const Uuid().v4(); // فعلاً ساده و پایدار
    await prefs.setString(_k, id);
    return id;
  }

  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_k) ?? (await getOrCreate());
  }
}
