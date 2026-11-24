package app.grab.grab

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Home screen widget: the buddy in its chosen hat, the current streak and level,
 * and a button that opens Grab on the copied link (like the Quick Settings tile).
 * The app pushes the numbers through channel "grab/widget": update(streak, level, hat).
 */
class GrabWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { manager.updateAppWidget(it, views(context)) }
    }

    companion object {
        private const val PREFS = "grab_widget"

        fun channel(context: Context, messenger: BinaryMessenger) {
            MethodChannel(messenger, "grab/widget").setMethodCallHandler { call, result ->
                if (call.method != "update") return@setMethodCallHandler result.notImplemented()
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                    .putInt("streak", call.argument<Int>("streak") ?: 0)
                    .putString("level", call.argument<String>("level") ?: "")
                    .putString("hat", call.argument<String>("hat") ?: "none")
                    .apply()
                refresh(context)
                result.success(null)
            }
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, GrabWidget::class.java))
            if (ids.isEmpty()) return
            val v = views(context)
            ids.forEach { manager.updateAppWidget(it, v) }
        }

        private fun views(context: Context): RemoteViews {
            val p = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val streak = p.getInt("streak", 0)
            val level = p.getString("level", "") ?: ""
            val hat = p.getString("hat", "none") ?: "none"
            val buddy = context.resources.getIdentifier("widget_buddy_$hat", "drawable", context.packageName)
                .takeIf { it != 0 } ?: R.drawable.widget_buddy_none

            val grab = PendingIntent.getActivity(
                context, 1,
                Intent(context, MainActivity::class.java)
                    .setAction(GrabTileService.ACTION_GRAB_CLIPBOARD)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val open = PendingIntent.getActivity(
                context, 2,
                Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            return RemoteViews(context.packageName, R.layout.grab_widget).apply {
                setImageViewResource(R.id.widget_buddy, buddy)
                setTextViewText(
                    R.id.widget_streak,
                    when (streak) {
                        0 -> "Start a streak"
                        1 -> "🔥 1-day streak"
                        else -> "🔥 $streak-day streak"
                    },
                )
                setTextViewText(R.id.widget_level, level.ifEmpty { "Grab Club" })
                setOnClickPendingIntent(R.id.widget_grab, grab)
                setOnClickPendingIntent(R.id.widget_root, open)
            }
        }
    }
}
