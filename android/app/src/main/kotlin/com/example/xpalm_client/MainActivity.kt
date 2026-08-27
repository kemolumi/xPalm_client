package com.kemolumi.xpalm_client

import android.net.wifi.WifiManager
import android.net.wifi.WifiManager.MulticastLock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


open class MainActivity: FlutterActivity() {
    private val channel: String = "com.kemolumi.xpalm_client/multicast_lock"
    private var mLock: MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
                call, result ->
                if (call.method == "acquire") {
                    result.success(acquireMulticastLock())
                } else if (call.method == "release") {
                    result.success(releaseMulticastLock())
                }
        }
    }

    private fun acquireMulticastLock(): Boolean {
        val context = applicationContext
        val wifi: WifiManager = context.getSystemService(WIFI_SERVICE) as WifiManager
        mLock = wifi.createMulticastLock("discovery-multicast-lock")
        mLock?.acquire()
        return true
    }

    private fun releaseMulticastLock(): Boolean {
        mLock?.release()
        return true
    }
}