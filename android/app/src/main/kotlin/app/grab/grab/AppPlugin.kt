package app.grab.grab

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * App-level helpers. Channel "grab/app":
 *   abis()            -> List<String>, best first (picks the right APK from a release)
 *   openUrl(url)      -> opens a link in the browser
 *   installApk(path)  -> "started" | "needsPermission"
 *   takeCrash()       -> the last native crash report, once, or null
 *
 * Installing an APK signed with the same key and a higher version updates Grab in place:
 * downloads, settings and history all stay.
 */
class AppPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: () -> Activity?,
) {
    init {
        recordCrashes(context)
        MethodChannel(messenger, "grab/app").setMethodCallHandler { call, result ->
            when (call.method) {
                "takeCrash" -> {
                    val f = crashFile(context)
                    val text = if (f.exists()) f.readText().take(6000) else null
                    f.delete()
                    result.success(text)
                }
                "abis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "openUrl" -> {
                    start(Intent(Intent.ACTION_VIEW, Uri.parse(call.argument<String>("url")!!)))
                    result.success(null)
                }
                "installApk" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        !context.packageManager.canRequestPackageInstalls()
                    ) {
                        // Android asks the user to allow Grab to install updates, once.
                        start(
                            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
                                .setData(Uri.parse("package:${context.packageName}")),
                        )
                        result.success("needsPermission")
                        return@setMethodCallHandler
                    }
                    val file = File(call.argument<String>("path")!!)
                    val uri = FileProvider.getUriForFile(context, "${context.packageName}.files", file)
                    start(
                        Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
                    )
                    result.success("started")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun start(intent: Intent) {
        val a = activity()
        if (a != null) a.startActivity(intent)
        else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    companion object {
        private fun crashFile(context: Context) = File(context.filesDir, "last-crash.txt")
        private var installed = false

        /**
         * Saves a native crash (like a plugin throwing on the main thread) to a file,
         * so "Report a problem" can include it the next time Grab opens.
         */
        fun recordCrashes(context: Context) {
            if (installed) return
            installed = true
            val previous = Thread.getDefaultUncaughtExceptionHandler()
            Thread.setDefaultUncaughtExceptionHandler { thread, e ->
                try {
                    crashFile(context).writeText(
                        "${java.util.Date()}\n${Build.MANUFACTURER} ${Build.MODEL}, Android ${Build.VERSION.RELEASE}\n" +
                            android.util.Log.getStackTraceString(e).take(5000),
                    )
                } catch (_: Throwable) {}
                previous?.uncaughtException(thread, e)
            }
        }
    }
}
