package com.colombopal.colombo_pal

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    // Pull model: Dart asks for this once its handler exists, so a cold-start
    // trigger can't be lost to a channel race.
    private var pendingSosSource: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleSosIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (handleSosIntent(intent)) channel?.invokeMethod("sosPending", null)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeLaunchTrigger" -> {
                        result.success(pendingSosSource)
                        pendingSosSource = null
                    }
                    "isVolumeTriggerEnabled" -> result.success(SosPrefs.isVolumeEnabled(this))
                    "setVolumeTriggerEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        SosPrefs.setVolumeEnabled(this, enabled)
                        if (enabled) {
                            requestNotificationPermissionIfNeeded()
                            VolumeSosService.start(this)
                        } else {
                            VolumeSosService.stop(this)
                        }
                        result.success(enabled)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** Returns true when [intent] is an SOS trigger and records its source. */
    private fun handleSosIntent(intent: Intent?): Boolean {
        val isSos = intent?.action == SosTrigger.ACTION_SOS
        if (isSos) pendingSosSource = intent?.getStringExtra(SosTrigger.EXTRA_SOURCE) ?: "unknown"
        showOverLockScreen(isSos)
        return isSos
    }

    // Lets the SOS screen appear on a locked, sleeping phone. Reset for normal
    // launches so the app doesn't bypass the lock screen the rest of the time.
    private fun showOverLockScreen(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enabled)
            setTurnScreenOn(enabled)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (enabled) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    // Without this the foreground-service notice and SOS alert are silently dropped on Android 13+.
    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
        }
    }

    companion object {
        private const val CHANNEL = "colombo_pal/sos"
        private const val REQUEST_NOTIFICATIONS = 7001
    }
}
