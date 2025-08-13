// lib/services/token_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class TokenService {
  TokenService._();
  static final instance = TokenService._();

  static const Duration _timeout = Duration(seconds: 20);

  /// POST /api/apply-token
  /// Body: { uid, codeId, deviceId?, deviceInfo? }
  Future<ActivateResult> applyToken({
    required String uid,
    required String codeId,
    String? deviceId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    final uri = Uri.parse('${kApiBaseUrl}/api/apply-token');

    final body = jsonEncode({
      'uid': uid,
      'codeId': codeId,
      if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    });

    final res = await http
        .post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = data['ok'] == true;
      return ok
          ? ActivateResult.success(data)
          : ActivateResult.fail(data['error']?.toString() ?? 'activation_failed');
    }

    return ActivateResult.fail('HTTP ${res.statusCode}: ${res.body}');
  }
}

class ActivateResult {
  final bool ok;
  final Map<String, dynamic>? data;
  final String? error;

  ActivateResult._(this.ok, this.data, this.error);

  factory ActivateResult.success(Map<String, dynamic> data) =>
      ActivateResult._(true, data, null);

  factory ActivateResult.fail(String message) =>
      ActivateResult._(false, null, message);
}
