package com.samsung.android.scan3d.streaming

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.util.Log
import java.nio.ByteBuffer

/**
 * Hardware AAC audio encoder using MediaCodec
 * for the IP Camera Streaming Platform.
 */
class AudioEncoder {
    companion object {
        private const val TAG = "AudioEncoder"
        private const val MIME_TYPE = "audio/mp4a-latm" // AAC
        private const val SAMPLE_RATE = 44100
        private const val CHANNEL_COUNT = 1 // Mono
        private const val BIT_RATE = 64000 // 64 kbps
        private const val TIMEOUT_USEC = 10000L
    }

    private var codec: MediaCodec? = null
    private var sampleRate: Int = SAMPLE_RATE
    private var channelCount: Int = CHANNEL_COUNT
    private var bitRate: Int = BIT_RATE
    private var isConfigured = false
    private var presentationTimeUs: Long = 0

    /**
     * Callback for encoded frames
     * Parameters: (data: ByteBuffer, bufferInfo: MediaCodec.BufferInfo)
     */
    var onEncodedFrame: ((ByteBuffer, MediaCodec.BufferInfo) -> Unit)? = null

    /**
     * Configure the encoder with default parameters
     */
    fun configure() {
        configure(SAMPLE_RATE, CHANNEL_COUNT, BIT_RATE)
    }

    /**
     * Configure the encoder with audio parameters
     */
    fun configure(sampleRate: Int, channelCount: Int, bitRate: Int) {
        if (isConfigured) {
            Log.w(TAG, "Encoder already configured, shutting down first")
            shutdown()
        }

        this.sampleRate = sampleRate
        this.channelCount = channelCount
        this.bitRate = bitRate
        this.presentationTimeUs = 0

        try {
            // Create media format
            val format = MediaFormat.createAudioFormat(MIME_TYPE, sampleRate, channelCount).apply {
                setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC)
                setInteger(MediaFormat.KEY_BIT_RATE, bitRate)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384)
            }

            // Create and configure codec
            codec = MediaCodec.createEncoderByType(MIME_TYPE).apply {
                configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                start()
            }

            isConfigured = true
            Log.i(TAG, "AudioEncoder configured: ${sampleRate}Hz, ${channelCount}ch, ${bitRate}bps")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to configure encoder", e)
            shutdown()
            throw AudioEncoderException("Failed to configure encoder: ${e.message}", e)
        }
    }

    /**
     * Encode audio samples (PCM 16-bit)
     */
    fun encode(audioData: ByteArray) {
        if (!isConfigured || codec == null) {
            throw AudioEncoderException("Encoder not configured")
        }

        try {
            val currentCodec = codec ?: throw AudioEncoderException("Codec is null")

            // Get input buffer
            val inputBufferIndex = currentCodec.dequeueInputBuffer(TIMEOUT_USEC)
            if (inputBufferIndex >= 0) {
                val inputBuffer = currentCodec.getInputBuffer(inputBufferIndex)
                    ?: throw AudioEncoderException("Failed to get input buffer")

                // Copy audio data to input buffer
                inputBuffer.clear()
                inputBuffer.put(audioData)

                // Calculate presentation time
                val sampleCount = audioData.size / (2 * channelCount) // 16-bit = 2 bytes per sample
                val durationUs = (sampleCount * 1_000_000L) / sampleRate

                // Queue input buffer
                currentCodec.queueInputBuffer(
                    inputBufferIndex,
                    0,
                    audioData.size,
                    presentationTimeUs,
                    0
                )

                presentationTimeUs += durationUs
            }

            // Retrieve encoded output
            drainEncoder(false)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to encode audio", e)
            throw AudioEncoderException("Failed to encode audio: ${e.message}", e)
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
            presentationTimeUs = 0
            Log.i(TAG, "AudioEncoder shutdown")
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
     * Exception class for AudioEncoder errors
     */
    class AudioEncoderException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
