package com.vpnclient.vpn_app.services

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.*
import java.security.cert.Certificate
import java.security.interfaces.ECPrivateKey
import java.security.spec.ECGenParameterSpec
import javax.crypto.Cipher

/**
 * DeviceIdentity
 * - تولید و نگهداری کلید ECDSA در Android Keystore (secp256r1)
 * - ساخت شناسه دستگاه بر اساس hash کلید عمومی
 * - تولید Claim شامل deviceId، publicKey، timestamp، nonce و امضا
 * - خروجی آماده برای ارسال به سرور
 */
object DeviceIdentity {

    private const val KEYSTORE = "AndroidKeyStore"
    private const val KEY_ALIAS = "vpn_app_device_key"
    private const val SIGN_ALGO = "SHA256withECDSA"
    private const val CURVE = "secp256r1" // aka prime256v1
    private const val TAG = "DeviceIdentity"

    data class DeviceClaim(
        val deviceId: String,
        val publicKeyPem: String,
        val timestamp: Long,
        val nonce: String,
        val signatureBase64: String,
        val algo: String = SIGN_ALGO,
        val curve: String = CURVE
    )

    /**
     * بازم نکردن کی‌استور و برگرداندن Entry اگر وجود داشته باشد
     */
    private fun getPrivateKeyEntryOrNull(): KeyStore.PrivateKeyEntry? {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        return try {
            ks.getEntry(KEY_ALIAS, null) as? KeyStore.PrivateKeyEntry
        } catch (_: Exception) {
            null
        }
    }

    /**
     * اگر کلید وجود ندارد، می‌سازد؛ در غیر این‌صورت همان موجود را برمی‌گرداند.
     */
    private fun getOrCreateKeyPair(): KeyPair {
        val existing = getPrivateKeyEntryOrNull()
        if (existing != null) {
            return KeyPair(existing.certificate.publicKey, existing.privateKey)
        }
        return generateEcKeyPair()
    }

    /**
     * ساخت کلید ECDSA روی Keystore با منحنی secp256r1
     */
    private fun generateEcKeyPair(): KeyPair {
        val kpg = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            KEYSTORE
        )

        val parameterSpec = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec(CURVE))
            .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
            .setUserAuthenticationRequired(false)
            .build()

        kpg.initialize(parameterSpec)
        return kpg.generateKeyPair()
    }

    /**
     * تبدیل کلید عمومی به PEM
     */
    private fun publicKeyToPem(pub: PublicKey): String {
        val b64 = Base64.encodeToString(pub.encoded, Base64.NO_WRAP)
        return "-----BEGIN PUBLIC KEY-----\n$b64\n-----END PUBLIC KEY-----"
    }

    /**
     * تولید یک nonce تصادفی Base64 (بدون خط فاصله)
     */
    private fun randomNonce(len: Int = 16): String {
        val bytes = ByteArray(len)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    /**
     * امضای بایت‌ها با کلید خصوصی Keystore
     */
    private fun signBytes(privateKey: PrivateKey, data: ByteArray): ByteArray {
        val sig = Signature.getInstance(SIGN_ALGO)
        sig.initSign(privateKey)
        sig.update(data)
        return sig.sign()
    }

    /**
     * شناسه‌ی پایدار دستگاه از روی hash کلید عمومی (بدون tie شدن به Hardware IDs)
     */
    private fun makeDeviceIdFromPublicKey(pub: PublicKey): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(pub.encoded)
        return Base64.encodeToString(digest, Base64.NO_WRAP)
    }

    /**
     * ساخت payload و امضای آن. خروجی برای ارسال به سرور آماده است.
     *
     * canonical: deviceId=<..>&timestamp=<..>&nonce=<..>
     */
    @SuppressLint("HardwareIds") // ما از Hardware ID استفاده نمی‌کنیم؛ فقط برای سکوت Lint
    fun makeClaimPayload(context: Context): DeviceClaim {
        val kp = getOrCreateKeyPair()

        val deviceId = makeDeviceIdFromPublicKey(kp.public)
        val publicKeyPem = publicKeyToPem(kp.public)

        val ts = System.currentTimeMillis()
        val nonce = randomNonce()

        val canonical = "deviceId=$deviceId&timestamp=$ts&nonce=$nonce"
        val sigBytes = signBytes(kp.private, canonical.toByteArray(StandardCharsets.UTF_8))
        val sigB64 = Base64.encodeToString(sigBytes, Base64.NO_WRAP)

        return DeviceClaim(
            deviceId = deviceId,
            publicKeyPem = publicKeyPem,
            timestamp = ts,
            nonce = nonce,
            signatureBase64 = sigB64
        )
    }

    /**
     * دسترسی به گواهی/کلید عمومی در صورت نیاز
     */
    fun getPublicCertificate(): Certificate? {
        val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        return ks.getCertificate(KEY_ALIAS)
    }

    /**
     * حذف کلید (در صورت نیاز به ریست هویت دستگاه)
     */
    fun resetDeviceIdentity(): Boolean {
        return try {
            val ks = KeyStore.getInstance(KEYSTORE).apply { load(null) }
            ks.deleteEntry(KEY_ALIAS)
            true
        } catch (e: Exception) {
            Log.e(TAG, "resetDeviceIdentity failed", e)
            false
        }
    }
}
