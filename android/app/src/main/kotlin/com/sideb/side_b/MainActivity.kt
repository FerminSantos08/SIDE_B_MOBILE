package com.sideb.side_b

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "side_b/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "share") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val title = call.argument<String>("title") ?: "SIDE B"
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("invalid_url", "Falta el enlace de la publicación", null)
                    return@setMethodCallHandler
                }
                try {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_SUBJECT, title)
                        putExtra(Intent.EXTRA_TEXT, "$title\n$url")
                    }
                    startActivity(Intent.createChooser(intent, "Compartir publicación"))
                    result.success(null)
                } catch (error: Exception) {
                    result.error("share_failed", "No fue posible compartir", null)
                }
            }
    }
}
