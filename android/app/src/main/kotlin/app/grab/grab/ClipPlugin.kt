package app.grab.grab

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Turns a few seconds of a saved video into a GIF or a WhatsApp-style sticker.
 * Channel "grab/clip":
 *   make(input, start, end, kind: "gif" | "sticker", title)
 *     -> { path: shareable copy in the cache, uri: copy saved to Pictures/Grab }
 */
class ClipPlugin(private val context: Context, messenger: BinaryMessenger) {
    private val pool = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, "grab/clip").setMethodCallHandler { call, result ->
            if (call.method != "make") return@setMethodCallHandler result.notImplemented()
            val input = File(call.argument<String>("input")!!)
            val start = call.argument<Double>("start") ?: 0.0
            val end = call.argument<Double>("end") ?: (start + 3)
            val kind = call.argument<String>("kind") ?: "gif"
            val title = call.argument<String>("title") ?: input.nameWithoutExtension
            pool.execute {
                try {
                    val out = make(input, start, end, kind, title)
                    main.post { result.success(out) }
                } catch (e: Throwable) {
                    main.post { result.error("clip", e.message ?: e.toString(), null) }
                }
            }
        }
    }

    private fun make(input: File, start: Double, end: Double, kind: String, title: String): Map<String, String> {
        if (!input.exists()) throw IllegalStateException("The file is no longer on the phone")
        YoutubeDL.getInstance().init(context)
        FFmpeg.getInstance().init(context)
        val length = (end - start).coerceIn(0.5, if (kind == "sticker") 6.0 else 10.0)
        val name = title.replace(Regex("[\\\\/:*?\"<>|]"), " ").take(50).trim().ifEmpty { "Grab clip" }
        val ext = if (kind == "sticker") "webp" else "gif"
        // A fresh name each time: an old clip's file (and its cached preview) is never reused.
        val dir = File(context.cacheDir, "clips").apply {
            mkdirs()
            listFiles()?.forEach { it.delete() }
        }
        val stamp = (start * 10).toInt()
        val out = File(dir, "$name ${stamp}s ${System.currentTimeMillis() % 100000}.$ext")
        val cut = listOf("-ss", "%.2f".format(start), "-t", "%.2f".format(length), "-i", input.absolutePath, "-an")
        val log = if (kind == "sticker") {
            // WhatsApp stickers: 512x512, transparent padding, small and looping.
            val vf = "fps=15,scale=512:512:force_original_aspect_ratio=decrease," +
                "pad=512:512:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=yuva420p"
            run(cut + listOf("-vf", vf, "-c:v", "libwebp_anim", "-q:v", "55", "-loop", "0", out.absolutePath))
                ?: run(cut + listOf("-vf", vf, "-c:v", "libwebp", "-q:v", "55", "-loop", "0", out.absolutePath))
                ?: throw IllegalStateException("This phone's video tools can't make stickers")
        } else {
            // A two-pass palette keeps GIF colours clean.
            val vf = "fps=12,scale='min(480,iw)':-2:flags=lanczos,split[a][b];" +
                "[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4"
            run(cut + listOf("-vf", vf, "-loop", "0", out.absolutePath))
                ?: throw IllegalStateException("Couldn't make the GIF")
        }
        if (!out.exists() || out.length() == 0L) throw IllegalStateException(log)
        val uri = save(out, "$name ${clock(start)}", ext)
        return mapOf("path" to out.absolutePath, "uri" to uri)
    }

    private fun clock(s: Double): String {
        val t = s.toInt()
        return "%d-%02d".format(t / 60, t % 60)
    }

    /** Runs FFmpeg; returns its log on success, or null if it failed. */
    private fun run(args: List<String>): String? {
        val cmd = listOf(
            File(context.applicationInfo.nativeLibraryDir, "libffmpeg.so").absolutePath,
            "-hide_banner", "-nostdin", "-y",
        ) + args
        val packages = File(context.noBackupFilesDir, "youtubedl-android/packages")
        val pb = ProcessBuilder(cmd).redirectErrorStream(true)
        pb.environment()["LD_LIBRARY_PATH"] =
            "${File(packages, "python/usr/lib").absolutePath}:${File(packages, "ffmpeg/usr/lib").absolutePath}"
        val process = pb.start()
        val log = process.inputStream.bufferedReader().readText()
        return if (process.waitFor() == 0) log else null
    }

    /** Puts a copy in Pictures/Grab so it shows up in the gallery. */
    private fun save(file: File, name: String, ext: String): String {
        val mime = if (ext == "gif") "image/gif" else "image/webp"
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, "$name.$ext")
            put(MediaStore.Images.Media.MIME_TYPE, mime)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            values.put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Grab")
            values.put(MediaStore.Images.Media.IS_PENDING, 1)
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: return ""
            resolver.openOutputStream(uri)!!.use { o -> file.inputStream().use { it.copyTo(o) } }
            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri.toString()
        }
        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "Grab")
        dir.mkdirs()
        val target = File(dir, "$name.$ext")
        file.copyTo(target, overwrite = true)
        return target.absolutePath
    }
}
