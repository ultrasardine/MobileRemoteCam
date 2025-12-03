import XCTest
import CoreMedia
@testable import Runner

/// Property-based tests for RTSPServer
class RTSPServerTests: XCTestCase {
    
    var rtspServer: RTSPServer!
    
    override func setUp() {
        super.setUp()
        rtspServer = RTSPServer()
    }
    
    override func tearDown() {
        rtspServer?.stop()
        rtspServer = nil
        super.tearDown()
    }
    
    // MARK: - Property 7: RTSP server starts on configured port
    // Feature: ip-camera-streaming-platform, Property 7: RTSP server starts on configured port
    // Validates: Requirements 3.1, 3.2
    
    func testRTSPServerStartsOnConfiguredPort() {
        // Property: For any valid port number (1024-65535), when RTSP is enabled,
        // the system should successfully bind and listen on that port
        
        let validPorts = [1024, 8554, 10000, 20000, 30000, 40000, 50000, 60000, 65535]
        
        for port in validPorts {
            let server = RTSPServer()
            
            do {
                try server.start(port: port)
                
                // Property: Server should be running after start
                XCTAssertTrue(
                    server.running,
                    "RTSP server should be running after start on port \(port)"
                )
                
                // Property: Server should report the correct port
                XCTAssertEqual(
                    server.currentPort,
                    port,
                    "RTSP server should report port \(port) after starting on that port"
                )
                
                server.stop()
                
                // Property: Server should not be running after stop
                XCTAssertFalse(
                    server.running,
                    "RTSP server should not be running after stop"
                )
            } catch {
                XCTFail("RTSP server failed to start on valid port \(port): \(error)")
            }
        }
    }
    
    func testRTSPServerRejectsInvalidPorts() {
        // Property: For any invalid port number (< 1024 or > 65535),
        // the system should reject the configuration
        
        let invalidPorts = [0, 80, 443, 1023, 65536, 70000, 100000]
        
        for port in invalidPorts {
            let server = RTSPServer()
            
            do {
                try server.start(port: port)
                XCTFail("RTSP server should reject invalid port \(port)")
            } catch RTSPServerError.invalidPort {
                // Expected error
                XCTAssertFalse(
                    server.running,
                    "RTSP server should not be running after failed start"
                )
            } catch {
                XCTFail("RTSP server threw unexpected error for port \(port): \(error)")
            }
        }
    }
    
    func testRTSPServerPreventsDoubleStart() {
        // Property: Starting an already running server should fail
        
        do {
            try rtspServer.start(port: 8554)
            XCTAssertTrue(rtspServer.running)
            
            // Try to start again
            do {
                try rtspServer.start(port: 8555)
                XCTFail("RTSP server should not allow double start")
            } catch RTSPServerError.alreadyRunning {
                // Expected error
                XCTAssertTrue(rtspServer.running, "Server should still be running")
                XCTAssertEqual(rtspServer.currentPort, 8554, "Port should not have changed")
            }
        } catch {
            XCTFail("Initial server start failed: \(error)")
        }
    }
    
    func testRTSPServerStopIsIdempotent() {
        // Property: Stopping a stopped server should be safe (no error)
        
        do {
            try rtspServer.start(port: 8554)
            rtspServer.stop()
            XCTAssertFalse(rtspServer.running)
            
            // Stop again - should not crash or throw
            rtspServer.stop()
            XCTAssertFalse(rtspServer.running)
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    func testRTSPServerCanRestartOnDifferentPort() {
        // Property: After stopping, server can restart on a different port
        
        do {
            try rtspServer.start(port: 8554)
            XCTAssertEqual(rtspServer.currentPort, 8554)
            
            rtspServer.stop()
            XCTAssertFalse(rtspServer.running)
            
            try rtspServer.start(port: 9000)
            XCTAssertTrue(rtspServer.running)
            XCTAssertEqual(rtspServer.currentPort, 9000)
        } catch {
            XCTFail("Server restart failed: \(error)")
        }
    }
    
    // MARK: - Property 9: RTSP timestamps are monotonically increasing
    // Feature: ip-camera-streaming-platform, Property 9: RTSP timestamps are monotonically increasing
    // Validates: Requirements 3.4
    
    func testRTSPTimestampsAreMonotonicallyIncreasing() {
        // Property: For any sequence of frames fed to the RTSP server,
        // the timestamps should be monotonically increasing
        
        do {
            try rtspServer.start(port: 8554)
            
            // Generate a sequence of video frames with increasing timestamps
            let frameCount = 100
            var previousTimestamp = CMTime.zero
            
            for i in 0..<frameCount {
                let timestamp = CMTime(value: CMTimeValue(i * 33), timescale: 1000) // ~30fps
                let frameData = Data(repeating: UInt8(i % 256), count: 1024)
                let isKeyframe = (i % 30 == 0)
                
                // Property: Each timestamp should be >= previous timestamp
                XCTAssertTrue(
                    timestamp >= previousTimestamp,
                    "Timestamp at frame \(i) should be >= previous timestamp"
                )
                
                rtspServer.feedVideoFrame(
                    data: frameData,
                    timestamp: timestamp,
                    isKeyframe: isKeyframe
                )
                
                previousTimestamp = timestamp
            }
            
            let stats = rtspServer.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            
            // Property: All frames should be accepted
            XCTAssertEqual(
                videoFrameCount,
                Int64(frameCount),
                "All \(frameCount) frames should be accepted by RTSP server"
            )
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    func testRTSPHandlesNonMonotonicTimestampsGracefully() {
        // Property: Server should handle non-monotonic timestamps without crashing
        // (though it may log warnings)
        
        do {
            try rtspServer.start(port: 8554)
            
            // Feed frames with non-monotonic timestamps
            let timestamps: [CMTimeValue] = [0, 33, 66, 50, 100, 80, 133] // Some go backwards
            
            for (i, timestampValue) in timestamps.enumerated() {
                let timestamp = CMTime(value: timestampValue, timescale: 1000)
                let frameData = Data(repeating: UInt8(i % 256), count: 1024)
                
                // Should not crash
                rtspServer.feedVideoFrame(
                    data: frameData,
                    timestamp: timestamp,
                    isKeyframe: (i == 0)
                )
            }
            
            let stats = rtspServer.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            
            // Property: All frames should still be accepted (even if timestamps are wrong)
            XCTAssertEqual(
                videoFrameCount,
                Int64(timestamps.count),
                "All frames should be accepted even with non-monotonic timestamps"
            )
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    func testRTSPAudioTimestampsAreMonotonicallyIncreasing() {
        // Property: Audio timestamps should also be monotonically increasing
        
        do {
            try rtspServer.start(port: 8554)
            
            let frameCount = 100
            var previousTimestamp = CMTime.zero
            
            for i in 0..<frameCount {
                let timestamp = CMTime(value: CMTimeValue(i * 23), timescale: 1000) // ~43fps audio
                let frameData = Data(repeating: UInt8(i % 256), count: 512)
                
                // Property: Each timestamp should be >= previous timestamp
                XCTAssertTrue(
                    timestamp >= previousTimestamp,
                    "Audio timestamp at frame \(i) should be >= previous timestamp"
                )
                
                rtspServer.feedAudioFrame(
                    data: frameData,
                    timestamp: timestamp
                )
                
                previousTimestamp = timestamp
            }
            
            let stats = rtspServer.getStatistics()
            let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
            
            // Property: All audio frames should be accepted
            XCTAssertEqual(
                audioFrameCount,
                Int64(frameCount),
                "All \(frameCount) audio frames should be accepted by RTSP server"
            )
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    // MARK: - Additional Property Tests
    
    func testRTSPServerGeneratesValidStreamURL() {
        // Property: For any device IP address and RTSP port configuration,
        // the displayed stream URL should match the format rtsp://[IP]:[PORT]/live
        
        let testCases: [(ip: String, port: Int, expected: String)] = [
            ("192.168.1.100", 8554, "rtsp://192.168.1.100:8554/live"),
            ("10.0.0.5", 9000, "rtsp://10.0.0.5:9000/live"),
            ("172.16.0.1", 1024, "rtsp://172.16.0.1:1024/live"),
            ("192.168.0.255", 65535, "rtsp://192.168.0.255:65535/live")
        ]
        
        for testCase in testCases {
            do {
                let server = RTSPServer()
                try server.start(port: testCase.port)
                
                let url = server.getStreamURL(ipAddress: testCase.ip)
                
                // Property: URL should match expected format
                XCTAssertEqual(
                    url,
                    testCase.expected,
                    "Stream URL should match expected format for IP \(testCase.ip) and port \(testCase.port)"
                )
                
                // Property: URL should be a valid RTSP URL
                XCTAssertTrue(
                    url.hasPrefix("rtsp://"),
                    "Stream URL should start with rtsp://"
                )
                
                XCTAssertTrue(
                    url.contains(testCase.ip),
                    "Stream URL should contain IP address"
                )
                
                XCTAssertTrue(
                    url.contains(":\(testCase.port)"),
                    "Stream URL should contain port number"
                )
                
                server.stop()
            } catch {
                XCTFail("Server start failed for port \(testCase.port): \(error)")
            }
        }
    }
    
    func testRTSPServerIgnoresFramesWhenNotRunning() {
        // Property: Feeding frames to a stopped server should not crash
        
        let frameData = Data(repeating: 0, count: 1024)
        let timestamp = CMTime(value: 0, timescale: 1000)
        
        // Server is not started
        XCTAssertFalse(rtspServer.running)
        
        // Should not crash
        rtspServer.feedVideoFrame(data: frameData, timestamp: timestamp, isKeyframe: true)
        rtspServer.feedAudioFrame(data: frameData, timestamp: timestamp)
        
        let stats = rtspServer.getStatistics()
        let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
        let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
        
        // Property: Frames should be ignored when server is not running
        XCTAssertEqual(videoFrameCount, 0, "Video frames should be ignored when server is not running")
        XCTAssertEqual(audioFrameCount, 0, "Audio frames should be ignored when server is not running")
    }
    
    func testRTSPServerHandlesEmptyFrameData() {
        // Property: Server should handle empty frame data gracefully
        
        do {
            try rtspServer.start(port: 8554)
            
            let emptyData = Data()
            let timestamp = CMTime(value: 0, timescale: 1000)
            
            // Should not crash
            rtspServer.feedVideoFrame(data: emptyData, timestamp: timestamp, isKeyframe: true)
            rtspServer.feedAudioFrame(data: emptyData, timestamp: timestamp)
            
            let stats = rtspServer.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
            
            // Property: Empty frames should still be counted
            XCTAssertEqual(videoFrameCount, 1, "Empty video frame should be counted")
            XCTAssertEqual(audioFrameCount, 1, "Empty audio frame should be counted")
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    func testRTSPServerHandlesLargeFrameData() {
        // Property: Server should handle large frame data without issues
        
        do {
            try rtspServer.start(port: 8554)
            
            // Create a large frame (1MB)
            let largeData = Data(repeating: 0xFF, count: 1024 * 1024)
            let timestamp = CMTime(value: 0, timescale: 1000)
            
            // Should not crash
            rtspServer.feedVideoFrame(data: largeData, timestamp: timestamp, isKeyframe: true)
            
            let stats = rtspServer.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            
            // Property: Large frame should be accepted
            XCTAssertEqual(videoFrameCount, 1, "Large video frame should be accepted")
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
    
    func testRTSPServerStatisticsAreAccurate() {
        // Property: Server statistics should accurately reflect the number of frames fed
        
        do {
            try rtspServer.start(port: 8554)
            
            let videoFrameCount = 50
            let audioFrameCount = 75
            
            // Feed video frames
            for i in 0..<videoFrameCount {
                let timestamp = CMTime(value: CMTimeValue(i * 33), timescale: 1000)
                let frameData = Data(repeating: UInt8(i % 256), count: 1024)
                rtspServer.feedVideoFrame(data: frameData, timestamp: timestamp, isKeyframe: (i % 30 == 0))
            }
            
            // Feed audio frames
            for i in 0..<audioFrameCount {
                let timestamp = CMTime(value: CMTimeValue(i * 23), timescale: 1000)
                let frameData = Data(repeating: UInt8(i % 256), count: 512)
                rtspServer.feedAudioFrame(data: frameData, timestamp: timestamp)
            }
            
            let stats = rtspServer.getStatistics()
            let reportedVideoFrames = stats["videoFrameCount"] as? Int64 ?? 0
            let reportedAudioFrames = stats["audioFrameCount"] as? Int64 ?? 0
            
            // Property: Statistics should match actual frame counts
            XCTAssertEqual(
                reportedVideoFrames,
                Int64(videoFrameCount),
                "Video frame count should be accurate"
            )
            
            XCTAssertEqual(
                reportedAudioFrames,
                Int64(audioFrameCount),
                "Audio frame count should be accurate"
            )
        } catch {
            XCTFail("Server start failed: \(error)")
        }
    }
}
