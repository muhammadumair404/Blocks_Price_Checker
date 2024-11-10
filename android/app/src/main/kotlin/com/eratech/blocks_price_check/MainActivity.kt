package com.eratech.blocks_price_check

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.eratech.blocks_price_check/kiosk_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    if (startKioskMode()) {
                        result.success(true)
                    } else {
                        result.error("KIOSK_MODE_ERROR", "Failed to start Kiosk Mode", null)
                    }
                }
                "stopKioskMode" -> {
                    if (stopKioskMode()) {
                        result.success(true)
                    } else {
                        result.error("KIOSK_MODE_ERROR", "Failed to stop Kiosk Mode", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startKioskMode(): Boolean {
        return try {
            val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)
            if (dpm.isDeviceOwnerApp(packageName)) {
                dpm.setLockTaskPackages(componentName, arrayOf(packageName))
                startLockTask()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun stopKioskMode(): Boolean {
        return try {
            stopLockTask()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
