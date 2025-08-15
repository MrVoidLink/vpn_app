// lib/services/user_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_id_store.dart';

class UserService {
  UserService._();
  static final instance = UserService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  // ---------------------- Auth & Profile ----------------------

  /// ورود ناشناس و ساخت/به‌روزرسانی پروفایل کاربر.
  Future<void> ensureGuestUser({
    required String language,
    required String appVersion,
    required String platform,
    required String deviceModel,
  }) async {
    if (_auth.currentUser == null) {
      final cred = await _auth.signInAnonymously();
      print('Signed in as guest: ${cred.user!.uid}');
    }
    if (uid.isEmpty) return;

    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();

    if (userSnap.exists) {
      await userRef.set({
        'language': language,
        'appVersion': appVersion,
        'platform': platform,
        'deviceModel': deviceModel,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));
    } else {
      await userRef.set({
        'language': language,
        'appVersion': appVersion,
        'platform': platform,
        'deviceModel': deviceModel,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'plan': {
          'type': 'free',
          'source': 'app',
          'status': 'inactive',
        },
        'planType': 'free',
        'source': 'app',
        'codeId': null,
        'tokenId': null,
        'subscription': {
          'codeId': null,
          'source': 'app',
          'expiresAt': null, // ms
        },
      }, SetOptions(merge: true));
    }

    await _ensureAdminAliasesFromPlan(userRef);
  }

  /// ثبت یا به‌روزرسانی دستگاه
  Future<void> registerCurrentDevice() async {
    if (uid.isEmpty) return;

    final deviceId = await DeviceIdStore.get();
    final di = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';
    final model = Platform.isAndroid
        ? (await di.androidInfo).model
        : (await di.iosInfo).utsname.machine;

    final devRef = _db.collection('users').doc(uid).collection('devices').doc(deviceId);
    final devSnap = await devRef.get();

    final base = <String, dynamic>{
      'deviceId': deviceId,
      'platform': platform,
      'model': model,
      'appVersion': pkg.version,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    if (devSnap.exists) {
      await devRef.set(base, SetOptions(merge: true));
    } else {
      await devRef.set({
        ...base,
        'isActive': false,
        'registeredAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> setLanguage(String code) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).set({
      'language': code,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// لینک کد به دستگاه فعلی + به‌روزرسانی aliasها
  Future<void> linkCodeToCurrentDevice(
      String code, {
        String? planType,
        String? source,
        String? status,
        int? validForDays,
        int? maxDevices,
        int? activatedAtMs,
        int? expiresAtMs,
        String? codeId,
      }) async {
    if (uid.isEmpty) return;
    final deviceId = await DeviceIdStore.get();
    final userRef = _db.collection('users').doc(uid);
    final devRef = userRef.collection('devices').doc(deviceId);

    await userRef.set({
      'currentCode': code,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await devRef.set({
      'code': code,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (planType != null ||
        source != null ||
        status != null ||
        validForDays != null ||
        maxDevices != null ||
        activatedAtMs != null ||
        expiresAtMs != null ||
        codeId != null) {
      final String theCodeId = (codeId ?? code).trim();

      final Map<String, dynamic> plan = {
        if (planType != null) 'type': planType,
        'source': (source ?? 'code'),
        'status': (status ?? 'active'),
        'codeId': theCodeId,
        if (validForDays != null) 'validForDays': validForDays,
        if (maxDevices != null) 'maxDevices': maxDevices,
        if (activatedAtMs != null) 'activatedAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(activatedAtMs)!),
        if (expiresAtMs != null) 'expiresAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(expiresAtMs)!),
      };

      final batch = _db.batch();

      batch.set(userRef, {
        'plan': plan,
        'planType': planType ?? 'active',
        'source': (source ?? 'code'),
        'codeId': theCodeId,
        'tokenId': theCodeId,
        if (validForDays != null) 'validForDays': validForDays,
        if (maxDevices != null) 'maxDevices': maxDevices,
        if (expiresAtMs != null) 'expiresAt': _normalizeEpochMs(expiresAtMs),
        'status': (status ?? 'active'),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'subscription': {
          'codeId': theCodeId,
          'source': (source ?? 'code'),
          if (expiresAtMs != null) 'expiresAt': _normalizeEpochMs(expiresAtMs),
        },
      }, SetOptions(merge: true));

      batch.set(devRef, {
        'isActive': true,
        'linkedCodeId': theCodeId,
        if (planType != null) 'planType': planType,
        if (activatedAtMs != null) 'activatedAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(activatedAtMs)!),
        if (expiresAtMs != null) 'expiresAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(expiresAtMs)!),
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final actRef = _db.collection('codes').doc(theCodeId).collection('activations').doc('${uid}_$deviceId');
      batch.set(actRef, {
        'uid': uid,
        'deviceId': deviceId,
        'planType': planType ?? 'unknown',
        'source': plan['source'],
        if (activatedAtMs != null) 'activatedAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(activatedAtMs)!),
        if (expiresAtMs != null) 'expiresAt': Timestamp.fromMillisecondsSinceEpoch(_normalizeEpochMs(expiresAtMs)!),
        'at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } else {
      await _ensureAdminAliasesFromPlan(userRef);
    }
  }

  // ---------------------- Devices ----------------------

  Future<List<Map<String, dynamic>>> getUserDevices() async {
    if (uid.isEmpty) return [];
    final snap = await _db.collection('users').doc(uid).collection('devices').get();

    return snap.docs.map((d) {
      final m = (d.data() as Map<String, dynamic>? ?? {});
      final isActive = (m['isActive'] == true) || (m['status']?.toString().toLowerCase() == 'active');
      return {
        'id': d.id,
        'name': (m['name'] ?? m['deviceName'] ?? 'این دستگاه').toString(),
        'isActive': isActive,
        'code': (m['code'] ?? m['token'] ?? m['subscriptionCode']),
        'createdAt': _normalizeEpochMs(m['registeredAt'] ?? m['createdAt']),
        'lastSeen': _normalizeEpochMs(m['lastSeenAt'] ?? m['lastSeen']),
      };
    }).toList();
  }

  Future<void> removeDevice(String deviceId) async {
    if (uid.isEmpty) return;
    await _db.collection('users').doc(uid).collection('devices').doc(deviceId).delete();
  }

  // ---------------------- Summary ----------------------

  Future<Map<String, dynamic>> getUserSummary() async {
    if (uid.isEmpty) return _emptySummary();

    final userRef = _db.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final Map<String, dynamic> data = (userSnap.data() as Map<String, dynamic>?) ?? {};

    final Map<String, dynamic> plan = (data['plan'] is Map) ? Map<String, dynamic>.from(data['plan']) : {};
    final Map<String, dynamic> sub = (data['subscription'] is Map) ? Map<String, dynamic>.from(data['subscription']) : {};

    // -- لیست دستگاه‌های کاربر (همه) + تعیین active
    final userDevSnap = await userRef.collection('devices').get();
    final List<Map<String, dynamic>> userDevicesAll = userDevSnap.docs.map((d) {
      final m = (d.data() as Map<String, dynamic>? ?? {});
      final statusStr = (m['status']?.toString().toLowerCase() ?? '');
      final hasIsActive = m.containsKey('isActive');
      final bool isActive = (m['isActive'] == true) || (statusStr == 'active');
      final bool consideredActive = (statusStr == 'active' || statusStr.isEmpty) && (!hasIsActive || m['isActive'] != false);
      final bool finalActive = isActive || consideredActive;

      return {
        'id': d.id,
        'name': (m['name'] ?? m['deviceName'] ?? 'این دستگاه').toString(),
        'isActive': finalActive,
        'code': (m['code'] ?? m['token'] ?? m['subscriptionCode']),
        'createdAt': _normalizeEpochMs(m['registeredAt'] ?? m['createdAt']),
        'lastSeen': _normalizeEpochMs(m['lastSeenAt'] ?? m['lastSeen']),
      };
    }).toList();

    // فقط activeها را برای نمایش برگردان
    final List<Map<String, dynamic>> userDevices =
    userDevicesAll.where((e) => e['isActive'] == true).toList();

    // -- کُد فعلی
    String? primaryCode = (data['currentCode'] as String?)?.trim()
        ?? (plan['codeId'] as String?)?.trim()
        ?? (sub['codeId'] as String?)?.trim();

    final dynamic planRaw = plan['type'] ?? data['planType'] ?? sub['type'];
    final dynamic userMaxRaw = plan['maxDevices'] ?? data['maxDevices'] ?? sub['maxDevices'];
    final String status = (plan['status'] ?? data['status'] ?? sub['status'] ?? 'unknown').toString();

    final int? expiryMs = _normalizeEpochMs(plan['expiresAt'] ?? data['expiresAt'] ?? sub['expiresAt']);
    final int? maxDevicesFromUser = _asIntNullable(userMaxRaw);

    // -- دستگاه‌های روی کُد (فقط active)
    List<Map<String, dynamic>> codeDevices = <Map<String, dynamic>>[];
    int usedDevicesOnCode = 0;

    if ((primaryCode ?? '').isNotEmpty) {
      try {
        final codeRef = _db.collection('codes').doc(primaryCode);
        final cds = await codeRef.collection('devices').get();

        for (final doc in cds.docs) {
          final m = (doc.data() as Map<String, dynamic>? ?? {});
          final statusDev = (m['status'] ?? '').toString().toLowerCase();
          final hasIsActive = m.containsKey('isActive');
          final bool isActive = m['isActive'] == true;
          final bool consideredActive = (statusDev == 'active' || statusDev.isEmpty) && (!hasIsActive || m['isActive'] != false);
          if (isActive || consideredActive) {
            codeDevices.add({'id': doc.id});
          }
        }
        usedDevicesOnCode = codeDevices.length;
      } catch (_) {
        // اگر خواندن کالکشن کُد خطا داد، از تعداد active کاربر استفاده می‌کنیم (fallback)
        usedDevicesOnCode = userDevices.length;
      }
    }

    final int? remainingFinal =
    (maxDevicesFromUser == null) ? null : (maxDevicesFromUser - usedDevicesOnCode);

    return {
      'plan': planRaw?.toString(),
      'expiry': expiryMs,
      'maxDevices': maxDevicesFromUser,
      'usedDevices': usedDevicesOnCode,
      'remaining': remainingFinal,
      'status': status,
      'devices': userDevices,          // فقط activeهای کاربر
      'code': primaryCode,
      'codeDevices': codeDevices,      // فقط activeهای کُد
    };
  }

  Map<String, dynamic> _emptySummary() => {
    'plan': null,
    'expiry': null,
    'maxDevices': null,
    'usedDevices': 0,
    'remaining': null,
    'status': 'unknown',
    'devices': <Map<String, dynamic>>[],
    'code': null,
    'codeDevices': <Map<String, dynamic>>[],
  };

  Future<void> _ensureAdminAliasesFromPlan(DocumentReference userRef) async {
    final snap = await userRef.get();
    final data = (snap.data() as Map<String, dynamic>?) ?? {};
    if (data['plan'] is! Map) return;

    final Map<String, dynamic> plan = Map<String, dynamic>.from(data['plan'] as Map);
    final String? planType = plan['type'] as String?;
    final String? source = plan['source'] as String?;
    final String? codeId = plan['codeId'] as String?;
    final int? maxDevices = _asIntNullable(plan['maxDevices']);
    final int? expiresAtMs = _normalizeEpochMs(plan['expiresAt']);

    await userRef.set({
      if (planType != null) 'planType': planType,
      if (source != null) 'source': source,
      if (codeId != null) 'codeId': codeId,
      if (maxDevices != null) 'maxDevices': maxDevices,
      if (expiresAtMs != null) 'expiresAt': expiresAtMs,
      'subscription': {
        if (codeId != null) 'codeId': codeId,
        if (source != null) 'source': source,
        if (expiresAtMs != null) 'expiresAt': expiresAtMs,
      },
    }, SetOptions(merge: true));
  }

  int? _asIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int? _normalizeEpochMs(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.millisecondsSinceEpoch;
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
