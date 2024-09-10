package com.example.blocks_guide

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.app.Notification
import android.app.admin.DevicePolicyManager
import android.content.ComponentName

class MyDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device admin enabled logic
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = Notification.Builder(context)
            .setContentTitle("Device Admin Enabled")
            .setContentText("This app is now a device admin")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
        notificationManager.notify(1, notification)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device admin disabled logic
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(1) // Cancel the notification when admin is disabled
    }
}
