// lib/services/user_service.dart
// Centralized user profile & subscription service for Firestore (MVP-ready)
// Compatible with: firebase_auth ^6.x, cloud_firestore ^6.x

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _secure = const FlutterSecureStorage();

  /// ✅ Getterهای کاربردی
  /// UID کاربر فعلی؛ اگر لاگین نیست، رشته خالی می‌دهد.
  String get uid => _auth.currentUser?.uid ?? '';
  /// آیا کاربر ساین‌این شده است؟
  bool get isSignedIn => _auth.currentUser != null;

  /// Path: users/{uid}
  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Path: users/{uid}/devices/{deviceId}
  DocumentReference<Map<String, dynamic>> _deviceRef(String uid, String deviceId) =>
      _userRef(uid).collection('devices').doc(deviceId);

  /// ساخت/ورود کاربر مهمان و به‌روزرسانی فیلدهای پایه
  Future<User> ensureGuestUser({
    required String language,
    required String appVersion,
    required String platform,
    required String deviceModel,
  }) async {
    final current = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    final uid = current.uid;

    final userDoc = await _userRef(uid).get();

    if (!userDoc.exists) {
      final now = FieldValue.serverTimestamp();
      await _userRef(uid).set({
        'planType': 'free',
        'subscription': {
          'startAt': null,
          'activatedAt': null,
          'expiresAt': null,
          'source': null,
          'codeId': null,
        },
        'tokenId': null,
        'language': language,
        'createdAt': now,
        'lastSeenAt': now,
        'appVersion': appVersion,
        'platform': platform,
        'deviceModel': deviceModel,
        'defaultServerId': null,
        'favorites': <String>[],
        'status': 'active',
        'notes': null,
        'stats': {
          'totalSessions': 0,
          'totalBytes': 0,
          'lastServerId': null,
        },
      }, SetOptions(merge: false));
    } else {
      await _userRef(uid).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
        'language': language,
        'appVersion': appVersion,
        'platform': platform,
        'deviceModel': deviceModel,
      });
    }

    return current;
  }

  /// deviceId محلی برای ثبت در پروفایل (در صورت نیاز)
  Future<String> getOrCreateDeviceId() async {
    const key = 'device_id';
    var id = await _secure.read(key: key);
    if (id == null || id.isEmpty) {
      id = _db.collection('_').doc().id;
      await _secure.write(key: key, value: id);
    }
    return id;
  }

  /// ثبت/به‌روزرسانی دستگاه فعلی زیر users/{uid}/devices/{deviceId}
  Future<void> registerCurrentDevice({
    String? overrideDeviceId,
    String? overrideModel,
    String? overridePlatform,
    String? overrideAppVersion,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No signed-in user');
    }

    final deviceId = overrideDeviceId ?? await getOrCreateDeviceId();
    String platform = overridePlatform ?? (Platform.isAndroid ? 'android' : 'ios');
    String model = overrideModel ?? 'Unknown';
    String appVersion = overrideAppVersion ?? '1.0.0';

    try {
      final info = DeviceInfoPlugin();
      if (overrideModel == null) {
        if (Platform.isAndroid) {
          final ai = await info.androidInfo;
          model = ai.model ?? 'Android';
        } else if (Platform.isIOS) {
          final ii = await info.iosInfo;
          model = ii.utsname.machine ?? 'iPhone';
        }
      }
    } catch (_) {}

    try {
      if (overrideAppVersion == null) {
        final pkg = await PackageInfo.fromPlatform();
        appVersion = pkg.version;
      }
    } catch (_) {}

    await _deviceRef(uid, deviceId).set({
      'deviceId': deviceId,
      'model': model,
      'platform': platform,
      'appVersion': appVersion,
      'addedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
      'active': true,
    }, SetOptions(merge: true));

    await _userRef(uid).update({
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// به‌روزرسانی اشتراک کاربر پس از فعال‌سازی توکن (local-side helper)
  Future<void> applyToken({
    required String codeId,
    required String tokenId,
    required int days,
    required String plan,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    final startAtServer = FieldValue.serverTimestamp();
    final expiresAt = Timestamp.fromDate(
      DateTime.now().toUtc().add(Duration(days: days)),
    );

    await _userRef(uid).set({
      'planType': plan,
      'subscription': {
        'startAt': startAtServer,
        'activatedAt': startAtServer,
        'expiresAt': expiresAt,
        'source': 'token',
        'codeId': codeId,
      },
      'tokenId': tokenId,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateStats({
    int? bytes,
    String? serverId,
    bool incrementSession = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    final updates = <String, dynamic>{
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
    if (bytes != null) updates['stats.totalBytes'] = FieldValue.increment(bytes);
    if (serverId != null) updates['stats.lastServerId'] = serverId;
    if (incrementSession) updates['stats.totalSessions'] = FieldValue.increment(1);

    await _userRef(uid).update(updates);
  }

  Future<void> setDefaultServer(String serverId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    await _userRef(uid).update({
      'defaultServerId': serverId,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleFavorite(String serverId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    final snap = await _userRef(uid).get();
    final favorites = List<String>.from((snap.data()?['favorites'] ?? []) as List);
    final has = favorites.contains(serverId);

    await _userRef(uid).update({
      'favorites': has
          ? FieldValue.arrayRemove([serverId])
          : FieldValue.arrayUnion([serverId]),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String status) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    await _userRef(uid).update({
      'status': status,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ تغییر زبان بدون دست‌زدن به سایر فیلدها
  Future<void> setLanguage(String language) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('No signed-in user');

    await _userRef(uid).update({
      'language': language,
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream() {
    final id = _auth.currentUser?.uid;
    if (id == null) return const Stream.empty();
    return _userRef(id).snapshots();
    // اگر می‌خوای بدون uid هم استریم خالی بده:
    // return id == null ? const Stream.empty() : _userRef(id).snapshots();
  }

  Future<Map<String, dynamic>?> fetchUserOnce() async {
    final id = _auth.currentUser?.uid;
    if (id == null) return null;
    final doc = await _userRef(id).get();
    return doc.data();
  }
}
