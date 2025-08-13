import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_id_store.dart'; // منبع یکتا برای deviceId

class UserService {
  UserService._();
  static final instance = UserService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  /// ایجاد یا ورود کاربر مهمان + ذخیره اطلاعات پایه کاربر
  Future<void> ensureGuestUser({
    required String language,
    required String appVersion,
    required String platform,
    required String deviceModel,
  }) async {
    if (_auth.currentUser == null) {
      final cred = await _auth.signInAnonymously();
      // ignore: avoid_print
      print('Signed in as guest: ${cred.user!.uid}');
    }

    await _db.collection('users').doc(uid).set({
      'language': language,
      'appVersion': appVersion,
      'platform': platform,
      'deviceModel': deviceModel,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'status': 'active',
    }, SetOptions(merge: true));
  }

  /// ثبت یا به‌روزرسانی دستگاه فعلی (idempotent). کلاینت Active نمی‌کند.
  Future<void> registerCurrentDevice() async {
    if (uid.isEmpty) return;

    // فقط از شناسه پایدار شروع اپ استفاده کن
    final deviceId = await DeviceIdStore.get();

    // اطلاعات دستگاه
    final di = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final model = Platform.isAndroid
        ? (await di.androidInfo).model
        : (await di.iosInfo).utsname.machine;

    final data = <String, dynamic>{
      'deviceId': deviceId,
      'platform': platform,
      'model': model,
      'appVersion': pkg.version,
      // فعال‌سازی فقط بعد از apply-token سمت سرور انجام می‌شود
      'isActive': false,
      'registeredAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set(data, SetOptions(merge: true));
  }

  /// تنظیم زبان کاربر (برای LanguageScreen)
  Future<void> setLanguage(String code) async {
    final u = uid;
    if (u.isEmpty) return;

    await _db.collection('users').doc(u).set({
      'language': code,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// لیست دستگاه‌ها
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    if (uid.isEmpty) return [];
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// به‌روزرسانی آخرین زمان دیده شدن یک دستگاه
  Future<void> updateLastSeen(String deviceId) async {
    if (uid.isEmpty) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set({'lastSeenAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true));
  }

  /// حذف یک دستگاه
  Future<void> removeDevice(String deviceId) async {
    if (uid.isEmpty) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .delete();
  }
}
