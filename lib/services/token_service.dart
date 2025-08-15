import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore, FieldValue, Timestamp, SetOptions
import 'package:firebase_auth/firebase_auth.dart';

import 'user_service.dart';
import 'device_id_store.dart';

// ✅ اضافه‌شده برای ریلیز دیوایس
import 'dart:convert';
import 'package:http/http.dart' as http;

// ⬇️ اضافه‌شده: آدرس واقعی بک‌اند/ورسل خودت رو اینجا بگذار
const String kApiBase = 'https://vpn-admin-panel-chi.vercel.app';

class TokenService {
  TokenService._();
  static final instance = TokenService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  /// اعمال/فعال‌سازی توکن روی حساب و دستگاه فعلی
  /// - users/{uid} و users/{uid}/devices/{deviceId} را به‌روزرسانی می‌کند (plan کامل + aliasهای فلت + subscription.* برای پنل)
  /// - دستگاه را زیر codes/{CODE}/devices ثبت می‌کند و activeDevices را (در صورت جدید بودن) افزایش می‌دهد
  /// - اگر روی خود codes/{CODE} activatedAt/expiresAt نبود، ست می‌کند
  /// - در codes/{code}/activations/{uid_deviceId} لاگ می‌سازد
  Future<Map<String, dynamic>?> applyToken(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty) {
      throw Exception('Code is empty');
    }

    // Anonymous session ok
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    if (_uid.isEmpty) throw Exception('No user');

    final deviceId = await DeviceIdStore.get();
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final codeRef = _db.collection('codes').doc(code);
    final userRef = _db.collection('users').doc(_uid);
    final userDeviceRef = userRef.collection('devices').doc(deviceId);
    final codeDeviceRef = codeRef.collection('devices').doc('${_uid}_$deviceId');
    final activationRef = codeRef.collection('activations').doc('${_uid}_$deviceId');

    await _db.runTransaction((tx) async {
      // 1) خواندن سند کُد
      final codeSnap = await tx.get(codeRef);
      if (!codeSnap.exists) {
        throw Exception('Invalid code: not found');
      }
      final cdata = (codeSnap.data() as Map<String, dynamic>?) ?? {};

      // plan/ظرفیت/منبع
      final planType = (cdata['type'] ?? cdata['plan'] ?? 'premium').toString();
      final String source = (cdata['source'] ?? 'code').toString();
      final int? maxDevices = _asIntNullable(cdata['maxDevices']);
      final int? validForDays = _asIntNullable(cdata['validForDays']);

      // expiry: ترجیح با خود کُد؛ در غیر این صورت از validForDays
      int? expiresAtMs = _normalizeEpochMs(cdata['expiresAt'] ?? cdata['expiry']);
      if (expiresAtMs == null && validForDays != null && validForDays > 0) {
        expiresAtMs = now.add(Duration(days: validForDays)).millisecondsSinceEpoch;
      }

      // اگر منقضی، خطا
      if (expiresAtMs != null && expiresAtMs <= nowMs) {
        throw Exception('Code expired');
      }

      // activatedAt
      final bool hasActivatedAt = cdata['activatedAt'] != null || cdata['activatedAtTs'] != null;
      final int activatedAtMs = hasActivatedAt
          ? (_normalizeEpochMs(cdata['activatedAt']) ?? nowMs)
          : nowMs;

      // 2) وضعیت دستگاه زیر codes/{CODE}/devices  🔧(پچ‌شده)
      final codeDevSnap = await tx.get(codeDeviceRef);
      final Map<String, dynamic> codeDevData =
          (codeDevSnap.data() as Map<String, dynamic>?) ?? {};
      final bool wasActive = codeDevSnap.exists &&
          (codeDevData['isActive'] == true || codeDevData['status'] == 'active');

      // ظرفیت اگر تعریف شده و دستگاه "قبلاً active نبوده"، چک شود
      if (maxDevices != null && !wasActive) {
        final int currentlyUsed = _asIntNullable(cdata['activeDevices']) ?? 0;
        if (currentlyUsed >= maxDevices) {
          throw Exception('Code device capacity reached');
        }
      }

      // 3) متادیتای کُد (lean)
      final Map<String, dynamic> codeMerge = {
        'source': source,
        if (!hasActivatedAt) ...{
          'activatedAt': activatedAtMs, // فقط ms
          'status': 'active',
        },
        if (cdata['type'] == null) 'type': planType, // فقط type، plan لازم نیست
      };
      final bool hasExpiresAtOnCode = cdata['expiresAt'] != null || cdata['expiry'] != null;
      if (expiresAtMs != null && !hasExpiresAtOnCode) {
        codeMerge['expiresAt'] = expiresAtMs; // فقط ms
      }
      tx.set(codeRef, codeMerge, SetOptions(merge: true));

      // 4) لینک/فعال‌سازی دستگاه زیر codes/{CODE}/devices — همیشه merge  🔧(پچ‌شده)
      tx.set(codeDeviceRef, {
        'uid': _uid,
        'deviceId': deviceId,
        if (codeDevData['createdAt'] == null) 'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'isActive': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // اگر قبلاً active نبود (جدید یا از released برگشته) → شمارنده را +1 کن
      if (!wasActive) {
        tx.set(codeRef, {
          'activeDevices': FieldValue.increment(1),
          'status': 'active',
        }, SetOptions(merge: true));
      }

      // 5) users/{uid} — plan + aliasها + ✅ subscription.*
      final Map<String, dynamic> planObj = {
        'type': planType,
        'source': source,
        'status': 'active',
        'codeId': code,
        if (validForDays != null) 'validForDays': validForDays,
        if (maxDevices != null) 'maxDevices': maxDevices,
        'activatedAt': Timestamp.fromMillisecondsSinceEpoch(activatedAtMs),
        if (expiresAtMs != null)
          'expiresAt': Timestamp.fromMillisecondsSinceEpoch(expiresAtMs),
      };

      tx.set(userRef, {
        'currentCode': code,

        // aliasهای فلت
        'tokenId': code,
        'codeId': code,
        if (validForDays != null) 'validForDays': validForDays,
        if (maxDevices != null) 'maxDevices': maxDevices,
        if (expiresAtMs != null) 'expiresAt': expiresAtMs, // فقط ms
        'source': source,
        'planType': planType,
        'status': 'active',
        'lastSeenAt': FieldValue.serverTimestamp(),

        // plan جدید
        'plan': planObj,

        // ✅ mirror برای پنل فعلی
        'subscription': {
          'codeId': code,
          'source': source,
          if (expiresAtMs != null) 'expiresAt': expiresAtMs, // ms
        },
      }, SetOptions(merge: true));

      // 6) users/{uid}/devices/{deviceId} (lean)
      tx.set(userDeviceRef, {
        'code': code,
        'tokenId': code,
        'status': 'active',
        'isActive': true,
        'linkedCodeId': code,
        'planType': planType,
        'activatedAt': Timestamp.fromMillisecondsSinceEpoch(activatedAtMs),
        // تاریخ انقضا روی device لازم نیست؛ اگر می‌خوای برگردونیم، همین‌جا یک خط اضافه می‌کنیم.
        'claimedAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 7) لاگ اکتیویشن
      tx.set(activationRef, {
        'uid': _uid,
        'deviceId': deviceId,
        'planType': planType,
        'source': source,
        'activatedAt': Timestamp.fromMillisecondsSinceEpoch(activatedAtMs),
        if (expiresAtMs != null)
          'expiresAt': Timestamp.fromMillisecondsSinceEpoch(expiresAtMs),
        'at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // خلاصه برای UI
    return getActiveCodeSummary();
  }

  /// برای سازگاری با کد قدیمی
  Future<void> linkCodeToCurrentDevice(String code) async {
    await UserService.instance.linkCodeToCurrentDevice(code);
  }

  /// خلاصه‌ی کُد فعال
  Future<Map<String, dynamic>?> getActiveCodeSummary() async {
    if (_uid.isEmpty) return null;

    final uref = _db.collection('users').doc(_uid);
    final usnap = await uref.get();
    final udata = (usnap.data() as Map<String, dynamic>?) ?? {};

    // پیدا کردن کد
    String? code = (udata['currentCode'] as String?)?.trim();
    if (code == null || code.isEmpty) {
      final devs = await uref.collection('devices').get();
      for (final d in devs.docs) {
        final m = (d.data() as Map<String, dynamic>? ?? {});
        final c = (m['code'] ?? m['tokenId'] ?? m['subscriptionCode']);
        if (c is String && c.trim().isNotEmpty) {
          code = c.trim();
          break;
        }
      }
    }
    if (code == null || code.isEmpty) return null;

    final codeRef = _db.collection('codes').doc(code);
    final codeSnap = await codeRef.get();
    if (!codeSnap.exists) {
      return {
        'code': code,
        'type': null,
        'maxDevices': null,
        'usedDevices': null,
        'remaining': null,
        'expiresAt': null,
        'devices': const [],
      };
    }

    final cdata = (codeSnap.data() as Map<String, dynamic>?) ?? {};
    final int? maxDevices = _asIntNullable(cdata['maxDevices']);
    int? usedDevices = _asIntNullable(cdata['activeDevices']);

    // لیست دستگاه‌های claim شده (اختیاری)
    List<Map<String, dynamic>> devices = [];
    try {
      final cds = await codeRef.collection('devices').get();
      devices = cds.docs.map((d) => {'id': d.id}).toList();
      usedDevices ??= cds.docs.length;
    } catch (_) {}

    final int? remaining =
    (maxDevices == null || usedDevices == null) ? null : (maxDevices - usedDevices);

    return {
      'code': code,
      'type': cdata['type'] ?? cdata['plan'],
      'source': cdata['source'],
      'maxDevices': maxDevices,
      'usedDevices': usedDevices ?? 0,
      'remaining': remaining,
      'expiresAt': _normalizeEpochMs(cdata['expiresAt'] ?? cdata['expiry']),
      'devices': devices,
    };
  }

  // ✅ فقط اضافه‌شده — متد ریلیز بدون تغییر چیز دیگر
  /// آزاد کردن/Unlink یک دستگاه از کُد فعال
  ///
  /// ساختار فعلی codes/{codeId}/devices دارای DocID به‌شکل `${uid}_${deviceId}` است (طبق applyToken).
  /// این متد اول با `deviceId` ساده چک می‌کند، اگر نبود `${uid}_${deviceId}` را امتحان می‌کند
  /// و همان DocID را به API `/api/release-device` ارسال می‌کند.
  Future<Map<String, dynamic>> releaseDevice({
    required String codeId,
    required String deviceId,
    String? apiBase,
  }) async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('No user');
    }

    // تشخیص DocID واقعی در Firestore
    final codeRef = _db.collection('codes').doc(codeId);
    final devRefPlain = codeRef.collection('devices').doc(deviceId);
    final devRefCombo = codeRef.collection('devices').doc('${uid}_$deviceId');

    String deviceDocIdToRelease = deviceId;
    try {
      final snapPlain = await devRefPlain.get();
      if (!snapPlain.exists) {
        final snapCombo = await devRefCombo.get();
        if (snapCombo.exists) {
          deviceDocIdToRelease = '${uid}_$deviceId';
        }
      }
    } catch (_) {
      // اگر خطا رخ داد، با همان ورودی ادامه می‌دهیم
    }

    // آدرس API — از ثابت استفاده می‌کنیم مگر اینکه apiBase پاس داده شود
    final String base = (apiBase != null && apiBase.trim().isNotEmpty)
        ? apiBase.trim()
        : kApiBase;

    final uri = Uri.parse('$base/api/release-device');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'codeId': codeId,
        'deviceId': deviceDocIdToRelease,
      }),
    );

    if (resp.statusCode != 200) {
      final msg = resp.body.isNotEmpty ? resp.body : 'Release failed';
      throw Exception('Release failed (${resp.statusCode}) @ $base: $msg');
    }

    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // -------------------- helpers --------------------
  int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _normalizeEpochMs(dynamic v) {
    if (v == null) return null;
    if (v is int) return v < 100000000000 ? v * 1000 : v;
    if (v is double) {
      final n = v.toInt();
      return n < 100000000000 ? n * 1000 : n;
    }
    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) return _normalizeEpochMs(asInt);
      final dt = DateTime.tryParse(v);
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return null;
  }
}
