package com.samsung.android.scan3d.streaming

import android.media.Image
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.util.Log
import java.nio.ByteBuffer

/**
 * Hardware H.264 video encoder using MediaCodec
 * for the IP Camera Streaming Platform.
 */
class VideoEncoder {
    companion object {
        private const val TAG = "VideoEncoder"
        private const val MIME_TYPE = "video/avc" // H.264
        private const val IFRAME_INTERVAL = 2 // seconds
        private const val TIMEOUT_USEC = 10000L
    }

    private var codec: MediaCodec? = null
    private var width: Int = 0
    private var height: Int = 0
    private var frameRate: Int = 30
    private var bitrate: Int = 5_000_000
    private var isConfigured = false

    /**
     * Callback for encoded frames
     * Parameters: (data: ByteBuffer, bufferInfo: MediaCodec.BufferInfo)
     */
    var onEncodedFrame: ((ByteBuffer, MediaCodec.BufferInfo) -> Unit)? = null

    /**
     * Configure the encoder with video parameters
     */
    fun configure(width: Int, height: Int, frameRate: Int, bitrate: Int) {
        if (isConfigured) {
            Log.w(TAG, "Encoder already configured, shutting down first")
            shutdown()
        }

        this.width = width
        this.height = height
        this.frameRate = frameRate
        this.bitrate = bitrate

        try {
            // Create media format
            val format = MediaFormat.createVideoFormat(MIME_TYPE, width, height).apply {
                setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible)
                setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
                setInteger(MediaFormat.KEY_FRAME_RATE, frameRate)
                setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, IFRAME_INTERVAL)
                
                // Set encoding profile
                setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileMain)
                
                // Enable low latency mode
                setInteger(MediaFormat.KEY_LATENCY, 0)
            }

            // Create and configure codec
            codec = MediaCodec.createEncoderByType(MIME_TYPE).apply {
                configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                start()
            }

            isConfigured = true
            Log.i(TAG, "VideoEncoder configured: ${width}x${height} @ ${frameRate}fps, ${bitrate}bps")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure encoder", e)
            shutdown()
            throw VideoEncoderException("Failed to configure encoder: ${e.message}", e)
        }
    }

    /**
     * Encode a video frame from Image
     */
    fun encode(image: Image) {
        if (!isConfigured || codec == null) {
            throw VideoEncoderException("Encoder not configured")
        }

        try {
            val currentCodec = codec ?: throw VideoEncoderException("Codec is null")

            // Get input buffer
            val inputBufferIndex = currentCodec.dequeueInputBuffer(TIMEOUT_USEC)
            if (inputBufferIndex >= 0) {
                val inputBuffer = currentCodec.getInputBuffer(inputBufferIndex)
                    ?: throw VideoEncoderException("Failed to get input buffer")

                // Convert Image to YUV420 and copy to input buffer
                inputBuffer.clear()
                imageToYUV420(image, inputBuffer)

                // Queue input buffer
                val presentationTimeUs = System.nanoTime() / 1000
                currentCodec.queueInputBuffer(
                    inputBufferIndex,
                    0,
                    inputBuffer.position(),
                    presentationTimeUs,
                    0
                )
            }

            // Retrieve encoded output
            drainEncoder(false)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encode frame", e)
            throw VideoEncoderException("Failed to encode frame: ${e.message}", e)
        }
    }

    /**
     * Shutdown the encoder and release resources
     */
    fun shutdown() {
        try {
            if (isConfigured) {
                drainEncoder(true)
            }

            codec?.let {
                try {
                    it.stop()
                } catch (e: Exception) {
                    Log.w(TAG, "Error stopping codec", e)
                }
                try {
                    it.release()
                } catch (e: Exception) {
                    Log.w(TAG, "Error releasing codec", e)
                }
            }
            codec = null
            isConfigured = false
            Log.i(TAG, "VideoEncoder shutdown")
        } catch (e: Exception) {
            Log.e(TAG, "Error during shutdown", e)
        }
    }

    /**
     * Drain encoded frames from the encoder
     */
    private fun drainEncoder(endOfStream: Boolean) {
        val currentCodec = codec ?: return

        if (endOfStream) {
            try {
                val inputBufferIndex = currentCodec.dequeueInputBuffer(TIMEOUT_USEC)
                if (inputBufferIndex >= 0) {
                    currentCodec.queueInputBuffer(
                        inputBufferIndex,
                        0,
                        0,
                        0,
                        MediaCodec.BUFFER_FLAG_END_OF_STREAM
                    )
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error signaling end of stream", e)
            }
        }

        val bufferInfo = MediaCodec.BufferInfo()
        while (true) {
            val outputBufferIndex = currentCodec.dequeueOutputBuffer(bufferInfo, TIMEOUT_USEC)

            when {
                outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) {
                        break
                    }
                }
                outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    val newFormat = currentCodec.outputFormat
                    Log.d(TAG, "Output format changed: $newFormat")
                }
                outputBufferIndex < 0 -> {
                    Log.w(TAG, "Unexpected output buffer index: $outputBufferIndex")
                }
                else -> {
                    val outputBuffer = currentCodec.getOutputBuffer(outputBufferIndex)
                    if (outputBuffer != null) {
                        // Check for valid data
                        if (bufferInfo.size > 0) {
                            // Adjust buffer position and limit
                            outputBuffer.position(bufferInfo.offset)
                            outputBuffer.limit(bufferInfo.offset + bufferInfo.size)

                            // Create a copy of the buffer for the callback
                            val data = ByteBuffer.allocate(bufferInfo.size)
                            data.put(outputBuffer)
                            data.flip()

                            // Call the callback with encoded data
                            onEncodedFrame?.invoke(data, bufferInfo)
                        }

                        currentCodec.releaseOutputBuffer(outputBufferIndex, false)
                    }

                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        break
                    }
                }
            }
        }
    }

    /**
     * Convert Image (YUV_420_888) to YUV420 planar format
     */
    private fun imageToYUV420(image: Image, buffer: ByteBuffer) {
        val planes = image.planes
        
        // Y plane
        val yPlane = planes[0]
        val yBuffer = yPlane.buffer
        val ySize = yBuffer.remaining()
        val yRowStride = yPlane.rowStride
        val yPixelStride = yPlane.pixelStride

        // U plane
        val uPlane = planes[1]
        val uBuffer = uPlane.buffer
        val uRowStride = uPlane.rowStride
        val uPixelStride = uPlane.pixelStride

        // V plane
        val vPlane = planes[2]
        val vBuffer = vPlane.buffer
        val vRowStride = vPlane.rowStride
        val vPixelStride = vPlane.pixelStride

        // Copy Y plane
        if (yPixelStride == 1 && yRowStride == width) {
            // Contiguous Y plane, direct copy
            buffer.put(yBuffer)
        } else {
            // Non-contiguous, copy row by row
            val rowData = ByteArray(width)
            for (row in 0 until height) {
                yBuffer.position(row * yRowStride)
                if (yPixelStride == 1) {
                    yBuffer.get(rowData, 0, width)
                    buffer.put(rowData)
                } else {
                    // Handle pixel stride
                    for (col in 0 until width) {
                        rowData[col] = yBuffer.get(row * yRowStride + col * yPixelStride)
                    }
                    buffer.put(rowData)
                }
            }
        }

        // Copy U and V planes (interleaved or planar)
        val chromaHeight = height / 2
        val chromaWidth = width / 2

        // Copy U plane
        val uRowData = ByteArray(chromaWidth)
        for (row in 0 until chromaHeight) {
            uBuffer.position(row * uRowStride)
            for (col in 0 until chromaWidth) {
                uRowData[col] = uBuffer.get(row * uRowStride + col * uPixelStride)
            }
            buffer.put(uRowData)
        }

        // Copy V plane
        val vRowData = ByteArray(chromaWidth)
        for (row in 0 until chromaHeight) {
            vBuffer.position(row * vRowStride)
            for (col in 0 until chromaWidth) {
                vRowData[col] = vBuffer.get(row * vRowStride + col * vPixelStride)
            }
            buffer.put(vRowData)
        }
    }

    /**
     * Exception class for VideoEncoder errors
     */
    class VideoEncoderException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
