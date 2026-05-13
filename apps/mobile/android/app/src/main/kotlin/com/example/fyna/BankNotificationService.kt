package com.example.fyna

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

class BankNotificationService : NotificationListenerService() {

    companion object {
        const val CHANNEL = "com.example.fyna/bank_notifications"
        // SharedPreferences usado pelo Flutter — mantém compatibilidade com
        // o plugin shared_preferences (que prefixa keys com "flutter.")
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val PREFS_KEY = "flutter.pending_bank_notifications"

        private val BANK_PACKAGES = setOf(
            "br.com.intermedium",
            "com.bradesco",
            "br.com.bb.android",
            "com.itau",
            "com.santander.app",
            "br.com.nubank",
            "com.c6bank.app",
            "br.com.original.bank",
            "com.picpay",
            "br.com.mercadopago.wallet",
            "br.com.sicredi.app",
            "br.com.caixa.economiafederal",
        )

        var eventSink: EventChannel.EventSink? = null
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return
        if (packageName !in BANK_PACKAGES) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: text

        if (title.isBlank() && bigText.isBlank()) return

        val payload = JSONObject().apply {
            put("package", packageName)
            put("title", title)
            put("body", bigText.ifBlank { text })
            put("timestamp", sbn.postTime)
        }
        val payloadJson = payload.toString()

        // 1) Persiste em SharedPreferences (para processamento posterior)
        appendToPendingQueue(payloadJson)

        // 2) Envia em tempo real (se app estiver em foreground)
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(payloadJson)
        }
    }

    private fun appendToPendingQueue(payloadJson: String) {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(PREFS_KEY, "[]") ?: "[]"
            val arr = JSONArray(existing)
            arr.put(JSONObject(payloadJson))
            // Limita o tamanho da fila para evitar crescimento descontrolado
            val MAX_QUEUE = 50
            if (arr.length() > MAX_QUEUE) {
                val trimmed = JSONArray()
                for (i in (arr.length() - MAX_QUEUE) until arr.length()) {
                    trimmed.put(arr.get(i))
                }
                prefs.edit().putString(PREFS_KEY, trimmed.toString()).apply()
            } else {
                prefs.edit().putString(PREFS_KEY, arr.toString()).apply()
            }
        } catch (e: Exception) {
            android.util.Log.e("BankNotification", "Erro ao persistir notificação", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {}
}
