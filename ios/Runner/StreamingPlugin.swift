import Flutter
import UIKit
import AVFoundation

/// Flutter plugin for streaming functionality
class StreamingPlugin: NSObject, FlutterPlugin {
    private let streamingManager = StreamingManager()
    private let networkMonitor = NetworkMonitor()
    private var networkChannel: FlutterMethodChannel?
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let streamingChannel = FlutterMethodChannel(
            name: "com.ipcamera/streaming",
            binaryMessenger: registrar.messenger()
        )
        let networkChannel = FlutterMethodChannel(
            name: "com.ipcamera/network",
            binaryMessenger: registrar.messenger()
        )
        let instance = StreamingPlugin()
        instance.networkChannel = networkChannel
        registrar.addMethodCallDelegate(instance, channel: streamingChannel)
        registrar.addMethodCallDelegate(instance, channel: networkChannel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCameras":
            handleGetCameras(result: result)
            
        case "getResolutions":
            handleGetResolutions(call: call, result: result)
            
        case "startStreaming":
            handleStartStreaming(call: call, result: result)
            
        case "stopStreaming":
            handleStopStreaming(result: result)
            
        case "getStatistics":
            handleGetStatistics(result: result)
            
        case "getStreamURL":
            handleGetStreamURL(call: call, result: result)
            
        case "startNetworkMonitoring":
            handleStartNetworkMonitoring(result: result)
            
        case "stopNetworkMonitoring":
            handleStopNetworkMonitoring(result: result)
            
        case "getCurrentNetwork":
            handleGetCurrentNetwork(result: result)
            
        case "requestMicrophonePermission":
            handleRequestMicrophonePermission(result: result)
            
        case "hasMicrophonePermission":
            handleHasMicrophonePermission(result: result)
            
        case "requestCameraPermission":
            handleRequestCameraPermission(result: result)
            
        case "hasCameraPermission":
            handleHasCameraPermission(result: result)
            
        case "startForegroundService":
            // iOS doesn't need foreground service - background modes handle this
            result(nil)
            
        case "stopForegroundService":
            // iOS doesn't need foreground service
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func handleGetCameras(result: @escaping FlutterResult) {
        let cameras = streamingManager.enumerateCameras()
        result(cameras)
    }
    
    private func handleGetResolutions(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let cameraId = args["cameraId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "cameraId is required",
                details: nil
            ))
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        result(resolutions)
    }
    
    private func handleStartStreaming(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let cameraId = args["cameraId"] as? String,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let frameRate = args["frameRate"] as? Int,
              let bitrate = args["bitrate"] as? Int,
              let audioEnabled = args["audioEnabled"] as? Bool else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing required streaming parameters",
                details: nil
            ))
            return
        }
        
        // Get RTSP configuration
        let rtspEnabled = args["rtspEnabled"] as? Bool ?? false
        let rtspPort = args["rtspPort"] as? Int ?? 8554
        
        // Get RTMP configuration
        var rtmpTargets: [RtmpTarget] = []
        if let rtmpTargetsArray = args["rtmpTargets"] as? [[String: Any]] {
            for targetDict in rtmpTargetsArray {
                if let url = targetDict["url"] as? String,
                   let streamKey = targetDict["streamKey"] as? String,
                   let enabled = targetDict["enabled"] as? Bool {
                    rtmpTargets.append(RtmpTarget(url: url, streamKey: streamKey, enabled: enabled))
                }
            }
        }
        
        // Create configuration
        let config = StreamConfig(
            cameraId: cameraId,
            resolution: Resolution(width: width, height: height),
            frameRate: frameRate,
            bitrate: bitrate,
            audioEnabled: audioEnabled,
            rtspEnabled: rtspEnabled,
            rtspPort: rtspPort,
            rtmpTargets: rtmpTargets
        )
        
        do {
            try streamingManager.startStreaming(config: config)
            result(nil)
        } catch {
            result(FlutterError(
                code: "START_FAILED",
                message: "Failed to start streaming: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
    
    private func handleStopStreaming(result: @escaping FlutterResult) {
        streamingManager.stopStreaming()
        result(nil)
    }
    
    private func handleGetStatistics(result: @escaping FlutterResult) {
        let stats = streamingManager.getStatistics()
        
        let statsDict: [String: Any] = [
            "currentBitrate": stats.currentBitrate,
            "currentFps": stats.currentFps,
            "droppedFrames": stats.droppedFrames,
            "deviceTemperature": stats.deviceTemperature,
            "batteryLevel": stats.batteryLevel,
            "connectionStatus": stats.connectionStatus
        ]
        
        result(statsDict)
    }
    
    private func handleGetStreamURL(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let ipAddress = args["ipAddress"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "ipAddress is required",
                details: nil
            ))
            return
        }
        
        // For now, construct URL with default port
        // In a full implementation, this would get the actual port from StreamingManager
        let port = 8554
        let url = "rtsp://\(ipAddress):\(port)/live"
        result(url)
    }
    
    private func handleStartNetworkMonitoring(result: @escaping FlutterResult) {
        networkMonitor.startMonitoring { [weak self] networkType, ipAddress in
            guard let self = self, let channel = self.networkChannel else { return }
            
            let data: [String: Any] = [
                "networkType": networkType,
                "ipAddress": ipAddress
            ]
            
            channel.invokeMethod("onNetworkChanged", arguments: data)
            
            // Handle RTMP reconnection on network change
            if networkType != "none" {
                self.streamingManager.handleNetworkChange()
            }
        }
        result(nil)
    }
    
    private func handleStopNetworkMonitoring(result: @escaping FlutterResult) {
        networkMonitor.stopMonitoring()
        result(nil)
    }
    
    private func handleGetCurrentNetwork(result: @escaping FlutterResult) {
        let network = networkMonitor.getCurrentNetwork()
        let data: [String: Any] = [
            "networkType": network.networkType,
            "ipAddress": network.ipAddress
        ]
        result(data)
    }
    
    private func handleRequestMicrophonePermission(result: @escaping FlutterResult) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }
    
    private func handleHasMicrophonePermission(result: @escaping FlutterResult) {
        let status = AVAudioSession.sharedInstance().recordPermission
        let granted = (status == .granted)
        result(granted)
    }
    
    private func handleRequestCameraPermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            result(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        result(FlutterError(
                            code: "PERMISSION_DENIED",
                            message: "Camera permission is required to capture video for streaming. " +
                                   "Please grant permission in Settings to enable streaming.",
                            details: nil
                        ))
                    } else {
                        result(granted)
                    }
                }
            }
        case .denied, .restricted:
            result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "Camera permission is required to capture video for streaming. " +
                       "Please grant permission in Settings to enable streaming.",
                details: nil
            ))
        @unknown default:
            result(false)
        }
    }
    
    private func handleHasCameraPermission(result: @escaping FlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let granted = (status == .authorized)
        result(granted)
    }
}
