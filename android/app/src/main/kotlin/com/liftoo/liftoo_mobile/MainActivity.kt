package com.liftoo.liftoo_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    companion object {
        const val NOTIFICATION_CHANNEL_ID = "liftoo_alerts"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createAlertNotificationChannel()
        }
    }

    private fun createAlertNotificationChannel() {
        val manager = getSystemService(NotificationManager::class.java) ?: return

        // Recreate channel so sound/vibration apply (Android locks channel settings after first create).
        manager.deleteNotificationChannel("liftoo_default")
        manager.deleteNotificationChannel(NOTIFICATION_CHANNEL_ID)

        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Liftoo alerts",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Booking updates with sound and vibration"
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 300, 200, 300)
            enableLights(true)
            setSound(soundUri, audioAttributes)
            setBypassDnd(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }

        manager.createNotificationChannel(channel)
    }
}
