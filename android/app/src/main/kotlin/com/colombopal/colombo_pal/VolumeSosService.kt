package com.colombopal.colombo_pal

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.SystemClock

/**
 * Foreground service that listens for a quick Up-Down-Up (or Down-Up-Down)
 * volume-button sequence so SOS can be raised with the screen off or the app
 * closed. Alternation is required because pressing the same button 3 times is
 * just normal volume adjusting.
 *
 * It watches Android's volume-changed broadcast rather than raw key events, so
 * no accessibility permission is needed. A press that doesn't change the
 * volume (already at max/min) isn't seen, but alternating presses always
 * change it, so the gesture still completes (at most one extra press).
 */
class VolumeSosService : Service() {
    // Recent presses, oldest first, as (time, direction) where direction is
    // +1 (volume up), -1 (volume down) or 0 (unknown).
    private val presses = ArrayDeque<Pair<Long, Int>>()
    private var lastEventAt = 0L

    private val volumeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val now = SystemClock.elapsedRealtime()
            // One physical press can emit several broadcasts (one per linked stream).
            if (now - lastEventAt < MIN_GAP_MS) return
            lastEventAt = now

            val direction = directionOf(intent)
            // Same direction twice in a row is ordinary volume adjusting, not
            // the SOS gesture, so restart the sequence from this press.
            if (direction != 0 && presses.lastOrNull()?.second == direction) presses.clear()
            presses.addLast(now to direction)
            while (presses.isNotEmpty() && now - presses.first().first > WINDOW_MS) presses.removeFirst()

            if (presses.size >= REQUIRED_PRESSES) {
                presses.clear()
                SosTrigger.fireFromBackground(context, SosTrigger.SOURCE_VOLUME)
            }
        }
    }

    private fun directionOf(intent: Intent): Int {
        val now = intent.getIntExtra(EXTRA_VOLUME_VALUE, -1)
        val prev = intent.getIntExtra(EXTRA_PREV_VOLUME_VALUE, -1)
        return if (now < 0 || prev < 0) 0 else Integer.signum(now - prev)
    }

    override fun onCreate() {
        super.onCreate()
        startAsForeground()
        val filter = IntentFilter(VOLUME_CHANGED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // The broadcast comes from the system process, so it must be exported.
            registerReceiver(volumeReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(volumeReceiver, filter)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        unregisterReceiver(volumeReceiver)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startAsForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    getString(R.string.sos_service_channel_name),
                    NotificationManager.IMPORTANCE_LOW
                )
            )
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }

        val openApp = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java), SosTrigger.pendingIntentFlags()
        )
        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.sos_service_title))
            .setContentText(getString(R.string.sos_service_text, REQUIRED_PRESSES))
            .setOngoing(true)
            .setContentIntent(openApp)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        /** Hidden-API constant, but long stable and widely relied on. */
        private const val VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION"

        private const val EXTRA_VOLUME_VALUE = "android.media.EXTRA_VOLUME_STREAM_VALUE"
        private const val EXTRA_PREV_VOLUME_VALUE = "android.media.EXTRA_PREV_VOLUME_STREAM_VALUE"

        private const val CHANNEL_ID = "sos_shortcut_service"
        private const val NOTIFICATION_ID = 4100

        /** Alternating up/down presses needed, all within [WINDOW_MS]. */
        const val REQUIRED_PRESSES = 3
        private const val WINDOW_MS = 2000L
        private const val MIN_GAP_MS = 80L

        fun start(context: Context) {
            val intent = Intent(context, VolumeSosService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, VolumeSosService::class.java))
        }
    }
}
