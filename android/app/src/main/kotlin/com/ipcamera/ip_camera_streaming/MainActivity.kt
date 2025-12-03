package com.ipcamera.ip_camera_streaming

import android.Manifest
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ipcamera.ip_camera_streaming.serv.StreamingManager
import com.ipcamera.ip_camera_streaming.serv.NetworkMonitor

class MainActivity : FlutterActivity() {
    private val STREAMING_CHANNEL = "com.ipcamera/streaming"
    private val NETWORK_CHANNEL = "com.ipcamera/network"
    private val MICROPHONE_PERMISSION_REQUEST_CODE = 1001
    private val CAMERA_PERMISSION_REQUEST_CODE = 1002
    
    private var streamingManager: StreamingManager? = null
    private var networkMonitor: NetworkMonitor? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingPermissionType: String? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        streamingManager = StreamingManager(this)
        networkMonitor = NetworkMonitor(this)
        
        // Streaming channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STREAMING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCameras" -> {
                    val cameras = streamingManager?.enumerateCameras() ?: emptyList()
                    result.success(cameras)
                }
                "getResolutions" -> {
                    val cameraId = call.argument<String>("cameraId")
                    if (cameraId != null) {
                        val resolutions = streamingManager?.getResolutions(cameraId) ?: emptyList()
                        result.success(resolutions)
                    } else {
                        result.error("INVALID_ARGUMENTS", "cameraId is required", null)
                    }
                }
                "startStreaming" -> {
                    val config = call.arguments as? Map<String, Any>
                    if (config != null) {
                        try {
                            streamingManager?.startStreaming(config)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("START_FAILED", "Failed to start streaming: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Configuration is required", null)
                    }
                }
                "stopStreaming" -> {
                    streamingManager?.stopStreaming()
                    result.success(null)
                }
                "getStatistics" -> {
                    val stats = streamingManager?.getStatistics() ?: emptyMap<String, Any>()
                    result.success(stats)
                }
                "requestMicrophonePermission" -> {
                    requestMicrophonePermission(result)
                }
                "hasMicrophonePermission" -> {
                    val hasPermission = checkMicrophonePermission()
                    result.success(hasPermission)
                }
                "requestCameraPermission" -> {
                    requestCameraPermission(result)
                }
                "hasCameraPermission" -> {
                    val hasPermission = checkCameraPermission()
                    result.success(hasPermission)
                }
                "startForegroundService" -> {
                    startForegroundService()
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopForegroundService()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Network channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startNetworkMonitoring" -> {
                    networkMonitor?.startMonitoring { networkType, ipAddress ->
                        val data = mapOf(
                            "networkType" to networkType,
                            "ipAddress" to ipAddress
                        )
                        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
                            .invokeMethod("onNetworkChanged", data)
                        
                        if (networkType != "none") {
                            streamingManager?.handleNetworkChange()
                        }
                    }
                    result.success(null)
                }
                "stopNetworkMonitoring" -> {
                    networkMonitor?.stopMonitoring()
                    result.success(null)
                }
                "getCurrentNetwork" -> {
                    val network = networkMonitor?.getCurrentNetwork() ?: mapOf(
                        "networkType" to "none",
                        "ipAddress" to ""
                    )
                    result.success(network)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun checkMicrophonePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestMicrophonePermission(result: MethodChannel.Result) {
        if (checkMicrophonePermission()) {
            result.success(true)
            return
        }
        
        pendingPermissionResult = result
        pendingPermissionType = "microphone"
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            MICROPHONE_PERMISSION_REQUEST_CODE
        )
    }
    
    private fun checkCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }
    
    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (checkCameraPermission()) {
            result.success(true)
            return
        }
        
        pendingPermissionResult = result
        pendingPermissionType = "camera"
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.CAMERA),
            CAMERA_PERMISSION_REQUEST_CODE
        )
    }
    
    private fun startForegroundService() {
        // Start foreground service for background streaming
    }
    
    private fun stopForegroundService() {
        // Stop foreground service
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            MICROPHONE_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults[0] == PackageManager.PERMISSION_GRANTED
                
                if (!granted && pendingPermissionType == "microphone") {
                    pendingPermissionResult?.error(
                        "PERMISSION_DENIED",
                        "Microphone permission is required to capture audio for streaming.",
                        null
                    )
                } else {
                    pendingPermissionResult?.success(granted)
                }
                pendingPermissionResult = null
                pendingPermissionType = null
            }
            CAMERA_PERMISSION_REQUEST_CODE -> {
                val granted = grantResults.isNotEmpty() && 
                             grantResults[0] == PackageManager.PERMISSION_GRANTED
                
                if (!granted && pendingPermissionType == "camera") {
                    pendingPermissionResult?.error(
                        "PERMISSION_DENIED",
                        "Camera permission is required to capture video for streaming.",
                        null
                    )
                } else {
                    pendingPermissionResult?.success(granted)
                }
                pendingPermissionResult = null
                pendingPermissionType = null
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        streamingManager?.stopStreaming()
        networkMonitor?.stopMonitoring()
    }
}
