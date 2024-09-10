package com.example.blocks_guide

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    private val CHANNEL = "your_channel_name"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(FlutterEngine(this))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startKioskMode") {
                // Trigger custom broadcast for testing BootBroadcastReceiver
                val intent = Intent("com.example.blocks_guide.CUSTOM_ACTION")
                sendBroadcast(intent)

                // Respond with a success message to the Flutter side
                val jsonObject: Map<String, Any?> = mapOf(
                    "code" to 200,
                )
                result.success(jsonObject)
            }
        }
    }
}
                          