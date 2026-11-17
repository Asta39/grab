package app.grab.grab

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EnginePlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        HapticsPlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
