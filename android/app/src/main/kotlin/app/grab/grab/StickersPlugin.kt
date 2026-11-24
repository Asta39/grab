package app.grab.grab

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Puts a sticker made in Grab into the "Grab stickers" pack and asks WhatsApp
 * to add (or refresh) the pack. Channel "grab/stickers":
 *   addToWhatsApp(path) -> "added" | "cancelled" | "noWhatsApp" | "error:<why>"
 */
class StickersPlugin(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: () -> Activity?,
) {
    private var pending: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, "grab/stickers").setMethodCallHandler { call, result ->
            if (call.method != "addToWhatsApp") return@setMethodCallHandler result.notImplemented()
            val src = File(call.argument<String>("path")!!)
            if (!src.exists()) return@setMethodCallHandler result.success("error:The sticker file is gone")
            if (src.length() > 500 * 1024) {
                return@setMethodCallHandler result.success("error:Stickers must be under 500 KB. Try a shorter part.")
            }
            // Copy it into the pack, keeping at most the newest 28 of the user's own.
            val dir = StickerProvider.dir(context)
            src.copyTo(File(dir, "sticker_${System.currentTimeMillis()}.webp"), overwrite = true)
            StickerProvider.userStickers(context).dropLast(StickerProvider.MAX - 2).forEach { it.delete() }
            StickerProvider.bump(context)

            val pkg = listOf("com.whatsapp", "com.whatsapp.w4b").firstOrNull { installed(it) }
                ?: return@setMethodCallHandler result.success("noWhatsApp")
            val intent = Intent("com.whatsapp.intent.action.ENABLE_STICKER_PACK")
                .setPackage(pkg)
                .putExtra("sticker_pack_id", StickerProvider.PACK)
                .putExtra("sticker_pack_authority", StickerProvider.authority(context))
                .putExtra("sticker_pack_name", StickerProvider.NAME)
            val a = activity() ?: return@setMethodCallHandler result.success("error:Grab isn't open")
            try {
                pending = result
                a.startActivityForResult(intent, REQUEST)
            } catch (_: ActivityNotFoundException) {
                pending = null
                result.success("noWhatsApp")
            }
        }
    }

    private fun installed(pkg: String) = try {
        context.packageManager.getPackageInfo(pkg, 0); true
    } catch (_: Exception) { false }

    /** WhatsApp answers here; a pack that is already added still refreshes. */
    fun onResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val r = pending ?: return true
        pending = null
        val error = data?.getStringExtra("validation_error")
        r.success(
            when {
                resultCode == Activity.RESULT_OK -> "added"
                error != null && error.contains("already", ignoreCase = true) -> "added"
                error != null -> "error:$error"
                else -> "cancelled"
            },
        )
        return true
    }

    companion object {
        const val REQUEST = 4207
    }
}
