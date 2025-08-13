package com.vpnclient.vpn_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.vpnclient.vpn_app.services.DeviceIdentity

class MainActivity : FlutterActivity() {

    private val channelName = "device_identity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // تست اختیاری لاگ
        try {
            val claim = DeviceIdentity.makeClaimPayload(this)
            Log.d("DeviceIdentity", "claim=$claim")
        } catch (t: Throwable) {
            Log.e("DeviceIdentity", "failed to build claim", t)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makeClaim" -> {
                        try {
                            val claim = DeviceIdentity.makeClaimPayload(this)

                            val map = mapOf(
                                "deviceId" to claim.deviceId,
                                "publicKey" to claim.publicKeyPem,     // در صورت تفاوت نام فیلد، اصلاح کن
                                "nonce" to claim.nonce,
                                "signature" to claim.signatureBase64,  // در صورت تفاوت نام فیلد، اصلاح کن
                                "alg" to "ES256",
                                "timestamp" to claim.timestamp
                            )

                            result.success(map)
                        } catch (t: Throwable) {
                            Log.e("DeviceIdentity", "makeClaim failed", t)
                            result.error("CLAIM_ERROR", t.message ?: "failed to build claim", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
