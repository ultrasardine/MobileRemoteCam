package com.samsung.android.scan3d.streaming

import android.util.Log
import java.nio.ByteBuffer

/**
 * RTSP Server implementation using Live555 library via JNI
 * for the IP Camera Streaming Platform.
 * 
 * This class provides RTSP streaming capabilities for local network clients
 * like OBS and VLC to connect and receive H.264 video and AAC audio streams.
 */
class RTSPServer {
    companion object {
        private const val TAG = "RTSPServer"
        private const val DEFAULT_PORT = 8554
        
        init {
            try {
                System.loadLibrary("rtsp_server_jni")
                Log.i(TAG, "Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "Failed to load native library", e)
                throw RTSPServerException("Failed to load native library: ${e.message}", e)
            }
        }
    }

    // Native method declarations
    private external fun nativeStart(port: Int): Long
    private external fun nativeStop(handle: Long)
    private external fun nativeFeedVideo(handle: Long, data: ByteArray, timestamp: Long, isKeyframe: Boolean)
    private external fun nativeFeedAudio(handle: Long, data: ByteArray, timestamp: Long)

    private var nativeHandle: Long = 0
    private var port: Int = DEFAULT_PORT
    private var isRunning: Boolean = false
    private val lock = Any()

    /**
     * Start the RTSP server on the specified port
     * 
     * @param port The port number to bind to (default: 8554)
     * @throws RTSPServerException if the server fails to start
     */
    fun start(port: Int = DEFAULT_PORT) {
        synchronized(lock) {
            if (isRunning) {
                Log.w(TAG, "RTSP server is already running on port $this.port")
                return
            }

            if (port < 1024 || port > 65535) {
                throw RTSPServerException("Invalid port number: $port. Must be between 1024 and 65535")
            }

            try {
                Log.i(TAG, "Starting RTSP server on port $port")
                
                nativeHandle = nativeStart(port)
                
                if (nativeHandle == 0L) {
                    throw RTSPServerException("Failed to start RTSP server: native initialization failed")
                }

                this.port = port
                isRunning = true
                
                Log.i(TAG, "RTSP server started successfully on port $port")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start RTSP server", e)
                nativeHandle = 0
                isRunning = false
                throw RTSPServerException("Failed to start RTSP server: ${e.message}", e)
            }
        }
    }

    /**
     * Stop the RTSP server and release resources
     */
    fun stop() {
        synchronized(lock) {
            if (!isRunning) {
                Log.w(TAG, "RTSP server is not running")
                return
            }

            try {
                Log.i(TAG, "Stopping RTSP server on port $port")
                
                if (nativeHandle != 0L) {
                    nativeStop(nativeHandle)
                    nativeHandle = 0
                }

                isRunning = false
                
                Log.i(TAG, "RTSP server stopped successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping RTSP server", e)
                nativeHandle = 0
                isRunning = false
            }
        }
    }

    /**
     * Feed a video frame to the RTSP server
     * 
     * @param data The encoded H.264 video frame data
     * @param timestamp The presentation timestamp in microseconds
     * @param isKeyframe True if this is a keyframe (I-frame)
     * @throws RTSPServerException if the server is not running or feeding fails
     */
    fun feedVideoFrame(data: ByteArray, timestamp: Long, isKeyframe: Boolean) {
        synchronized(lock) {
            if (!isRunning || nativeHandle == 0L) {
                throw RTSPServerException("Cannot feed video frame: RTSP server is not running")
            }

            if (data.isEmpty()) {
                Log.w(TAG, "Ignoring empty video frame")
                return
            }

            try {
                nativeFeedVideo(nativeHandle, data, timestamp, isKeyframe)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to feed video frame", e)
                throw RTSPServerException("Failed to feed video frame: ${e.message}", e)
            }
        }
    }

    /**
     * Feed a video frame to the RTSP server from ByteBuffer
     * 
     * @param buffer The ByteBuffer containing encoded H.264 video frame data
     * @param timestamp The presentation timestamp in microseconds
     * @param isKeyframe True if this is a keyframe (I-frame)
     */
    fun feedVideoFrame(buffer: ByteBuffer, timestamp: Long, isKeyframe: Boolean) {
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        buffer.rewind()
        feedVideoFrame(data, timestamp, isKeyframe)
    }

    /**
     * Feed an audio frame to the RTSP server
     * 
     * @param data The encoded AAC audio frame data
     * @param timestamp The presentation timestamp in microseconds
     * @throws RTSPServerException if the server is not running or feeding fails
     */
    fun feedAudioFrame(data: ByteArray, timestamp: Long) {
        synchronized(lock) {
            if (!isRunning || nativeHandle == 0L) {
                throw RTSPServerException("Cannot feed audio frame: RTSP server is not running")
            }

            if (data.isEmpty()) {
                Log.w(TAG, "Ignoring empty audio frame")
                return
            }

            try {
                nativeFeedAudio(nativeHandle, data, timestamp)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to feed audio frame", e)
                throw RTSPServerException("Failed to feed audio frame: ${e.message}", e)
            }
        }
    }

    /**
     * Feed an audio frame to the RTSP server from ByteBuffer
     * 
     * @param buffer The ByteBuffer containing encoded AAC audio frame data
     * @param timestamp The presentation timestamp in microseconds
     */
    fun feedAudioFrame(buffer: ByteBuffer, timestamp: Long) {
        val data = ByteArray(buffer.remaining())
        buffer.get(data)
        buffer.rewind()
        feedAudioFrame(data, timestamp)
    }

    /**
     * Check if the RTSP server is currently running
     * 
     * @return true if the server is running, false otherwise
     */
    fun isRunning(): Boolean {
        synchronized(lock) {
            return isRunning
        }
    }

    /**
     * Get the port the RTSP server is running on
     * 
     * @return the port number, or 0 if not running
     */
    fun getPort(): Int {
        synchronized(lock) {
            return if (isRunning) port else 0
        }
    }

    /**
     * Get the RTSP stream URL for the given IP address
     * 
     * @param ipAddress The device's IP address
     * @return The RTSP stream URL (e.g., rtsp://192.168.1.50:8554/live)
     */
    fun getStreamUrl(ipAddress: String): String {
        synchronized(lock) {
            if (!isRunning) {
                return ""
            }
            return "rtsp://$ipAddress:$port/live"
        }
    }

    /**
     * Exception class for RTSP server errors
     */
    class RTSPServerException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
