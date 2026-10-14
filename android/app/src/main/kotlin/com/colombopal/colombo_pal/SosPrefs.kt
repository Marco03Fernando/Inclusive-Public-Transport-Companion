package com.colombopal.colombo_pal

import android.content.Context

/** Native-side copy of the volume-trigger switch so [BootReceiver] can read it without Flutter. */
object SosPrefs {
    private const val FILE = "sos_prefs"
    private const val KEY_VOLUME_ENABLED = "volume_trigger_enabled"

    fun isVolumeEnabled(context: Context): Boolean =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE).getBoolean(KEY_VOLUME_ENABLED, false)

    fun setVolumeEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
            .edit().putBoolean(KEY_VOLUME_ENABLED, enabled).apply()
    }
}
