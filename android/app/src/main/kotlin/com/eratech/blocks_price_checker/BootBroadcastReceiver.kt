// package com.eratech.blocks_price_checker

// import android.content.BroadcastReceiver
// import android.content.Context
// import android.content.Intent
// import android.util.Log

// class BootBroadcastReceiver : BroadcastReceiver() {
//     override fun onReceive(context: Context?, intent: Intent?) {
//         if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
//             // Boot complete hone par Flutter app ko launch karne ka code
//             val launchIntent = Intent(context, MainActivity::class.java)
//             launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
//             context?.startActivity(launchIntent)
//             Log.d("BootReceiver", "App launched after boot")
//         }
//     }
// }


package com.eratech.blocks_price_checker // Replace with your actual package name

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log

class BootBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // Acquire a wake lock to ensure the app stays active
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "BootBroadcastReceiver::WakeLock"
            )
            wakeLock.acquire(10 * 60 * 1000L /*10 minutes*/) // Acquire the lock for 10 minutes

            // Intent to launch the MainActivity
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            context.startActivity(launchIntent)
            Log.d("BootBroadcastReceiver", "App launched after boot")

            // Release the wake lock after starting the activity
            wakeLock.release()
        }
    }
}
