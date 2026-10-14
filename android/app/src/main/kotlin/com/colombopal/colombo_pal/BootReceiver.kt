package com.colombopal.colombo_pal

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restarts the volume-press listener after a reboot if the user had it switched on. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED && SosPrefs.isVolumeEnabled(context)) {
            VolumeSosService.start(context)
        }
    }
}
