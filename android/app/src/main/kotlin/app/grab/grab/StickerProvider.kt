package app.grab.grab

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.UriMatcher
import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File

/**
 * The "Grab stickers" pack, in the shape WhatsApp reads sticker packs:
 *   content://<authority>/metadata[/<id>]          pack details
 *   content://<authority>/stickers/<id>             the stickers in it
 *   content://<authority>/stickers_asset/<id>/<f>   one sticker or the tray icon
 * Two animated buddy stickers ship with Grab (WhatsApp needs at least three);
 * stickers the user makes are added after them, newest last, up to 30.
 */
class StickerProvider : ContentProvider() {
    companion object {
        const val PACK = "grab_stickers"
        const val NAME = "Grab stickers"
        private const val TRAY = "tray.png"
        private val STARTERS = listOf("buddy_hello.webp", "buddy_party.webp")
        const val MAX = 30

        fun authority(context: Context) = "${context.packageName}.stickers"
        fun dir(context: Context) = File(context.filesDir, "stickers").apply { mkdirs() }

        fun userStickers(context: Context): List<File> =
            dir(context).listFiles { f -> f.extension == "webp" }
                ?.sortedBy { it.lastModified() } ?: emptyList()

        /** Bumped whenever the pack changes so WhatsApp reloads it. */
        fun version(context: Context): Int =
            context.getSharedPreferences("stickers", Context.MODE_PRIVATE).getInt("version", 1)

        fun bump(context: Context) {
            val p = context.getSharedPreferences("stickers", Context.MODE_PRIVATE)
            p.edit().putInt("version", p.getInt("version", 1) + 1).apply()
        }
    }

    private lateinit var matcher: UriMatcher

    override fun onCreate(): Boolean {
        val auth = authority(context!!)
        matcher = UriMatcher(UriMatcher.NO_MATCH).apply {
            addURI(auth, "metadata", 1)
            addURI(auth, "metadata/*", 2)
            addURI(auth, "stickers/*", 3)
            addURI(auth, "stickers_asset/*/*", 4)
        }
        return true
    }

    override fun query(
        uri: Uri, projection: Array<out String>?, selection: String?,
        selectionArgs: Array<out String>?, sortOrder: String?,
    ): Cursor? = when (matcher.match(uri)) {
        1, 2 -> metadata()
        3 -> stickers()
        else -> null
    }

    private fun metadata(): Cursor = MatrixCursor(
        arrayOf(
            "sticker_pack_identifier", "sticker_pack_name", "sticker_pack_publisher",
            "sticker_pack_icon", "android_play_store_link", "ios_app_download_link",
            "sticker_pack_publisher_email", "sticker_pack_publisher_website",
            "sticker_pack_privacy_policy_website", "sticker_pack_license_agreement_website",
            "image_data_version", "whatsapp_will_not_cache_stickers", "animated_sticker_pack",
        ),
    ).apply {
        addRow(
            arrayOf<Any>(
                PACK, NAME, "Grab", TRAY, "", "", "",
                "https://asta39.github.io/grab", "", "",
                version(context!!).toString(), 0, 1,
            ),
        )
    }

    private fun stickers(): Cursor =
        MatrixCursor(arrayOf("sticker_file_name", "sticker_emoji", "sticker_accessibility_text")).apply {
            for (s in STARTERS) addRow(arrayOf<Any>(s, "😀", "Grab buddy"))
            for (f in userStickers(context!!).takeLast(MAX - STARTERS.size)) {
                addRow(arrayOf<Any>(f.name, "🎬", "Sticker made in Grab"))
            }
        }

    override fun openAssetFile(uri: Uri, mode: String): AssetFileDescriptor? {
        if (matcher.match(uri) != 4) return null
        val name = uri.lastPathSegment ?: return null
        val ctx = context!!
        if (name == TRAY || name in STARTERS) return ctx.assets.openFd("stickers/$name")
        val file = File(dir(ctx), name)
        if (!file.exists() || file.parentFile != dir(ctx)) return null
        return AssetFileDescriptor(
            ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY), 0, file.length(),
        )
    }

    override fun getType(uri: Uri): String? = when (matcher.match(uri)) {
        1 -> "vnd.android.cursor.dir/vnd.$PACK.metadata"
        2 -> "vnd.android.cursor.item/vnd.$PACK.metadata"
        3 -> "vnd.android.cursor.dir/vnd.$PACK.stickers"
        4 -> if (uri.lastPathSegment?.endsWith(".png") == true) "image/png" else "image/webp"
        else -> null
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?) = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?) = 0
}
