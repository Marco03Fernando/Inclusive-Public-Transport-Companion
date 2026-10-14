package com.colombopal.colombo_pal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/** Shared entry point for every way of raising an SOS from outside the app UI. */
object SosTrigger {
    const val ACTION_SOS = "com.colombopal.colombo_pal.action.SOS"
    const val EXTRA_SOURCE = "sos_source"

    const val SOURCE_WIDGET = "widget"
    const val SOURCE_VOLUME = "volume"

    private const val ALERT_CHANNEL_ID = "sos_alerts"
    private const val ALERT_NOTIFICATION_ID = 4101

    fun activityIntent(context: Context, source: String): Intent =
        Intent(context, MainActivity::class.java).apply {
            action = ACTION_SOS
            putExtra(EXTRA_SOURCE, source)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
        }

    fun pendingIntentFlags(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        return flags
    }

    /**
     * Raise SOS from a context with no visible UI (the background volume
     * service). Android 10+ blocks plain background activity starts, so this
     * also posts a full-screen-intent notification, which is the sanctioned way
     * to put an urgent screen in front of the user. Worst case it shows as a
     * heads-up notification the user can tap.
     */
    fun fireFromBackground(context: Context, source: String) {
        vibrate(context)
        postAlertNotification(context, source)
        try {
            context.startActivity(activityIntent(context, source))
        } catch (_: Exception) {
            // Blocked by background-start restrictions; the notification covers it.
        }
    }

    private fun postAlertNotification(context: Context, source: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val pending = PendingIntent.getActivity(
            context, ALERT_NOTIFICATION_ID, activityIntent(context, source), pendingIntentFlags()
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                context.getString(R.string.sos_alert_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            )
            manager.createNotificationChannel(channel)
            Notification.Builder(context, ALERT_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_MAX)
        }

        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(context.getString(R.string.sos_alert_title))
            .setContentText(context.getString(R.string.sos_alert_text))
            .setCategory(Notification.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pending)
            .setFullScreenIntent(pending, true)
            .build()

        try {
            manager.notify(ALERT_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted; nothing more we can do from here.
        }
    }

    fun vibrate(context: Context) {
        val pattern = longArrayOf(0, 300, 120, 300, 120, 300)
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }
}
