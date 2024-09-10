package com.example.blocks_guide

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.blocks_guide/kiosk_mode"
    private var isKioskModeActive = false // Flag to track Kiosk Mode state

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Ensure flutterEngine is not null before creating MethodChannel
        flutterEngine?.dartExecutor?.binaryMessenger?.let { binaryMessenger ->
            MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "startKioskMode" -> {
                        if (startKioskMode()) {
                            result.success("Kiosk Mode Started")
                        } else {
                            result.error("ERROR", "Failed to start Kiosk Mode", null)
                        }
                    }
                    "stopKioskMode" -> {
                        if (stopKioskMode()) {
                            result.success("Kiosk Mode Stopped")
                        } else {
                            result.error("ERROR", "Failed to stop Kiosk Mode", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun startKioskMode(): Boolean {
        return try {
            if (!isKioskModeActive) {
                val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
                val componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)
                if (dpm.isDeviceOwnerApp(packageName)) {
                    dpm.setLockTaskPackages(componentName, arrayOf(packageName))
                    startLockTask()
                    isKioskModeActive = true // Set the flag to true
                    true
                } else {
                    false // Device owner check failed
                }
            } else {
                true // Already in Kiosk Mode, no need to start again
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun stopKioskMode(): Boolean {
        return try {
            if (isKioskModeActive) {
                stopLockTask()
                isKioskModeActive = false // Reset the flag
                true
            } else {
                false // Not in Kiosk Mode, nothing to stop
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
