package app.grab.grab

import android.content.Context
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Bridge between Dart and yt-dlp (via youtubedl-android).
 *
 * Methods on "grab/engine":
 *   init()                              -> yt-dlp version
 *   update()                            -> "updated" | "already_up_to_date" | null
 *   fetch(url)                          -> yt-dlp JSON (--dump-single-json) as a string
 *   download(id, url, args, suffix, match, title) -> starts a job; results come as events
 *   cancel(id)                          -> Boolean
 *   outputDir()                         -> folder files are saved in
 *
 * Events on "grab/engine/progress": maps with id, status, progress, eta, line, paths, error.
 * status: starting | running | done | canceled | error
 */
class EnginePlugin(private val context: Context, messenger: BinaryMessenger) {
    private val main = Handler(Looper.getMainLooper())
    private val pool = Executors.newCachedThreadPool()
    private var sink: EventChannel.EventSink? = null
    @Volatile private var ready = false

    /** Active jobs: id -> (title, progress). Drives the foreground notification. */
    private val active = ConcurrentHashMap<String, Pair<String, Float>>()

    init {
        MethodChannel(messenger, "grab/engine").setMethodCallHandler { call, result -> handle(call, result) }
        EventChannel(messenger, "grab/engine/progress").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
            override fun onCancel(arguments: Any?) { sink = null }
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> background(result) {
                ensureReady()
                YoutubeDL.getInstance().versionName(context)
                    ?: YoutubeDL.getInstance().execute(YoutubeDLRequest(emptyList()).apply { addOption("--version") }).out.trim()
            }
            "update" -> background(result) {
                ensureReady()
                when (YoutubeDL.getInstance().updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)) {
                    YoutubeDL.UpdateStatus.DONE -> "updated"
                    YoutubeDL.UpdateStatus.ALREADY_UP_TO_DATE -> "already_up_to_date"
                    else -> null
                }
            }
            "fetch" -> {
                val url = call.argument<String>("url")!!
                background(result) {
                    ensureReady()
                    val req = YoutubeDLRequest(url)
                    req.addOption("--dump-single-json")
                    req.addOption("--no-warnings")
                    req.addOption("--flat-playlist")
                    YoutubeDL.getInstance().execute(req).out
                }
            }
            "download" -> {
                val job = Job(
                    id = call.argument<String>("id")!!,
                    url = call.argument<String>("url")!!,
                    args = call.argument<List<String>>("args") ?: emptyList(),
                    suffix = call.argument<String>("suffix") ?: "",
                    match = call.argument<String>("match"),
                    title = call.argument<String>("title") ?: "Download",
                )
                pool.execute { runDownload(job) }
                result.success(null)
            }
            "cancel" -> result.success(YoutubeDL.getInstance().destroyProcessById(call.argument<String>("id")!!))
            "outputDir" -> result.success(outputDir().absolutePath)
            else -> result.notImplemented()
        }
    }

    private data class Job(
        val id: String,
        val url: String,
        val args: List<String>,
        val suffix: String,
        val match: String?,
        val title: String,
    )

    @Synchronized
    private fun ensureReady() {
        if (ready) return
        YoutubeDL.getInstance().init(context)
        FFmpeg.getInstance().init(context)
        ready = true
    }

    private fun outputDir(): File {
        val dir = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "Grab")
        } else {
            File(context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS), "Grab")
        }
        dir.mkdirs()
        return dir
    }

    private fun runDownload(job: Job) {
        emit(mapOf("id" to job.id, "status" to "starting"))
        active[job.id] = job.title to 0f
        refreshService()
        val startedAt = System.currentTimeMillis() - 2_000
        try {
            ensureReady()
            val dir = outputDir()
            val req = YoutubeDLRequest(job.url)
            req.addOption("-o", File(dir, "%(title).80B [%(id)s]${job.suffix}.%(ext)s").absolutePath)
            req.addOption("--no-mtime")
            req.addOption("--no-playlist")
            req.addOption("--print", "after_move:filepath")
            req.addOption("--no-simulate")
            for (a in job.args) req.addOption(a)
            val resp = YoutubeDL.getInstance().execute(req, job.id) { progress, eta, line ->
                active[job.id] = job.title to progress
                refreshService()
                emit(mapOf("id" to job.id, "status" to "running", "progress" to progress.toDouble(), "eta" to eta, "line" to line))
            }
            val paths = collectOutputs(dir, resp.out, job.match, startedAt)
            if (paths.isNotEmpty()) MediaScannerConnection.scanFile(context, paths.toTypedArray(), null, null)
            emit(mapOf("id" to job.id, "status" to "done", "progress" to 100.0, "paths" to paths))
        } catch (e: YoutubeDL.CanceledException) {
            emit(mapOf("id" to job.id, "status" to "canceled"))
        } catch (e: Throwable) {
            emit(mapOf("id" to job.id, "status" to "error", "error" to (e.message ?: e.toString())))
        } finally {
            active.remove(job.id)
            refreshService()
        }
    }

    /**
     * The media file comes from yt-dlp's --print output. Subtitle files (.srt) are not printed,
     * so we also pick up files written during this job whose name carries the item's id.
     */
    private fun collectOutputs(dir: File, out: String, match: String?, since: Long): List<String> {
        val printed = out.lines().map { it.trim() }.filter { it.isNotEmpty() && File(it).exists() }
        val extra = if (match.isNullOrEmpty()) emptyList() else
            dir.listFiles().orEmpty()
                .filter { it.isFile && it.name.contains(match) && it.lastModified() >= since && !it.name.endsWith(".part") }
                .map { it.absolutePath }
        return (printed + extra).distinct()
    }

    private fun refreshService() {
        val snapshot = active.values.toList()
        main.post { DownloadService.update(context, snapshot) }
    }

    private fun emit(event: Map<String, Any?>) = main.post { sink?.success(event) }

    private fun background(result: MethodChannel.Result, work: () -> Any?) {
        pool.execute {
            try {
                val value = work()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                main.post { result.error("engine", e.message ?: e.toString(), null) }
            }
        }
    }
}
