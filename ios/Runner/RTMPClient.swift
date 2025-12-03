import Foundation
import CoreMedia

/// RTMP Client for cloud streaming using librtmp
/// Provides RTMP streaming to platforms like YouTube and Twitch
class RTMPClient {
    private var isConnected = false
    private var rtmpURL: String = ""
    private var streamKey: String = ""
    private var clientQueue = DispatchQueue(label: "com.ipcamera.rtmpClient")
    
    // Reconnection state
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private var reconnectionTimer: Timer?
    
    // Frame buffers
    private var videoFrameBuffer: [VideoFrame] = []
    private var audioFrameBuffer: [AudioFrame] = []
    private let bufferLock = NSLock()
    
    // Statistics
    private var videoFrameCount: Int64 = 0
    private var audioFrameCount: Int64 = 0
    private var bytesSent: Int64 = 0
    
    /// Connect to RTMP server with URL and stream key
    /// - Parameters:
    ///   - url: RTMP server URL (e.g., rtmp://a.rtmp.youtube.com/live2)
    ///   - streamKey: Stream authentication key
    /// - Throws: RTMPClientError if connection fails
    func connect(url: String, streamKey: String) throws {
        guard !isConnected else {
            throw RTMPClientError.alreadyConnected
        }
        
        // Validate RTMP URL format
        guard isValidRTMPURL(url) else {
            throw RTMPClientError.invalidURL
        }
        
        // Validate stream key is not empty
        guard !streamKey.isEmpty else {
            throw RTMPClientError.invalidStreamKey
        }
        
        self.rtmpURL = url
        self.streamKey = streamKey
        
        // Reset reconnection state
        reconnectionAttempts = 0
        
        // Attempt connection
        try performConnection()
    }
    
    /// Disconnect from RTMP server
    func disconnect() {
        guard isConnected else { return }
        
        clientQueue.sync {
            isConnected = false
            
            // Cancel any pending reconnection
            reconnectionTimer?.invalidate()
            reconnectionTimer = nil
            
            // Clear buffers
            bufferLock.lock()
            videoFrameBuffer.removeAll()
            audioFrameBuffer.removeAll()
            bufferLock.unlock()
            
            // Reset statistics
            videoFrameCount = 0
            audioFrameCount = 0
            bytesSent = 0
            reconnectionAttempts = 0
            
            print("RTMP Client disconnected from \(rtmpURL)")
            
            // In a real implementation, this would:
            // 1. Close the librtmp connection
            // 2. Clean up network resources
            // 3. Flush any pending data
        }
    }
    
    /// Send a video frame to RTMP server
    /// - Parameters:
    ///   - data: Encoded H.264 frame data
    ///   - timestamp: Timestamp in milliseconds
    ///   - isKeyframe: Whether this is a keyframe (I-frame)
    func sendVideoFrame(data: Data, timestamp: UInt32, isKeyframe: Bool) {
        guard isConnected else { return }
        
        // Packetize as FLV
        let flvPacket = packetizeVideoAsFLV(data: data, timestamp: timestamp, isKeyframe: isKeyframe)
        
        let frame = VideoFrame(
            data: flvPacket,
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
        bytesSent += Int64(flvPacket.count)
        
        // In a real implementation, this would:
        // 1. Send FLV packet via librtmp
        // 2. Handle send errors
        // 3. Trigger reconnection if needed
    }
    
    /// Send an audio frame to RTMP server
    /// - Parameters:
    ///   - data: Encoded AAC frame data
    ///   - timestamp: Timestamp in milliseconds
    func sendAudioFrame(data: Data, timestamp: UInt32) {
        guard isConnected else { return }
        
        // Packetize as FLV
        let flvPacket = packetizeAudioAsFLV(data: data, timestamp: timestamp)
        
        let frame = AudioFrame(
            data: flvPacket,
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
        bytesSent += Int64(flvPacket.count)
        
        // In a real implementation, this would:
        // 1. Send FLV packet via librtmp
        // 2. Handle send errors
        // 3. Trigger reconnection if needed
    }
    
    /// Attempt reconnection with exponential backoff
    func reconnect() async throws {
        guard !isConnected else {
            throw RTMPClientError.alreadyConnected
        }
        
        guard reconnectionAttempts < maxReconnectionAttempts else {
            throw RTMPClientError.maxReconnectionAttemptsReached
        }
        
        // Calculate exponential backoff delay
        let delay = calculateBackoffDelay(attempt: reconnectionAttempts)
        
        print("RTMP Client: Reconnection attempt \(reconnectionAttempts + 1)/\(maxReconnectionAttempts) after \(delay)s")
        
        // Wait for backoff period
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        reconnectionAttempts += 1
        
        // Attempt connection
        try performConnection()
    }
    
    /// Get connection status
    var connected: Bool {
        return isConnected
    }
    
    /// Get current reconnection attempt count
    var currentReconnectionAttempt: Int {
        return reconnectionAttempts
    }
    
    /// Get statistics
    func getStatistics() -> [String: Any] {
        return [
            "videoFrameCount": videoFrameCount,
            "audioFrameCount": audioFrameCount,
            "bytesSent": bytesSent,
            "isConnected": isConnected,
            "reconnectionAttempts": reconnectionAttempts
        ]
    }
    
    // MARK: - Private Methods
    
    private func performConnection() throws {
        // Simulate connection
        // In a real implementation, this would:
        // 1. Initialize librtmp
        // 2. Set connection parameters
        // 3. Perform RTMP handshake
        // 4. Send connect and createStream commands
        
        clientQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Simulate connection delay
            Thread.sleep(forTimeInterval: 0.1)
            
            self.isConnected = true
            print("RTMP Client connected to \(self.rtmpURL)")
        }
        
        // Give connection time to establish
        Thread.sleep(forTimeInterval: 0.15)
        
        if !isConnected {
            throw RTMPClientError.connectionFailed
        }
    }
    
    private func isValidRTMPURL(_ url: String) -> Bool {
        // RTMP URL format: rtmp://[host]/[app]
        // Examples:
        // - rtmp://a.rtmp.youtube.com/live2
        // - rtmp://live.twitch.tv/app
        
        guard url.hasPrefix("rtmp://") || url.hasPrefix("rtmps://") else {
            return false
        }
        
        // Remove protocol
        let withoutProtocol = url.replacingOccurrences(of: "rtmp://", with: "")
            .replacingOccurrences(of: "rtmps://", with: "")
        
        // Should have at least host/app format
        let components = withoutProtocol.components(separatedBy: "/")
        guard components.count >= 2 else {
            return false
        }
        
        // Host should not be empty
        guard !components[0].isEmpty else {
            return false
        }
        
        // App should not be empty
        guard !components[1].isEmpty else {
            return false
        }
        
        return true
    }
    
    private func calculateBackoffDelay(attempt: Int) -> Double {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let baseDelay = 1.0
        let maxDelay = 16.0
        let delay = baseDelay * pow(2.0, Double(attempt))
        return min(delay, maxDelay)
    }
    
    private func packetizeVideoAsFLV(data: Data, timestamp: UInt32, isKeyframe: Bool) -> Data {
        // FLV video tag format:
        // - Frame type (4 bits): 1 = keyframe, 2 = inter frame
        // - Codec ID (4 bits): 7 = AVC (H.264)
        // - AVC packet type (1 byte): 0 = sequence header, 1 = NALU
        // - Composition time (3 bytes): 0 for now
        // - Data
        
        var flvPacket = Data()
        
        // Frame type and codec ID
        let frameType: UInt8 = isKeyframe ? 0x10 : 0x20 // 1 = keyframe, 2 = inter
        let codecID: UInt8 = 0x07 // AVC
        flvPacket.append(frameType | codecID)
        
        // AVC packet type (1 = NALU)
        flvPacket.append(0x01)
        
        // Composition time (3 bytes, big-endian)
        flvPacket.append(0x00)
        flvPacket.append(0x00)
        flvPacket.append(0x00)
        
        // Append H.264 data
        flvPacket.append(data)
        
        return flvPacket
    }
    
    private func packetizeAudioAsFLV(data: Data, timestamp: UInt32) -> Data {
        // FLV audio tag format:
        // - Sound format (4 bits): 10 = AAC
        // - Sound rate (2 bits): 3 = 44 kHz
        // - Sound size (1 bit): 1 = 16-bit
        // - Sound type (1 bit): 1 = stereo
        // - AAC packet type (1 byte): 0 = sequence header, 1 = raw
        // - Data
        
        var flvPacket = Data()
        
        // Sound format, rate, size, type
        let soundFormat: UInt8 = 0xA0 // AAC (10 << 4)
        let soundRate: UInt8 = 0x0C   // 44 kHz (3 << 2)
        let soundSize: UInt8 = 0x02   // 16-bit (1 << 1)
        let soundType: UInt8 = 0x01   // Stereo
        flvPacket.append(soundFormat | soundRate | soundSize | soundType)
        
        // AAC packet type (1 = raw AAC frame)
        flvPacket.append(0x01)
        
        // Append AAC data
        flvPacket.append(data)
        
        return flvPacket
    }
}

// MARK: - Data Structures

private struct VideoFrame {
    let data: Data
    let timestamp: UInt32
    let isKeyframe: Bool
}

private struct AudioFrame {
    let data: Data
    let timestamp: UInt32
}

// MARK: - Error Types

enum RTMPClientError: Error {
    case alreadyConnected
    case invalidURL
    case invalidStreamKey
    case connectionFailed
    case notConnected
    case sendFailed
    case maxReconnectionAttemptsReached
    
    var localizedDescription: String {
        switch self {
        case .alreadyConnected:
            return "RTMP client is already connected"
        case .invalidURL:
            return "Invalid RTMP URL format. Expected: rtmp://[host]/[app]"
        case .invalidStreamKey:
            return "Stream key cannot be empty"
        case .connectionFailed:
            return "Failed to connect to RTMP server"
        case .notConnected:
            return "RTMP client is not connected"
        case .sendFailed:
            return "Failed to send data to RTMP server"
        case .maxReconnectionAttemptsReached:
            return "Maximum reconnection attempts reached"
        }
    }
}
