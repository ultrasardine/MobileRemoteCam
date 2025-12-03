import AVFoundation
import UIKit

/// Handles camera and audio capture using AVFoundation
class CameraCapture: NSObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var currentCamera: AVCaptureDevice?
    
    private let videoQueue = DispatchQueue(label: "com.ipcamera.videoQueue")
    private let audioQueue = DispatchQueue(label: "com.ipcamera.audioQueue")
    
    var onVideoFrame: ((CMSampleBuffer) -> Void)?
    var onAudioSample: ((CMSampleBuffer) -> Void)?
    
    /// Enumerate all available cameras on the device
    func enumerateCameras() -> [[String: Any]] {
        var cameras: [[String: Any]] = []
        
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInUltraWideCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in discoverySession.devices {
            var cameraInfo: [String: Any] = [:]
            cameraInfo["id"] = device.uniqueID
            cameraInfo["name"] = device.localizedName
            
            // Determine position
            switch device.position {
            case .front:
                cameraInfo["position"] = "front"
            case .back:
                cameraInfo["position"] = "back"
            case .unspecified:
                cameraInfo["position"] = "external"
            @unknown default:
                cameraInfo["position"] = "external"
            }
            
            // Determine capabilities
            var capabilities: [String] = []
            if device.deviceType == .builtInTelephotoCamera {
                capabilities.append("telephoto")
            }
            if device.deviceType == .builtInUltraWideCamera {
                capabilities.append("ultra-wide")
            }
            if device.deviceType == .builtInWideAngleCamera {
                capabilities.append("wide-angle")
            }
            cameraInfo["capabilities"] = capabilities
            
            cameras.append(cameraInfo)
        }
        
        return cameras
    }
    
    /// Get available resolutions for a specific camera
    func getResolutions(cameraId: String) -> [[String: Any]] {
        guard let device = AVCaptureDevice(uniqueID: cameraId) else {
            return []
        }
        
        var resolutions: [[String: Any]] = []
        let formats = device.formats
        
        for format in formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let width = Int(dimensions.width)
            let height = Int(dimensions.height)
            
            // Filter for common resolutions
            if (width == 1280 && height == 720) ||
               (width == 1920 && height == 1080) ||
               (width == 3840 && height == 2160) {
                let resolution: [String: Any] = [
                    "width": width,
                    "height": height
                ]
                // Avoid duplicates
                if !resolutions.contains(where: { ($0["width"] as? Int) == width && ($0["height"] as? Int) == height }) {
                    resolutions.append(resolution)
                }
            }
        }
        
        return resolutions
    }
    
    /// Start camera capture with specified configuration
    func start(cameraId: String, width: Int, height: Int, frameRate: Int, audioEnabled: Bool) throws {
        // Stop any existing session
        stop()
        
        // Get the camera device
        guard let device = AVCaptureDevice(uniqueID: cameraId) else {
            throw CameraCaptureError.cameraNotFound
        }
        
        // Create capture session
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Add video input
        let videoInput = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(videoInput) else {
            throw CameraCaptureError.cannotAddVideoInput
        }
        session.addInput(videoInput)
        
        // Configure video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        
        guard session.canAddOutput(videoOutput) else {
            throw CameraCaptureError.cannotAddVideoOutput
        }
        session.addOutput(videoOutput)
        
        // Set resolution
        if let format = findFormat(for: device, width: width, height: height) {
            try device.lockForConfiguration()
            device.activeFormat = format
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
            device.unlockForConfiguration()
        }
        
        // Add audio input if enabled
        if audioEnabled {
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    
                    let audioOutput = AVCaptureAudioDataOutput()
                    audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
                    
                    if session.canAddOutput(audioOutput) {
                        session.addOutput(audioOutput)
                        self.audioOutput = audioOutput
                    }
                }
            }
        }
        
        session.commitConfiguration()
        
        self.captureSession = session
        self.videoOutput = videoOutput
        self.currentCamera = device
        
        // Start the session
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    /// Stop camera capture
    func stop() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        audioOutput = nil
        currentCamera = nil
    }
    
    // MARK: - Private Helpers
    
    private func findFormat(for device: AVCaptureDevice, width: Int, height: Int) -> AVCaptureDevice.Format? {
        for format in device.formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if Int(dimensions.width) == width && Int(dimensions.height) == height {
                return format
            }
        }
        return nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraCapture: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            onVideoFrame?(sampleBuffer)
        } else if output == audioOutput {
            onAudioSample?(sampleBuffer)
        }
    }
}

// MARK: - Error Types

enum CameraCaptureError: Error {
    case cameraNotFound
    case cannotAddVideoInput
    case cannotAddVideoOutput
    case cannotAddAudioInput
    case cannotAddAudioOutput
    case configurationFailed
}
