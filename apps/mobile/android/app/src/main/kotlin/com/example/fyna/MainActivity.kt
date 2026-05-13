package com.example.fyna

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

/**
 * Usa FlutterFragmentActivity (não FlutterActivity) — exigido pelo local_auth
 * para mostrar o prompt biométrico nativo do Android.
 */
class MainActivity : FlutterFragmentActivity() {

    companion object {
        const val PERMISSION_CHANNEL = "com.example.fyna/notification_permission"
        const val PENDING_NOTIFS_CHANNEL = "com.example.fyna/pending_notifications"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel — stream em tempo real (quando o app está em foreground)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BankNotificationService.CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                BankNotificationService.eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                BankNotificationService.eventSink = null
            }
        })

        // MethodChannel — verifica/abre configurações de notificação
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PERMISSION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationAccess" -> result.success(isNotificationServiceEnabled())
                "openNotificationAccessSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // MethodChannel — lê e limpa fila de notificações pendentes
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PENDING_NOTIFS_CHANNEL
        ).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(
                BankNotificationService.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            when (call.method) {
                "getPending" -> {
                    val json = prefs.getString(BankNotificationService.PREFS_KEY, "[]") ?: "[]"
                    result.success(json)
                }
                "clearPending" -> {
                    prefs.edit().putString(BankNotificationService.PREFS_KEY, "[]").apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        if (flat.isEmpty()) return false
        val names = flat.split(":").toTypedArray()
        for (name in names) {
            val cn = ComponentName.unflattenFromString(name) ?: continue
            if (TextUtils.equals(pkgName, cn.packageName)) return true
        }
        return false
    }
}
