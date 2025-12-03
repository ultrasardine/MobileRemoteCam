package com.samsung.android.scan3d.serv

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter method channel handler for network monitoring
 */
class NetworkChannelHandler(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {
    
    private val networkMonitor = NetworkMonitor(context)
    private val mainHandler = Handler(Looper.getMainLooper())
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startNetworkMonitoring" -> {
                handleStartNetworkMonitoring(result)
            }
            "stopNetworkMonitoring" -> {
                handleStopNetworkMonitoring(result)
            }
            "getCurrentNetwork" -> {
                handleGetCurrentNetwork(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleStartNetworkMonitoring(result: MethodChannel.Result) {
        try {
            networkMonitor.startMonitoring { networkType, ipAddress ->
                // Invoke Flutter callback on main thread
                mainHandler.post {
                    val data = mapOf(
                        "networkType" to networkType,
                        "ipAddress" to ipAddress
                    )
                    channel.invokeMethod("onNetworkChanged", data)
                }
                
                // Handle RTMP reconnection on network change
                if (networkType != "none") {
                    StreamingManager.getInstance(context)?.handleNetworkChange()
                }
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("START_MONITORING_FAILED", e.message, null)
        }
    }
    
    private fun handleStopNetworkMonitoring(result: MethodChannel.Result) {
        try {
            networkMonitor.stopMonitoring()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_MONITORING_FAILED", e.message, null)
        }
    }
    
    private fun handleGetCurrentNetwork(result: MethodChannel.Result) {
        try {
            val (networkType, ipAddress) = networkMonitor.getCurrentNetwork()
            val data = mapOf(
                "networkType" to networkType,
                "ipAddress" to ipAddress
            )
            result.success(data)
        } catch (e: Exception) {
            result.error("GET_NETWORK_FAILED", e.message, null)
        }
    }
}
