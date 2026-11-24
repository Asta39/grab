package app.grab.grab

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** AudioServiceActivity (a FlutterActivity) keeps background audio tied to this screen. */
class MainActivity : AudioServiceActivity() {
    private var launch: MethodChannel? = null

    /** Set when the Quick Settings tile opened the app; Dart takes it once. */
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EnginePlugin(applicationContext, messenger)
        HapticsPlugin(applicationContext, messenger)
        RingtonePlugin(applicationContext, messenger) { this }
        ClipPlugin(applicationContext, messenger)
        GrabWidget.channel(applicationContext, messenger)
        AppPlugin(applicationContext, messenger) { this }
        pendingAction = actionOf(intent)
        launch = MethodChannel(messenger, "grab/launch").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeAction" -> { result.success(pendingAction); pendingAction = null }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = actionOf(intent) ?: return
        launch?.invokeMethod("action", action)
    }

    private fun actionOf(intent: Intent?): String? =
        if (intent?.action == GrabTileService.ACTION_GRAB_CLIPBOARD) "grabClipboard" else null
}
