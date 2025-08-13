import 'dart:convert';
import 'package:flutter/services.dart';

const MethodChannel _deviceIdentityChannel = MethodChannel('device_identity');

/// گرفتن DeviceClaim از لایه‌ی نیتیو.
/// - اگر Map برگشت: همان را برمی‌گردانیم.
/// - اگر String (JSON) برگشت: parse می‌کنیم.
/// - در غیر این صورت: خطا می‌دهیم.
Future<Map<String, dynamic>> getDeviceClaim() async {
  try {
    final result = await _deviceIdentityChannel.invokeMethod('makeClaim');

    if (result is Map) {
      return Map<String, dynamic>.from(result as Map);
    }
    if (result is String) {
      return Map<String, dynamic>.from(jsonDecode(result) as Map);
    }
    throw Exception('Unexpected claim type: ${result.runtimeType}');
  } on PlatformException catch (e) {
    throw Exception('Platform error while getting device claim: ${e.message}');
  } catch (e) {
    throw Exception('Failed to get device claim: $e');
  }
}
