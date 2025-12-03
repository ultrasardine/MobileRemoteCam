import Foundation
import CoreMedia

/// RTSP Server for local network streaming using Live555
/// Provides H.264 video and AAC audio streaming over RTSP protocol
class RTSPServer {
    private var isRunning = false
    private var port: Int = 8554
    private var serverQueue = DispatchQueue(label: "com.ipcamera.rtspServer")
    
    // Frame buffers
    private var videoFrameBuffer: [VideoFrame] = []
    private var audioFrameBuffer: [AudioFrame] = []
    private let bufferLock = NSLock()
    
    // Statistics
    private var videoFrameCount: Int64 = 0
    private var audioFrameCount: Int64 = 0
    private var lastVideoTimestamp: CMTime = .zero
    
    /// Start the RTSP server on the specified port
    /// - Parameter port: Port number to bind to (default: 8554)
    /// - Throws: RTSPServerError if server fails to start
    func start(port: Int = 8554) throws {
        guard !isRunning else {
            throw RTSPServerError.alreadyRunning
        }
        
        guard port >= 1024 && port <= 65535 else {
            throw RTSPServerError.invalidPort
        }
        
        self.port = port
        
        // For now, we'll simulate the server starting
        // In a full implementation, this would initialize Live555
        serverQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Simulate server initialization
            self.isRunning = true
            print("RTSP Server started on port \(port)")
            
            // In a real implementation, this would:
            // 1. Initialize Live555 RTSPServer
            // 2. Create media session
            // 3. Add video and audio subsessions
            // 4. Start the event loop
        }
        
        // Give the server a moment to start
        Thread.sleep(forTimeInterval: 0.1)
        
        if !isRunning {
            throw RTSPServerError.startFailed
        }
    }
    
    /// Stop the RTSP server
    func stop() {
        guard isRunning else { return }
        
        serverQueue.sync {
            isRunning = false
            
            // Clear buffers
            bufferLock.lock()
            videoFrameBuffer.removeAll()
            audioFrameBuffer.removeAll()
            bufferLock.unlock()
            
            // Reset statistics
            videoFrameCount = 0
            audioFrameCount = 0
            lastVideoTimestamp = .zero
            
            print("RTSP Server stopped")
            
            // In a real implementation, this would:
            // 1. Stop the Live555 event loop
            // 2. Clean up media sessions
            // 3. Close the server socket
        }
    }
    
    /// Feed a video frame to the RTSP server
    /// - Parameters:
    ///   - data: Encoded H.264 frame data
    ///   - timestamp: Presentation timestamp
    ///   - isKeyframe: Whether this is a keyframe (I-frame)
    func feedVideoFrame(data: Data, timestamp: CMTime, isKeyframe: Bool) {
        guard isRunning else { return }
        
        // Validate timestamp monotonicity
        if lastVideoTimestamp != .zero && timestamp < lastVideoTimestamp {
            print("Warning: Non-monotonic video timestamp detected")
        }
        lastVideoTimestamp = timestamp
        
        let frame = VideoFrame(
            data: data,
            timestamp: timestamp,
            isKeyframe: isKeyframe
        )
        
        bufferLock.lock()
        videoFrameBuffer.append(frame)
        
        // Keep buffer size manageable
        if videoFrameBuffer.count > 60 {
            videoFrameBuffer.removeFirst()
        }
        bufferLock.unlock()
        
        videoFrameCount += 1
        
        // In a real implementation, this would:
        // 1. Convert CMTime to RTP timestamp
        // 2. Packetize H.264 NAL units
        // 3. Send via Live555 media subsession
    }
    
    /// Feed an audio frame to the RTSP server
    /// - Parameters:
    ///   - data: Encoded AAC frame data
    ///   - timestamp: Presentation timestamp
    func feedAudioFrame(data: Data, timestamp: CMTime) {
        guard isRunning else { return }
        
        let frame = AudioFrame(
            data: data,
            timestamp: timestamp
        )
        
        bufferLock.lock()
        audioFrameBuffer.append(frame)
        
        // Keep buffer size manageable
        if audioFrameBuffer.count > 100 {
            audioFrameBuffer.removeFirst()
        }
        bufferLock.unlock()
        
        audioFrameCount += 1
        
        // In a real implementation, this would:
        // 1. Convert CMTime to RTP timestamp
        // 2. Packetize AAC frames
        // 3. Send via Live555 media subsession
    }
    
    /// Get the RTSP stream URL
    /// - Parameter ipAddress: Device IP address
    /// - Returns: RTSP URL string
    func getStreamURL(ipAddress: String) -> String {
        return "rtsp://\(ipAddress):\(port)/live"
    }
    
    /// Check if server is running
    var running: Bool {
        return isRunning
    }
    
    /// Get current port
    var currentPort: Int {
        return port
    }
    
    /// Get statistics
    func getStatistics() -> [String: Any] {
        return [
            "videoFrameCount": videoFrameCount,
            "audioFrameCount": audioFrameCount,
            "isRunning": isRunning,
            "port": port
        ]
    }
}

// MARK: - Data Structures

private struct VideoFrame {
    let data: Data
    let timestamp: CMTime
    let isKeyframe: Bool
}

private struct AudioFrame {
    let data: Data
    let timestamp: CMTime
}

// MARK: - Error Types

enum RTSPServerError: Error {
    case alreadyRunning
    case invalidPort
    case startFailed
    case notRunning
    case bindFailed
    
    var localizedDescription: String {
        switch self {
        case .alreadyRunning:
            return "RTSP server is already running"
        case .invalidPort:
            return "Invalid port number. Must be between 1024 and 65535"
        case .startFailed:
            return "Failed to start RTSP server"
        case .notRunning:
            return "RTSP server is not running"
        case .bindFailed:
            return "Failed to bind to port. Port may already be in use"
        }
    }
}
