package app.grab.grab

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Ringtone maker. Channel "grab/ringtone":
 *   make(input, start, end, title) -> content URI of a new ringtone in Ringtones/Grab
 *   set(uri)                       -> "set" | "needsPermission" (opens the system screen)
 *   canSet()                       -> Boolean
 *   duration(input)                -> seconds, or null
 */
class RingtonePlugin(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: () -> Activity?,
) {
    private val pool = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "grab/ringtone").setMethodCallHandler { call, result ->
            when (call.method) {
                "make" -> {
                    val input = File(call.argument<String>("input")!!)
                    val start = call.argument<Double>("start") ?: 0.0
                    val end = call.argument<Double>("end") ?: (start + 30)
                    val title = call.argument<String>("title") ?: input.nameWithoutExtension
                    pool.execute {
                        try {
                            val uri = make(input, start, end, title)
                            main.post { result.success(uri.toString()) }
                        } catch (e: Throwable) {
                            main.post { result.error("ringtone", e.message ?: e.toString(), null) }
                        }
                    }
                }
                "canSet" -> result.success(Settings.System.canWrite(context))
                "duration" -> {
                    val path = call.argument<String>("input")!!
                    pool.execute {
                        val ms = try {
                            MediaMetadataRetriever().run {
                                setDataSource(path)
                                val d = extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
                                release()
                                d
                            }
                        } catch (_: Throwable) { null }
                        main.post { result.success(ms?.let { it / 1000.0 }) }
                    }
                }
                "set" -> {
                    val uri = Uri.parse(call.argument<String>("uri")!!)
                    if (Settings.System.canWrite(context)) {
                        RingtoneManager.setActualDefaultRingtoneUri(context, RingtoneManager.TYPE_RINGTONE, uri)
                        result.success("set")
                    } else {
                        // Android asks the user to allow "Modify system settings" for Grab.
                        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                            .setData(Uri.parse("package:${context.packageName}"))
                        val a = activity()
                        if (a != null) a.startActivity(intent)
                        else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success("needsPermission")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Cuts [start, end] to AAC with short fades and files it as a ringtone. */
    private fun make(input: File, start: Double, end: Double, title: String): Uri {
        if (!input.exists()) throw IllegalStateException("The file is no longer on the phone")
        YoutubeDL.getInstance().init(context)
        FFmpeg.getInstance().init(context)
        val length = (end - start).coerceAtLeast(1.0)
        val tmp = File(context.cacheDir, "ringtone-${System.currentTimeMillis()}.m4a")
        val fadeOut = (length - 1.0).coerceAtLeast(0.0)
        val cmd = listOf(
            File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so").absolutePath,
            "-hide_banner", "-nostdin", "-y",
            "-ss", "%.2f".format(start), "-t", "%.2f".format(length),
            "-i", input.absolutePath, "-vn", "-map", "0:a:0",
            "-af", "afade=t=in:st=0:d=0.3,afade=t=out:st=%.2f:d=1".format(fadeOut),
            "-c:a", "aac", "-b:a", "192k", tmp.absolutePath,
        )
        val packages = File(context.noBackupFilesDir, "youtubedl-android/packages")
        val pb = ProcessBuilder(cmd).redirectErrorStream(true)
        pb.environment()["LD_LIBRARY_PATH"] =
            "${File(packages, "python/usr/lib").absolutePath}:${File(packages, "ffmpeg/usr/lib").absolutePath}"
        val process = pb.start()
        val log = process.inputStream.bufferedReader().readText()
        if (process.waitFor() != 0 || !tmp.exists() || tmp.length() == 0L) {
            tmp.delete()
            throw IllegalStateException(
                if (log.contains("matches no streams") || log.contains("does not contain any stream"))
                    "This file has no audio track"
                else log.lines().lastOrNull { it.isNotBlank() } ?: "FFmpeg failed",
            )
        }
        val name = title.replace(Regex("[\\\\/:*?\"<>|]"), " ").take(60).trim().ifEmpty { "Grab ringtone" }
        try {
            return save(tmp, name)
        } finally {
            tmp.delete()
        }
    }

    private fun save(file: File, name: String): Uri {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, "$name.m4a")
            put(MediaStore.Audio.Media.TITLE, name)
            put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4")
            put(MediaStore.Audio.Media.IS_RINGTONE, true)
            put(MediaStore.Audio.Media.IS_MUSIC, false)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_RINGTONES}/Grab")
            values.put(MediaStore.Audio.Media.IS_PENDING, 1)
            val uri = resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Couldn't save the ringtone")
            resolver.openOutputStream(uri)!!.use { out -> file.inputStream().use { it.copyTo(out) } }
            values.clear()
            values.put(MediaStore.Audio.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri
        }
        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_RINGTONES), "Grab")
        dir.mkdirs()
        val target = File(dir, "$name.m4a")
        file.copyTo(target, overwrite = true)
        @Suppress("DEPRECATION")
        values.put(MediaStore.MediaColumns.DATA, target.absolutePath)
        return resolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
            ?: Uri.fromFile(target)
    }
}
