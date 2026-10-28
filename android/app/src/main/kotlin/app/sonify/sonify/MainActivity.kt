package app.sonify.sonify

import android.os.StatFs
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Comparte el FlutterEngine con audio_service (reproducción en segundo plano).
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Canal `app.sonify.sonify/storage` (ver `device_storage.dart`).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.sonify.sonify/storage")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                when {
                    path == null -> result.error("bad_args", "Falta path", null)
                    call.method == "freeBytes" -> result.success(StatFs(path).availableBytes)
                    // Los respaldos se excluyen en data_extraction_rules.xml.
                    call.method == "excludeFromBackup" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}
