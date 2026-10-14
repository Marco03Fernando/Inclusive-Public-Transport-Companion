package com.colombopal.colombo_pal

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/** One-tap SOS button for the launcher home screen. */
class SosWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        // A widget tap is user-initiated, so it may start the activity directly.
        val pending = PendingIntent.getActivity(
            context,
            0,
            SosTrigger.activityIntent(context, SosTrigger.SOURCE_WIDGET),
            SosTrigger.pendingIntentFlags()
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sos_widget)
            views.setOnClickPendingIntent(R.id.sos_widget_root, pending)
            manager.updateAppWidget(id, views)
        }
    }
}
