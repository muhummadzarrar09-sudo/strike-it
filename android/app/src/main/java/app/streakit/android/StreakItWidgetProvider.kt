package app.streakit.android

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class StreakItWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            updateStreakWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        internal fun updateStreakWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.streak_widget)
            val streak = widgetData.getInt("streak", 0)
            val checkedIn = widgetData.getBoolean("checked_in_today", false)

            views.setTextViewText(R.id.widget_streak_count, streak.toString())
            views.setTextViewText(
                R.id.widget_streak_label,
                if (checkedIn) "✅ DONE TODAY" else "DAY STREAK"
            )

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class QuickCheckWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            updateQuickCheckWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        internal fun updateQuickCheckWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.quick_check_widget)
            val habitNames = widgetData.getString("habit_names", "")?.split(",") ?: emptyList()
            val habitCompleted = widgetData.getString("habit_completed", "")?.split(",") ?: emptyList()

            val habitListContainer = views.apply {
                // Remove any existing views in the habit list
                removeAllViews(R.id.widget_habit_list)

                if (habitNames.isEmpty() || habitNames.first().isEmpty()) {
                    val emptyView = RemoteViews(context.packageName, android.R.layout.simple_list_item_1).apply {
                        setTextViewText(android.R.id.text1, "No habits for today")
                    }
                    addView(R.id.widget_habit_list, emptyView)
                } else {
                    habitNames.forEachIndexed { index, name ->
                        val checked = index < habitCompleted.size && habitCompleted[index] == "1"
                        val displayText = if (checked) "$name ✅" else "$name ⬜"
                        // Use a simple TextView approach via text concatenation
                        // since we can't dynamically add CompoundButtons in RemoteViews easily
                    }
                }
            }

            // Update with concatenated text in the title area as fallback
            val summary = if (habitNames.isNotEmpty() && habitNames.first().isNotEmpty()) {
                val completed = habitCompleted.take(habitNames.size).count { it == "1" }
                "$completed/${habitNames.size} done"
            } else {
                "No habits yet"
            }
            views.setTextViewText(R.id.widget_title, summary)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 1, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class ProgressRingWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val widgetData = HomeWidgetPlugin.getData(context)
        for (appWidgetId in appWidgetIds) {
            updateProgressWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        internal fun updateProgressWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences
        ) {
            val views = RemoteViews(context.packageName, R.layout.progress_widget)
            val percent = widgetData.getFloat("progress_percent", 0f)
            val percentInt = (percent * 100).toInt()

            views.setTextViewText(R.id.widget_progress_percent, "${percentInt}%")
            views.setTextViewText(
                R.id.widget_progress_label,
                if (percentInt >= 100) "ALL DONE 🔥" else "DONE TODAY"
            )

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 2, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
