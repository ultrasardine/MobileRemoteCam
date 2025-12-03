package com.samsung.android.scan3d.streaming

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.ImageFormat
import android.hardware.camera2.*
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.Image
import android.media.MediaRecorder
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import android.view.Surface
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * CameraCapture handles camera and audio capture using Camera2 API and AudioRecord
 * for the IP Camera Streaming Platform.
 */
class CameraCapture(private val context: Context) {
    companion object {
        private const val TAG = "CameraCapture"
        private const val AUDIO_SAMPLE_RATE = 44100
        private const val AUDIO_CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    }

    private val cameraManager: CameraManager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: android.media.ImageReader? = null
    private var audioRecord: AudioRecord? = null

    private val cameraThread = HandlerThread("CameraThread").apply { start() }
    private val cameraHandler = Handler(cameraThread.looper)

    private val audioThread = HandlerThread("AudioThread").apply { start() }
    private val audioHandler = Handler(audioThread.looper)

    private var isCapturing = false
    private var isAudioCapturing = false

    /**
     * Callback for video frames
     */
    var onVideoFrame: ((Image) -> Unit)? = null

    /**
     * Callback for audio samples
     */
    var onAudioSample: ((ByteArray) -> Unit)? = null

    /**
     * Enumerate all available cameras on the device
     */
    fun enumerateCameras(): List<CameraInfo> {
        val cameras = mutableListOf<CameraInfo>()

        try {
            val cameraIds = cameraManager.cameraIdList

            for (id in cameraIds) {
                try {
                    val characteristics = cameraManager.getCameraCharacteristics(id)

                    // Check if camera supports backward compatibility
                    val capabilities = characteristics.get(
                        CameraCharacteristics.REQUEST_AVAILABLE_CAPABILITIES
                    ) ?: continue

                    if (!capabilities.contains(
                            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_BACKWARD_COMPATIBLE
                        )
                    ) {
                        continue
                    }

                    // Skip logical multi-camera devices
                    if (capabilities.contains(
                            CameraMetadata.REQUEST_AVAILABLE_CAPABILITIES_LOGICAL_MULTI_CAMERA
                        )
                    ) {
                        continue
                    }

                    val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
                    val position = when (facing) {
                        CameraCharacteristics.LENS_FACING_FRONT -> "front"
                        CameraCharacteristics.LENS_FACING_BACK -> "back"
                        CameraCharacteristics.LENS_FACING_EXTERNAL -> "external"
                        else -> "back"
                    }

                    val name = buildCameraName(characteristics, position)
                    val cameraCapabilities = buildCapabilities(characteristics)

                    cameras.add(
                        CameraInfo(
                            id = id,
                            name = name,
                            position = position,
                            capabilities = cameraCapabilities
                        )
                    )
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to enumerate camera $id", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to enumerate cameras", e)
        }

        return cameras
    }

    /**
     * Get available resolutions for a specific camera
     */
    fun getResolutions(cameraId: String): List<Resolution> {
        return try {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val map = characteristics.get(
                CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP
            ) ?: return emptyList()

            val sizes = map.getOutputSizes(ImageFormat.YUV_420_888) ?: return emptyList()

            sizes.map { size ->
                Resolution(width = size.width, height = size.height)
            }.sortedByDescending { it.width * it.height }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get resolutions for camera $cameraId", e)
            emptyList()
        }
    }

    /**
     * Start camera capture with the specified configuration
     */
    @SuppressLint("MissingPermission")
    suspend fun start(
        cameraId: String,
        resolution: Size,
        frameRate: Int,
        audioEnabled: Boolean = false
    ) {
        if (isCapturing) {
            Log.w(TAG, "Camera is already capturing")
            return
        }

        try {
            // Open camera
            cameraDevice = openCamera(cameraId)

            // Create image reader for video frames
            imageReader = android.media.ImageReader.newInstance(
                resolution.width,
                resolution.height,
                ImageFormat.YUV_420_888,
                4
            ).apply {
                setOnImageAvailableListener({ reader ->
                    val image = reader.acquireLatestImage()
                    if (image != null) {
                        onVideoFrame?.invoke(image)
                        image.close()
                    }
                }, cameraHandler)
            }

            // Create capture session
            val surfaces = listOf(imageReader!!.surface)
            captureSession = createCaptureSession(cameraDevice!!, surfaces)

            // Start repeating request
            val captureRequest = cameraDevice!!.createCaptureRequest(
                CameraDevice.TEMPLATE_RECORD
            ).apply {
                addTarget(imageReader!!.surface)
                set(CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, android.util.Range(frameRate, frameRate))
            }

            captureSession!!.setRepeatingRequest(
                captureRequest.build(),
                null,
                cameraHandler
            )

            isCapturing = true
            Log.i(TAG, "Camera capture started: $cameraId at ${resolution.width}x${resolution.height} @ ${frameRate}fps")

            // Start audio capture if enabled
            if (audioEnabled) {
                startAudioCapture()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start camera capture", e)
            stop()
            throw e
        }
    }

    /**
     * Stop camera and audio capture
     */
    fun stop() {
        isCapturing = false

        try {
            captureSession?.stopRepeating()
            captureSession?.close()
            captureSession = null
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping capture session", e)
        }

        try {
            cameraDevice?.close()
            cameraDevice = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing camera device", e)
        }

        try {
            imageReader?.close()
            imageReader = null
        } catch (e: Exception) {
            Log.w(TAG, "Error closing image reader", e)
        }

        stopAudioCapture()

        Log.i(TAG, "Camera capture stopped")
    }

    /**
     * Clean up resources
     */
    fun destroy() {
        stop()
        cameraThread.quitSafely()
        audioThread.quitSafely()
    }

    /**
     * Start audio capture using AudioRecord
     */
    @SuppressLint("MissingPermission")
    private fun startAudioCapture() {
        if (isAudioCapturing) {
            return
        }

        try {
            val minBufferSize = AudioRecord.getMinBufferSize(
                AUDIO_SAMPLE_RATE,
                AUDIO_CHANNEL_CONFIG,
                AUDIO_FORMAT
            )

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                AUDIO_SAMPLE_RATE,
                AUDIO_CHANNEL_CONFIG,
                AUDIO_FORMAT,
                minBufferSize * 2
            )

            audioRecord?.startRecording()
            isAudioCapturing = true

            // Start audio capture thread
            audioHandler.post {
                val buffer = ByteArray(minBufferSize)
                while (isAudioCapturing) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        onAudioSample?.invoke(buffer.copyOf(read))
                    }
                }
            }

            Log.i(TAG, "Audio capture started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start audio capture", e)
            isAudioCapturing = false
        }
    }

    /**
     * Stop audio capture
     */
    private fun stopAudioCapture() {
        isAudioCapturing = false

        try {
            audioRecord?.stop()
            audioRecord?.release()
            audioRecord = null
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping audio capture", e)
        }

        Log.i(TAG, "Audio capture stopped")
    }

    /**
     * Open camera device
     */
    @SuppressLint("MissingPermission")
    private suspend fun openCamera(cameraId: String): CameraDevice =
        suspendCancellableCoroutine { cont ->
            cameraManager.openCamera(cameraId, object : CameraDevice.StateCallback() {
                override fun onOpened(device: CameraDevice) {
                    cont.resume(device)
                }

                override fun onDisconnected(device: CameraDevice) {
                    Log.w(TAG, "Camera $cameraId disconnected")
                    device.close()
                }

                override fun onError(device: CameraDevice, error: Int) {
                    val msg = when (error) {
                        ERROR_CAMERA_DEVICE -> "Fatal (device)"
                        ERROR_CAMERA_DISABLED -> "Device policy"
                        ERROR_CAMERA_IN_USE -> "Camera in use"
                        ERROR_CAMERA_SERVICE -> "Fatal (service)"
                        ERROR_MAX_CAMERAS_IN_USE -> "Maximum cameras in use"
                        else -> "Unknown"
                    }
                    val exc = RuntimeException("Camera $cameraId error: ($error) $msg")
                    Log.e(TAG, exc.message, exc)
                    if (cont.isActive) {
                        cont.resumeWithException(exc)
                    }
                }
            }, cameraHandler)
        }

    /**
     * Create capture session
     */
    private suspend fun createCaptureSession(
        device: CameraDevice,
        targets: List<Surface>
    ): CameraCaptureSession = suspendCancellableCoroutine { cont ->
        device.createCaptureSession(targets, object : CameraCaptureSession.StateCallback() {
            override fun onConfigured(session: CameraCaptureSession) {
                cont.resume(session)
            }

            override fun onConfigureFailed(session: CameraCaptureSession) {
                val exc = RuntimeException("Camera ${device.id} session configuration failed")
                Log.e(TAG, exc.message, exc)
                cont.resumeWithException(exc)
            }
        }, cameraHandler)
    }

    /**
     * Build camera name from characteristics
     */
    private fun buildCameraName(characteristics: CameraCharacteristics, position: String): String {
        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        val apertures = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_APERTURES)

        val focalLength = focalLengths?.firstOrNull()?.let { "%.1fmm".format(it) } ?: ""
        val aperture = apertures?.firstOrNull()?.let { "f/%.1f".format(it) } ?: ""

        val positionName = position.replaceFirstChar { it.uppercase() }

        return if (focalLength.isNotEmpty() && aperture.isNotEmpty()) {
            "$positionName Camera ($focalLength $aperture)"
        } else {
            "$positionName Camera"
        }
    }

    /**
     * Build capabilities list from characteristics
     */
    private fun buildCapabilities(characteristics: CameraCharacteristics): List<String> {
        val capabilities = mutableListOf<String>()

        val focalLengths = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
        if (focalLengths != null && focalLengths.isNotEmpty()) {
            val focalLength = focalLengths[0]
            when {
                focalLength < 3.0f -> capabilities.add("ultra-wide")
                focalLength < 5.0f -> capabilities.add("wide-angle")
                focalLength > 6.0f -> capabilities.add("telephoto")
            }
        }

        return capabilities
    }

    /**
     * Data class for camera information
     */
    data class CameraInfo(
        val id: String,
        val name: String,
        val position: String,
        val capabilities: List<String>
    )

    /**
     * Data class for resolution
     */
    data class Resolution(
        val width: Int,
        val height: Int
    )
}
