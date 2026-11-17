package app.grab.grab

import android.content.Context
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Crisp, iPhone-like haptics. Flutter's HapticFeedback maps to whatever the phone's
 * default buzz is; here we use Android's haptic primitives (short, sharp taps from the
 * actuator) when the phone supports them, and fall back to predefined effects.
 *
 * Channel "grab/haptics", method "play" with a type:
 * selection | light | medium | heavy | soft | success | warning | error
 */
class HapticsPlugin(context: Context, messenger: BinaryMessenger) {
    private val vibrator: Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    init {
        MethodChannel(messenger, "grab/haptics").setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    play(call.argument<String>("type") ?: "light")
                    result.success(null)
                }
                "supportsPrimitives" -> result.success(supportsPrimitives())
                else -> result.notImplemented()
            }
        }
    }

    private fun supportsPrimitives(): Boolean {
        val v = vibrator ?: return false
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return false
        return v.areAllPrimitivesSupported(
            VibrationEffect.Composition.PRIMITIVE_CLICK,
            VibrationEffect.Composition.PRIMITIVE_TICK,
            VibrationEffect.Composition.PRIMITIVE_LOW_TICK,
        )
    }

    private fun play(type: String) {
        val v = vibrator ?: return
        if (!v.hasVibrator()) return
        val effect = if (supportsPrimitives()) composed(type) else predefined(type)
        effect ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Touch usage respects the user's "touch feedback" system setting.
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH))
        } else {
            v.vibrate(effect)
        }
    }

    /** Short taps built from primitives (API 30+): closest to iOS's Taptic Engine. */
    private fun composed(type: String): VibrationEffect? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val c = VibrationEffect.startComposition()
        val tick = VibrationEffect.Composition.PRIMITIVE_TICK
        val click = VibrationEffect.Composition.PRIMITIVE_CLICK
        val low = VibrationEffect.Composition.PRIMITIVE_LOW_TICK
        when (type) {
            "selection" -> c.addPrimitive(tick, 0.45f)
            "soft" -> c.addPrimitive(low, 0.6f)
            "light" -> c.addPrimitive(click, 0.45f)
            "medium" -> c.addPrimitive(click, 0.75f)
            "heavy" -> c.addPrimitive(click, 1.0f)
            // iOS "success": a light tap then a firm one.
            "success" -> c.addPrimitive(click, 0.5f).addPrimitive(click, 1.0f, 70)
            // iOS "warning": firm then light.
            "warning" -> c.addPrimitive(click, 1.0f).addPrimitive(click, 0.5f, 90)
            // iOS "error": three quick taps.
            "error" -> c.addPrimitive(click, 0.8f).addPrimitive(click, 0.8f, 60).addPrimitive(click, 1.0f, 60)
            else -> c.addPrimitive(click, 0.5f)
        }
        return c.compose()
    }

    /** Older phones: the closest predefined effects. */
    private fun predefined(type: String): VibrationEffect? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val id = when (type) {
                "selection", "soft" -> VibrationEffect.EFFECT_TICK
                "light", "medium" -> VibrationEffect.EFFECT_CLICK
                "heavy" -> VibrationEffect.EFFECT_HEAVY_CLICK
                "success", "warning", "error" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                else -> VibrationEffect.EFFECT_CLICK
            }
            return VibrationEffect.createPredefined(id)
        }
        val ms = when (type) {
            "selection", "soft" -> 8L
            "heavy" -> 25L
            "success", "warning", "error" -> 30L
            else -> 14L
        }
        return VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
    }
}
