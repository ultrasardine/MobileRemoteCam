import Foundation
import CoreMedia
import AVFoundation

/// Central coordinator for iOS streaming operations
/// Manages camera capture, encoding, and streaming protocols
class StreamingManager {
    // Components
    private var cameraCapture: CameraCapture?
    private var videoEncoder: VideoEncoder?
    private var audioEncoder: AudioEncoder?
    private var rtspServer: RTSPServer?
    private var rtmpClients: [RTMPClient] = []
    
    // State
    private var isStreaming = false
    private var currentConfig: StreamConfig?
    
    // Statistics tracking
    private var statistics = StreamStatistics()
    private var statisticsLock = NSLock()
    private var statisticsTimer: Timer?
    
    // Frame tracking for statistics
    private var videoFramesEncoded: Int64 = 0
    private var audioFramesEncoded: Int64 = 0
    private var videoFramesDropped: Int64 = 0
    private var lastStatisticsUpdate = Date()
    private var bytesEncodedSinceLastUpdate: Int64 = 0
    
    /// Start streaming with the provided configuration
    /// - Parameter config: Streaming configuration
    /// - Throws: StreamingManagerError if initialization fails
    func startStreaming(config: StreamConfig) throws {
        guard !isStreaming else {
            throw StreamingManagerError.alreadyStreaming
        }
        
        // Store configuration
        currentConfig = config
        
        // Reset statistics
        resetStatistics()
        
        // Initialize camera capture
        let camera = CameraCapture()
        self.cameraCapture = camera
        
        // Initialize video encoder
        let videoEnc = VideoEncoder()
        try videoEnc.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            frameRate: config.frameRate,
            bitrate: config.bitrate
        )
        self.videoEncoder = videoEnc
        
        // Initialize audio encoder if enabled
        if config.audioEnabled {
            let audioEnc = AudioEncoder()
            try audioEnc.configure()
            self.audioEncoder = audioEnc
        }
        
        // Initialize RTSP server if enabled
        if config.rtspEnabled {
            let rtsp = RTSPServer()
            try rtsp.start(port: config.rtspPort)
            self.rtspServer = rtsp
        }
        
        // Initialize RTMP clients if enabled
        for target in config.rtmpTargets where target.enabled {
            let rtmpClient = RTMPClient()
            try rtmpClient.connect(url: target.url, streamKey: target.streamKey)
            rtmpClients.append(rtmpClient)
        }
        
        // Wire up video encoder callbacks
        videoEnc.onEncodedFrame = { [weak self] data, isKeyframe, timestamp in
            guard let self = self else { return }
            
            self.statisticsLock.lock()
            self.videoFramesEncoded += 1
            self.bytesEncodedSinceLastUpdate += Int64(data.count)
            self.statisticsLock.unlock()
            
            // Feed to RTSP server
            self.rtspServer?.feedVideoFrame(data: data, timestamp: timestamp, isKeyframe: isKeyframe)
            
            // Feed to RTMP clients
            let timestampMs = UInt32(CMTimeGetSeconds(timestamp) * 1000)
            for client in self.rtmpClients {
                client.sendVideoFrame(data: data, timestamp: timestampMs, isKeyframe: isKeyframe)
            }
        }
        
        // Wire up audio encoder callbacks if enabled
        if let audioEnc = audioEncoder {
            audioEnc.onEncodedFrame = { [weak self] data, timestamp in
                guard let self = self else { return }
                
                self.statisticsLock.lock()
                self.audioFramesEncoded += 1
                self.bytesEncodedSinceLastUpdate += Int64(data.count)
                self.statisticsLock.unlock()
                
                // Feed to RTSP server
                self.rtspServer?.feedAudioFrame(data: data, timestamp: timestamp)
                
                // Feed to RTMP clients
                let timestampMs = UInt32(CMTimeGetSeconds(timestamp) * 1000)
                for client in self.rtmpClients {
                    client.sendAudioFrame(data: data, timestamp: timestampMs)
                }
            }
        }
        
        // Wire up camera capture callbacks
        camera.onVideoFrame = { [weak self] sampleBuffer in
            guard let self = self else { return }
            
            do {
                try self.videoEncoder?.encode(sampleBuffer: sampleBuffer)
            } catch {
                self.statisticsLock.lock()
                self.videoFramesDropped += 1
                self.statisticsLock.unlock()
                print("StreamingManager: Failed to encode video frame: \(error)")
            }
        }
        
        if config.audioEnabled {
            camera.onAudioSample = { [weak self] sampleBuffer in
                guard let self = self else { return }
                
                do {
                    try self.audioEncoder?.encode(sampleBuffer: sampleBuffer)
                } catch {
                    print("StreamingManager: Failed to encode audio sample: \(error)")
                }
            }
        }
        
        // Start camera capture
        try camera.start(
            cameraId: config.cameraId,
            width: config.resolution.width,
            height: config.resolution.height,
            frameRate: config.frameRate,
            audioEnabled: config.audioEnabled
        )
        
        // Mark as streaming
        isStreaming = true
        
        // Start statistics timer (update every second)
        startStatisticsTimer()
    }
    
    /// Stop streaming and release all resources
    func stopStreaming() {
        guard isStreaming else { return }
        
        // Stop statistics timer
        stopStatisticsTimer()
        
        // Stop camera capture
        cameraCapture?.stop()
        
        // Shutdown encoders
        videoEncoder?.shutdown()
        audioEncoder?.shutdown()
        
        // Stop RTSP server
        rtspServer?.stop()
        
        // Disconnect RTMP clients
        for client in rtmpClients {
            client.disconnect()
        }
        
        // Clear references
        cameraCapture = nil
        videoEncoder = nil
        audioEncoder = nil
        rtspServer = nil
        rtmpClients.removeAll()
        currentConfig = nil
        
        // Mark as not streaming
        isStreaming = false
    }
    
    /// Get current streaming statistics
    /// - Returns: StreamStatistics object with current metrics
    func getStatistics() -> StreamStatistics {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        return statistics
    }
    
    /// Enumerate available cameras
    /// - Returns: Array of camera information dictionaries
    func enumerateCameras() -> [[String: Any]] {
        let camera = CameraCapture()
        return camera.enumerateCameras()
    }
    
    /// Get available resolutions for a specific camera
    /// - Parameter cameraId: Camera identifier
    /// - Returns: Array of resolution dictionaries
    func getResolutions(cameraId: String) -> [[String: Any]] {
        let camera = CameraCapture()
        return camera.getResolutions(cameraId: cameraId)
    }
    
    /// Check if currently streaming
    var streaming: Bool {
        return isStreaming
    }
    
    /// Handle network change event - attempt to reconnect RTMP clients
    func handleNetworkChange() {
        guard isStreaming else { return }
        
        // Attempt to reconnect disconnected RTMP clients
        for client in rtmpClients {
            if !client.connected {
                Task {
                    do {
                        try await client.reconnect()
                        print("StreamingManager: RTMP client reconnected after network change")
                    } catch {
                        print("StreamingManager: Failed to reconnect RTMP client: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func resetStatistics() {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        statistics = StreamStatistics()
        videoFramesEncoded = 0
        audioFramesEncoded = 0
        videoFramesDropped = 0
        lastStatisticsUpdate = Date()
        bytesEncodedSinceLastUpdate = 0
    }
    
    private func startStatisticsTimer() {
        statisticsTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { [weak self] _ in
            self?.updateStatistics()
        }
    }
    
    private func stopStatisticsTimer() {
        statisticsTimer?.invalidate()
        statisticsTimer = nil
    }
    
    private func updateStatistics() {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastStatisticsUpdate)
        
        guard timeDelta > 0 else { return }
        
        // Calculate current bitrate (Mbps)
        let bitsEncoded = bytesEncodedSinceLastUpdate * 8
        let currentBitrate = Double(bitsEncoded) / timeDelta / 1_000_000.0
        
        // Calculate current FPS
        let framesSinceLastUpdate = videoFramesEncoded - statistics.totalVideoFrames
        let currentFps = Int(Double(framesSinceLastUpdate) / timeDelta)
        
        // Update statistics
        statistics.currentBitrate = currentBitrate
        statistics.currentFps = currentFps
        statistics.droppedFrames = Int(videoFramesDropped)
        statistics.totalVideoFrames = videoFramesEncoded
        statistics.totalAudioFrames = audioFramesEncoded
        
        // Update connection status
        updateConnectionStatus()
        
        // Get device metrics
        updateDeviceMetrics()
        
        // Reset counters for next interval
        lastStatisticsUpdate = now
        bytesEncodedSinceLastUpdate = 0
    }
    
    private func updateConnectionStatus() {
        var connectionStatus: [String: String] = [:]
        
        // RTSP status
        if let rtsp = rtspServer {
            connectionStatus["rtsp"] = rtsp.running ? "connected" : "disconnected"
        }
        
        // RTMP status
        for (index, client) in rtmpClients.enumerated() {
            let key = "rtmp_\(index)"
            connectionStatus[key] = client.connected ? "connected" : "disconnected"
        }
        
        statistics.connectionStatus = connectionStatus
    }
    
    private func updateDeviceMetrics() {
        // Get battery level
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel >= 0 {
            statistics.batteryLevel = Int(batteryLevel * 100)
        }
        
        // Note: Device temperature is not directly accessible on iOS
        // In a real implementation, you might use private APIs or estimate based on thermal state
        statistics.deviceTemperature = 0.0
    }
}

// MARK: - Data Structures

/// Streaming configuration
struct StreamConfig {
    let cameraId: String
    let resolution: Resolution
    let frameRate: Int
    let bitrate: Int
    let audioEnabled: Bool
    
    // RTSP configuration
    let rtspEnabled: Bool
    let rtspPort: Int
    
    // RTMP configuration
    let rtmpTargets: [RtmpTarget]
}

/// Resolution specification
struct Resolution {
    let width: Int
    let height: Int
}

/// RTMP target configuration
struct RtmpTarget {
    let url: String
    let streamKey: String
    let enabled: Bool
}

/// Streaming statistics
struct StreamStatistics {
    var currentBitrate: Double = 0.0  // Mbps
    var currentFps: Int = 0
    var droppedFrames: Int = 0
    var deviceTemperature: Double = 0.0  // Celsius
    var batteryLevel: Int = 100  // percentage
    var connectionStatus: [String: String] = [:]
    
    // Internal tracking
    var totalVideoFrames: Int64 = 0
    var totalAudioFrames: Int64 = 0
}

// MARK: - Error Types

enum StreamingManagerError: Error {
    case alreadyStreaming
    case notStreaming
    case cameraInitializationFailed
    case encoderInitializationFailed
    case rtspServerStartFailed
    case rtmpConnectionFailed
    
    var localizedDescription: String {
        switch self {
        case .alreadyStreaming:
            return "Streaming is already active"
        case .notStreaming:
            return "Streaming is not active"
        case .cameraInitializationFailed:
            return "Failed to initialize camera"
        case .encoderInitializationFailed:
            return "Failed to initialize encoder"
        case .rtspServerStartFailed:
            return "Failed to start RTSP server"
        case .rtmpConnectionFailed:
            return "Failed to connect to RTMP server"
        }
    }
}
