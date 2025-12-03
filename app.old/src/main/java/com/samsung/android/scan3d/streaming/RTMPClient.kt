package com.samsung.android.scan3d.streaming

import android.util.Log
import kotlinx.coroutines.*
import java.nio.ByteBuffer

/**
 * RTMP Client implementation using librtmp library via JNI
 * for the IP Camera Streaming Platform.
 * 
 * This class provides RTMP streaming capabilities for cloud platforms
 * like YouTube and Twitch.
 */
class RTMPClient {
    companion object {
        private const val TAG = "RTMPClient"
        private const val MAX_RECONNECTION_ATTEMPTS = 5
        
        init {
            try {
                System.loadLibrary("rtmp_client_jni")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e)
                throw RTMPClientException("Failed to load native library: ${e.message}", e)
            }
        }
    }

    // Native method declarations
    private external fun nativeConnect(url: String, streamKey: String): Long
    private external fun nativeDisconnect(handle: Long)
    private external fun nativeSendVideo(handle: Long, data: ByteArray, timestamp: Int, isKeyframe: Boolean): Boolean
    private external fun nativeSendAudio(handle: Long, data: ByteArray, timestamp: Int): Boolean
    private external fun nativeReconnect(handle: Long): Boolean
    private external fun nativeGetReconnectionAttempts(handle: Long): Int

    private var nativeHandle: Long = 0
    private var rtmpURL: String = ""
    private var streamKey: String = ""
    private var isConnected: Boolean = false
    private val lock = Any()
    
    // Statistics
    private var videoFrameCount: Long = 0
    private var audioFrameCount: Long = 0
    private var bytesSent: Long = 0
    
    // Reconnection state
    private var reconnectionJob: Job? = null
    private val coroutineScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    /**
     * Connect to RTMP server with URL and stream key
     * 
     * @param url RTMP server URL (e.g., rtmp://a.rtmp.youtube.com/live2)
     * @param streamKey Stream authentication key
     * @throws RTMPClientException if connection fails
     */
    fun connect(url: String, streamKey: String) {
        synchronized(lock) {
            if (isConnected) {
                throw RTMPClientException("RTMP client is already connected")
            }

            // Validate RTMP URL format
            if (!isValidRTMPURL(url)) {
                throw RTMPClientException("Invalid RTMP URL format. Expected: rtmp://[host]/[app]")
            }

            // Validate stream key is not empty
            if (streamKey.isEmpty()) {
                throw RTMPClientException("Stream key cannot be empty")
            }

            this.rtmpURL = url
            this.streamKey = streamKey

            try {
                Log.i(TAG, "Connecting to RTMP server: $url")
                
                nativeHandle = nativeConnect(url, streamKey)
                
                if (nativeHandle == 0L) {
                    throw RTMPClientException("Failed to connect to RTMP server: native initialization failed")
                }

                isConnected = true
                
                // Reset statistics
                videoFrameCount = 0
                audioFrameCount = 0
                bytesSent = 0
                
                Log.i(TAG, "RTMP client connected successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to connect to RTMP server", e)
                nativeHandle = 0
                isConnected = false
                throw RTMPClientException("Failed to connect to RTMP server: ${e.message}", e)
            }
        }
    }

    /**
     * Disconnect from RTMP server and release resources
     */
    fun disconnect() {
        synchronized(lock) {
            if (!isConnected) {
                Log.w(TAG, "RTMP client is not connected")
                return
            }

            try {
                Log.i(TAG, "Disconnecting from RTMP server")
                
                // Cancel any pending reconnection
                reconnectionJob?.cancel()
                reconnectionJob = null
                
                if (nativeHandle != 0L) {
                    nativeDisconnect(nativeHandle)
                    nativeHandle = 0
                }

                isConnected = false
                
                Log.i(TAG, "RTMP client disconnected successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error disconnecting from RTMP server", e)
                nativeHandle = 0
                isConnected = false
            }
        }
    }

    /**
     * Send a video frame to RTMP server
     * 
     * @param data The encoded H.264 video frame data
     * @param timestamp The presentation timestamp in milliseconds
     * @param isKeyframe True if this is a keyframe (I-frame)
     * @throws RTMPClientException if the client is not connected or sending fails
     */
    fun sendVideoFrame(data: ByteArray, timestamp: Int, isKeyframe: Boolean) {
        synchronized(lock) {
            if (!isConnected || nativeHandle == 0L) {
                throw RTMPClientException("Cannot send video frame: RTMP client is not connected")
            }

            if (data.isEmpty()) {
                Log.w(TAG, "Ignoring empty video frame")
                return
            }

            try {
                // Packetize as FLV
                val flvPacket = packetizeVideoAsFLV(data, isKeyframe)
                
                val success = nativeSendVideo(nativeHandle, flvPacket, timestamp, isKeyframe)
                
                if (!success) {
                    throw RTMPClientException("Failed to send video frame")
                }
                
                videoFrameCount++
                bytesSent += flvPacket.size
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send video frame", e)
                throw RTMPClientException("Failed to send video frame: ${e.message}", e)
            }
        }
    }

    /**
     * Send a video frame to RTMP server from ByteBuffer
     * 
     * @param buffer The ByteBuffer containing encoded H.264 video frame data
     * @param timestamp The presentation timestamp in milliseconds
     * @param isKeyframe True if this is a keyframe (I-frame)
     */
    fun sendVideoFrame(buffer: ByteBuffer, timestamp: Int, isKeyframe: Boolean) {
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        buffer.rewind()
        sendVideoFrame(data, timestamp, isKeyframe)
    }

    /**
     * Send an audio frame to RTMP server
     * 
     * @param data The encoded AAC audio frame data
     * @param timestamp The presentation timestamp in milliseconds
     * @throws RTMPClientException if the client is not connected or sending fails
     */
    fun sendAudioFrame(data: ByteArray, timestamp: Int) {
        synchronized(lock) {
            if (!isConnected || nativeHandle == 0L) {
                throw RTMPClientException("Cannot send audio frame: RTMP client is not connected")
            }

            if (data.isEmpty()) {
                Log.w(TAG, "Ignoring empty audio frame")
                return
            }

            try {
                // Packetize as FLV
                val flvPacket = packetizeAudioAsFLV(data)
                
                val success = nativeSendAudio(nativeHandle, flvPacket, timestamp)
                
                if (!success) {
                    throw RTMPClientException("Failed to send audio frame")
                }
                
                audioFrameCount++
                bytesSent += flvPacket.size
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send audio frame", e)
                throw RTMPClientException("Failed to send audio frame: ${e.message}", e)
            }
        }
    }

    /**
     * Send an audio frame to RTMP server from ByteBuffer
     * 
     * @param buffer The ByteBuffer containing encoded AAC audio frame data
     * @param timestamp The presentation timestamp in milliseconds
     */
    fun sendAudioFrame(buffer: ByteBuffer, timestamp: Int) {
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        buffer.rewind()
        sendAudioFrame(data, timestamp)
    }

    /**
     * Attempt reconnection with exponential backoff
     * 
     * @return Job that can be used to cancel the reconnection attempt
     */
    fun reconnectAsync(): Job {
        return coroutineScope.launch {
            try {
                reconnect()
            } catch (e: Exception) {
                Log.e(TAG, "Reconnection failed", e)
            }
        }
    }

    /**
     * Attempt reconnection with exponential backoff (blocking)
     * 
     * @throws RTMPClientException if reconnection fails
     */
    suspend fun reconnect() {
        synchronized(lock) {
            if (isConnected) {
                throw RTMPClientException("RTMP client is already connected")
            }

            if (nativeHandle == 0L) {
                throw RTMPClientException("Invalid client handle, cannot reconnect")
            }
        }

        val currentAttempt = getReconnectionAttempts()
        
        if (currentAttempt >= MAX_RECONNECTION_ATTEMPTS) {
            throw RTMPClientException("Maximum reconnection attempts ($MAX_RECONNECTION_ATTEMPTS) reached")
        }

        // Calculate exponential backoff delay
        val delay = calculateBackoffDelay(currentAttempt)
        
        Log.i(TAG, "Reconnection attempt ${currentAttempt + 1}/$MAX_RECONNECTION_ATTEMPTS after ${delay}s")
        
        // Wait for backoff period
        delay(delay.toLong() * 1000)
        
        synchronized(lock) {
            val success = nativeReconnect(nativeHandle)
            
            if (success) {
                isConnected = true
                Log.i(TAG, "Reconnection successful")
            } else {
                Log.e(TAG, "Reconnection failed")
                throw RTMPClientException("Reconnection failed")
            }
        }
    }

    /**
     * Check if the RTMP client is currently connected
     * 
     * @return true if connected, false otherwise
     */
    fun isConnected(): Boolean {
        synchronized(lock) {
            return isConnected
        }
    }

    /**
     * Get the current reconnection attempt count
     * 
     * @return the number of reconnection attempts made
     */
    fun getReconnectionAttempts(): Int {
        synchronized(lock) {
            if (nativeHandle == 0L) {
                return 0
            }
            return nativeGetReconnectionAttempts(nativeHandle)
        }
    }

    /**
     * Get streaming statistics
     * 
     * @return Map containing statistics
     */
    fun getStatistics(): Map<String, Any> {
        synchronized(lock) {
            return mapOf(
                "videoFrameCount" to videoFrameCount,
                "audioFrameCount" to audioFrameCount,
                "bytesSent" to bytesSent,
                "isConnected" to isConnected,
                "reconnectionAttempts" to getReconnectionAttempts()
            )
        }
    }

    /**
     * Clean up resources
     */
    fun cleanup() {
        disconnect()
        coroutineScope.cancel()
    }

    // MARK: - Private Methods

    private fun isValidRTMPURL(url: String): Boolean {
        // RTMP URL format: rtmp://[host]/[app]
        // Examples:
        // - rtmp://a.rtmp.youtube.com/live2
        // - rtmp://live.twitch.tv/app
        
        if (!url.startsWith("rtmp://") && !url.startsWith("rtmps://")) {
            return false
        }
        
        // Remove protocol
        val withoutProtocol = url.removePrefix("rtmp://").removePrefix("rtmps://")
        
        // Should have at least host/app format
        val components = withoutProtocol.split("/")
        if (components.size < 2) {
            return false
        }
        
        // Host should not be empty
        if (components[0].isEmpty()) {
            return false
        }
        
        // App should not be empty
        if (components[1].isEmpty()) {
            return false
        }
        
        return true
    }

    private fun calculateBackoffDelay(attempt: Int): Double {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        val baseDelay = 1.0
        val maxDelay = 16.0
        val delay = baseDelay * Math.pow(2.0, attempt.toDouble())
        return minOf(delay, maxDelay)
    }

    private fun packetizeVideoAsFLV(data: ByteArray, isKeyframe: Boolean): ByteArray {
        // FLV video tag format:
        // - Frame type (4 bits): 1 = keyframe, 2 = inter frame
        // - Codec ID (4 bits): 7 = AVC (H.264)
        // - AVC packet type (1 byte): 0 = sequence header, 1 = NALU
        // - Composition time (3 bytes): 0 for now
        // - Data
        
        val flvPacket = ByteArray(5 + data.size)
        var offset = 0
        
        // Frame type and codec ID
        val frameType: Byte = if (isKeyframe) 0x10 else 0x20 // 1 = keyframe, 2 = inter
        val codecID: Byte = 0x07 // AVC
        flvPacket[offset++] = (frameType.toInt() or codecID.toInt()).toByte()
        
        // AVC packet type (1 = NALU)
        flvPacket[offset++] = 0x01
        
        // Composition time (3 bytes, big-endian)
        flvPacket[offset++] = 0x00
        flvPacket[offset++] = 0x00
        flvPacket[offset++] = 0x00
        
        // Append H.264 data
        System.arraycopy(data, 0, flvPacket, offset, data.size)
        
        return flvPacket
    }

    private fun packetizeAudioAsFLV(data: ByteArray): ByteArray {
        // FLV audio tag format:
        // - Sound format (4 bits): 10 = AAC
        // - Sound rate (2 bits): 3 = 44 kHz
        // - Sound size (1 bit): 1 = 16-bit
        // - Sound type (1 bit): 1 = stereo
        // - AAC packet type (1 byte): 0 = sequence header, 1 = raw
        // - Data
        
        val flvPacket = ByteArray(2 + data.size)
        var offset = 0
        
        // Sound format, rate, size, type
        val soundFormat: Byte = 0xA0.toByte() // AAC (10 << 4)
        val soundRate: Byte = 0x0C // 44 kHz (3 << 2)
        val soundSize: Byte = 0x02 // 16-bit (1 << 1)
        val soundType: Byte = 0x01 // Stereo
        flvPacket[offset++] = (soundFormat.toInt() or soundRate.toInt() or soundSize.toInt() or soundType.toInt()).toByte()
        
        // AAC packet type (1 = raw AAC frame)
        flvPacket[offset++] = 0x01
        
        // Append AAC data
        System.arraycopy(data, 0, flvPacket, offset, data.size)
        
        return flvPacket
    }

    /**
     * Exception class for RTMP client errors
     */
    class RTMPClientException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
