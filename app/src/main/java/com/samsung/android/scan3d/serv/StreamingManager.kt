package com.samsung.android.scan3d.serv

import android.content.Context
import android.media.MediaCodec
import android.os.BatteryManager
import android.os.PowerManager
import android.util.Log
import android.util.Size
import com.samsung.android.scan3d.streaming.*
import kotlinx.coroutines.*
import java.nio.ByteBuffer

/**
 * StreamingManager coordinates all streaming components for the IP Camera Streaming Platform.
 * 
 * This class orchestrates camera capture, hardware encoding, and streaming protocols (RTSP/RTMP)
 * to provide a unified streaming interface.
 */
class StreamingManager(private val context: Context) {
    companion object {
        private const val TAG = "StreamingManager"
        private const val STATS_UPDATE_INTERVAL_MS = 1000L
        
        @Volatile
        private var instance: StreamingManager? = null
        
        fun getInstance(context: Context): StreamingManager? {
            return instance
        }
        
        fun setInstance(manager: StreamingManager) {
            instance = manager
        }
    }

    // Components
    private var cameraCapture: CameraCapture? = null
    private var videoEncoder: VideoEncoder? = null
    private var audioEncoder: AudioEncoder? = null
    private var rtspServer: RTSPServer? = null
    private val rtmpClients = mutableListOf<RTMPClient>()

    // State
    private var isStreaming = false
    private val lock = Any()

    // Configuration
    private var currentConfig: StreamConfig? = null

    // Statistics
    private var videoFrameCount = 0
    private var audioFrameCount = 0
    private var droppedFrameCount = 0
    private var lastStatsUpdateTime = 0L
    private var lastFrameCount = 0
    private var currentFps = 0
    private var currentBitrate = 0.0
    private var lastBytesSent = 0L

    // Coroutine scope for async operations
    private val coroutineScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private var statsJob: Job? = null

    /**
     * Start streaming with the specified configuration
     * 
     * @param config Streaming configuration
     * @throws StreamingException if streaming fails to start
     */
    suspend fun startStreaming(config: StreamConfig) {
        synchronized(lock) {
            if (isStreaming) {
                throw StreamingException("Streaming is already active")
            }

            Log.i(TAG, "Starting streaming with config: $config")

            try {
                currentConfig = config

                // Initialize camera capture
                cameraCapture = CameraCapture(context).apply {
                    // Set up video frame callback
                    onVideoFrame = { image ->
                        handleVideoFrame(image)
                    }

                    // Set up audio sample callback if audio is enabled
                    if (config.audioEnabled) {
                        onAudioSample = { audioData ->
                            handleAudioSample(audioData)
                        }
                    }
                }

                // Initialize video encoder
                videoEncoder = VideoEncoder().apply {
                    configure(
                        width = config.resolution.width,
                        height = config.resolution.height,
                        frameRate = config.frameRate,
                        bitrate = config.bitrate
                    )

                    // Set up encoded frame callback
                    onEncodedFrame = { data, bufferInfo ->
                        handleEncodedVideoFrame(data, bufferInfo)
                    }
                }

                // Initialize audio encoder if audio is enabled
                if (config.audioEnabled) {
                    audioEncoder = AudioEncoder().apply {
                        configure()

                        // Set up encoded frame callback
                        onEncodedFrame = { data, bufferInfo ->
                            handleEncodedAudioFrame(data, bufferInfo)
                        }
                    }
                }

                // Initialize RTSP server if enabled
                if (config.rtspEnabled) {
                    rtspServer = RTSPServer().apply {
                        start(config.rtspPort)
                    }
                    Log.i(TAG, "RTSP server started on port ${config.rtspPort}")
                }

                // Initialize RTMP clients if enabled
                for (target in config.rtmpTargets.filter { it.enabled }) {
                    try {
                        val rtmpClient = RTMPClient().apply {
                            connect(target.url, target.streamKey)
                        }
                        rtmpClients.add(rtmpClient)
                        Log.i(TAG, "RTMP client connected to ${target.url}")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to connect RTMP client to ${target.url}", e)
                        // Continue with other targets
                    }
                }

                // Start camera capture
                cameraCapture?.start(
                    cameraId = config.cameraId,
                    resolution = Size(config.resolution.width, config.resolution.height),
                    frameRate = config.frameRate,
                    audioEnabled = config.audioEnabled
                )

                // Reset statistics
                videoFrameCount = 0
                audioFrameCount = 0
                droppedFrameCount = 0
                lastStatsUpdateTime = System.currentTimeMillis()
                lastFrameCount = 0
                currentFps = 0
                currentBitrate = 0.0
                lastBytesSent = 0L

                // Start statistics collection
                startStatisticsCollection()

                isStreaming = true
                Log.i(TAG, "Streaming started successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start streaming", e)
                // Clean up any partially initialized components
                stopStreaming()
                throw StreamingException("Failed to start streaming: ${e.message}", e)
            }
        }
    }

    /**
     * Stop streaming and release all resources
     */
    fun stopStreaming() {
        synchronized(lock) {
            if (!isStreaming) {
                Log.w(TAG, "Streaming is not active")
                return
            }

            Log.i(TAG, "Stopping streaming")

            try {
                // Stop statistics collection
                statsJob?.cancel()
                statsJob = null

                // Stop camera capture
                cameraCapture?.stop()
                cameraCapture?.destroy()
                cameraCapture = null

                // Shutdown encoders
                videoEncoder?.shutdown()
                videoEncoder = null

                audioEncoder?.shutdown()
                audioEncoder = null

                // Stop RTSP server
                rtspServer?.stop()
                rtspServer = null

                // Disconnect RTMP clients
                for (client in rtmpClients) {
                    try {
                        client.disconnect()
                        client.cleanup()
                    } catch (e: Exception) {
                        Log.w(TAG, "Error disconnecting RTMP client", e)
                    }
                }
                rtmpClients.clear()

                isStreaming = false
                currentConfig = null

                Log.i(TAG, "Streaming stopped successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping streaming", e)
                isStreaming = false
            }
        }
    }

    /**
     * Get current streaming statistics
     * 
     * @return StreamStatistics object with current metrics
     */
    fun getStatistics(): StreamStatistics {
        synchronized(lock) {
            val connectionStatus = mutableMapOf<String, String>()

            // RTSP connection status
            if (currentConfig?.rtspEnabled == true) {
                connectionStatus["rtsp"] = if (rtspServer?.isRunning() == true) {
                    "connected"
                } else {
                    "disconnected"
                }
            }

            // RTMP connection status
            for ((index, client) in rtmpClients.withIndex()) {
                val targetName = currentConfig?.rtmpTargets?.getOrNull(index)?.url ?: "rtmp_$index"
                connectionStatus[targetName] = if (client.isConnected()) {
                    "connected"
                } else {
                    "error"
                }
            }

            // Get device temperature
            val temperature = getDeviceTemperature()

            // Get battery level
            val batteryLevel = getBatteryLevel()

            return StreamStatistics(
                currentBitrate = currentBitrate,
                currentFps = currentFps,
                droppedFrames = droppedFrameCount,
                deviceTemperature = temperature,
                batteryLevel = batteryLevel,
                connectionStatus = connectionStatus
            )
        }
    }

    /**
     * Enumerate all available cameras
     * 
     * @return List of CameraInfo objects
     */
    fun enumerateCameras(): List<CameraInfo> {
        val capture = CameraCapture(context)
        return capture.enumerateCameras().map { cameraInfo ->
            CameraInfo(
                id = cameraInfo.id,
                name = cameraInfo.name,
                position = cameraInfo.position,
                capabilities = cameraInfo.capabilities
            )
        }
    }

    /**
     * Get available resolutions for a specific camera
     * 
     * @param cameraId Camera identifier
     * @return List of Resolution objects
     */
    fun getResolutions(cameraId: String): List<Resolution> {
        val capture = CameraCapture(context)
        return capture.getResolutions(cameraId).map { resolution ->
            Resolution(
                width = resolution.width,
                height = resolution.height
            )
        }
    }

    /**
     * Check if streaming is currently active
     * 
     * @return true if streaming, false otherwise
     */
    fun isStreaming(): Boolean {
        synchronized(lock) {
            return isStreaming
        }
    }

    /**
     * Clean up all resources
     */
    fun cleanup() {
        stopStreaming()
        coroutineScope.cancel()
    }
    
    /**
     * Handle network change event - attempt to reconnect RTMP clients
     */
    fun handleNetworkChange() {
        if (!isStreaming) return
        
        Log.i(TAG, "Network change detected, attempting to reconnect RTMP clients")
        
        // Attempt to reconnect disconnected RTMP clients
        coroutineScope.launch {
            for (client in rtmpClients) {
                if (!client.isConnected()) {
                    try {
                        client.reconnect()
                        Log.i(TAG, "RTMP client reconnected after network change")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to reconnect RTMP client", e)
                    }
                }
            }
        }
    }

    // MARK: - Private Methods

    /**
     * Handle video frame from camera
     */
    private fun handleVideoFrame(image: android.media.Image) {
        try {
            videoEncoder?.encode(image)
            videoFrameCount++
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encode video frame", e)
            droppedFrameCount++
        }
    }

    /**
     * Handle audio sample from microphone
     */
    private fun handleAudioSample(audioData: ByteArray) {
        try {
            audioEncoder?.encode(audioData)
            audioFrameCount++
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encode audio sample", e)
        }
    }

    /**
     * Handle encoded video frame
     */
    private fun handleEncodedVideoFrame(data: ByteBuffer, bufferInfo: MediaCodec.BufferInfo) {
        try {
            val isKeyframe = (bufferInfo.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME) != 0
            val timestamp = bufferInfo.presentationTimeUs

            // Feed to RTSP server
            rtspServer?.feedVideoFrame(data.duplicate(), timestamp, isKeyframe)

            // Feed to RTMP clients
            val timestampMs = (timestamp / 1000).toInt()
            for (client in rtmpClients) {
                try {
                    if (client.isConnected()) {
                        client.sendVideoFrame(data.duplicate(), timestampMs, isKeyframe)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to send video frame to RTMP client", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle encoded video frame", e)
        }
    }

    /**
     * Handle encoded audio frame
     */
    private fun handleEncodedAudioFrame(data: ByteBuffer, bufferInfo: MediaCodec.BufferInfo) {
        try {
            val timestamp = bufferInfo.presentationTimeUs

            // Feed to RTSP server
            rtspServer?.feedAudioFrame(data.duplicate(), timestamp)

            // Feed to RTMP clients
            val timestampMs = (timestamp / 1000).toInt()
            for (client in rtmpClients) {
                try {
                    if (client.isConnected()) {
                        client.sendAudioFrame(data.duplicate(), timestampMs)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to send audio frame to RTMP client", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to handle encoded audio frame", e)
        }
    }

    /**
     * Start statistics collection
     */
    private fun startStatisticsCollection() {
        statsJob = coroutineScope.launch {
            while (isActive) {
                delay(STATS_UPDATE_INTERVAL_MS)
                updateStatistics()
            }
        }
    }

    /**
     * Update streaming statistics
     */
    private fun updateStatistics() {
        synchronized(lock) {
            val currentTime = System.currentTimeMillis()
            val elapsedTime = (currentTime - lastStatsUpdateTime) / 1000.0

            if (elapsedTime > 0) {
                // Calculate FPS
                val framesSinceLastUpdate = videoFrameCount - lastFrameCount
                currentFps = (framesSinceLastUpdate / elapsedTime).toInt()

                // Calculate bitrate
                var totalBytesSent = 0L
                for (client in rtmpClients) {
                    val stats = client.getStatistics()
                    totalBytesSent += stats["bytesSent"] as? Long ?: 0L
                }

                val bytesSinceLastUpdate = totalBytesSent - lastBytesSent
                currentBitrate = (bytesSinceLastUpdate * 8) / (elapsedTime * 1_000_000) // Mbps

                // Update tracking variables
                lastStatsUpdateTime = currentTime
                lastFrameCount = videoFrameCount
                lastBytesSent = totalBytesSent
            }
        }
    }

    /**
     * Get device temperature in Celsius
     */
    private fun getDeviceTemperature(): Double {
        return try {
            // Android doesn't provide a standard API for device temperature
            // This is a placeholder that returns a reasonable default
            // In production, you might use thermal API or device-specific methods
            25.0
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get device temperature", e)
            25.0
        }
    }

    /**
     * Get battery level percentage
     */
    private fun getBatteryLevel(): Int {
        return try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to get battery level", e)
            100
        }
    }

    // MARK: - Data Classes

    /**
     * Streaming configuration
     */
    data class StreamConfig(
        val cameraId: String,
        val resolution: Resolution,
        val frameRate: Int,
        val bitrate: Int,
        val audioEnabled: Boolean,
        val rtspEnabled: Boolean,
        val rtspPort: Int,
        val rtmpTargets: List<RtmpTarget>
    )

    /**
     * Resolution
     */
    data class Resolution(
        val width: Int,
        val height: Int
    )

    /**
     * RTMP target
     */
    data class RtmpTarget(
        val url: String,
        val streamKey: String,
        val enabled: Boolean
    )

    /**
     * Camera information
     */
    data class CameraInfo(
        val id: String,
        val name: String,
        val position: String,
        val capabilities: List<String>
    )

    /**
     * Streaming statistics
     */
    data class StreamStatistics(
        val currentBitrate: Double,
        val currentFps: Int,
        val droppedFrames: Int,
        val deviceTemperature: Double,
        val batteryLevel: Int,
        val connectionStatus: Map<String, String>
    )

    /**
     * Exception class for streaming errors
     */
    class StreamingException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
