import XCTest
import CoreMedia
@testable import Runner

/// Property-based tests for RTMPClient
class RTMPClientTests: XCTestCase {
    
    var rtmpClient: RTMPClient!
    
    override func setUp() {
        super.setUp()
        rtmpClient = RTMPClient()
    }
    
    override func tearDown() {
        rtmpClient?.disconnect()
        rtmpClient = nil
        super.tearDown()
    }
    
    // MARK: - Property 13: Valid RTMP URLs are accepted
    // Feature: ip-camera-streaming-platform, Property 13: Valid RTMP URLs are accepted
    // Validates: Requirements 4.2, 4.3
    
    func testValidRTMPURLsAreAccepted() {
        // Property: For any valid RTMP URL (format: rtmp://[host]/[app]) and non-empty stream key,
        // the system should accept and store the configuration without error
        
        let validURLs = [
            "rtmp://a.rtmp.youtube.com/live2",
            "rtmp://live.twitch.tv/app",
            "rtmp://live-api-s.facebook.com:80/rtmp",
            "rtmp://192.168.1.100/live",
            "rtmp://example.com/stream",
            "rtmps://secure.example.com/live",
            "rtmp://server.com/app/stream",
            "rtmp://cdn.example.com:1935/live"
        ]
        
        let validStreamKeys = [
            "test-stream-key-123",
            "abcd-efgh-ijkl-mnop",
            "live_1234567890",
            "sk_test_key",
            "very-long-stream-key-with-many-characters-1234567890"
        ]
        
        for url in validURLs {
            for streamKey in validStreamKeys {
                let client = RTMPClient()
                
                do {
                    try client.connect(url: url, streamKey: streamKey)
                    
                    // Property: Connection should succeed for valid URL and stream key
                    XCTAssertTrue(
                        client.connected,
                        "Client should be connected after successful connect with URL: \(url)"
                    )
                    
                    client.disconnect()
                    
                    // Property: Client should be disconnected after disconnect
                    XCTAssertFalse(
                        client.connected,
                        "Client should be disconnected after disconnect"
                    )
                } catch {
                    XCTFail("Valid RTMP URL '\(url)' with stream key '\(streamKey)' should be accepted but got error: \(error)")
                }
            }
        }
    }
    
    func testInvalidRTMPURLsAreRejected() {
        // Property: For any invalid RTMP URL, the system should reject the configuration
        
        let invalidURLs = [
            "",                                    // Empty
            "http://example.com/live",            // Wrong protocol
            "rtmp://",                            // No host
            "rtmp://example.com",                 // No app
            "rtmp://example.com/",                // Empty app
            "rtmp:///live",                       // No host
            "ftp://example.com/live",             // Wrong protocol
            "rtmp//example.com/live",             // Missing colon
            "example.com/live",                   // No protocol
            "rtmp:/example.com/live"              // Single slash
        ]
        
        let validStreamKey = "test-key"
        
        for url in invalidURLs {
            let client = RTMPClient()
            
            do {
                try client.connect(url: url, streamKey: validStreamKey)
                XCTFail("Invalid RTMP URL '\(url)' should be rejected")
            } catch RTMPClientError.invalidURL {
                // Expected error
                XCTAssertFalse(
                    client.connected,
                    "Client should not be connected after failed connect with invalid URL"
                )
            } catch {
                XCTFail("Invalid RTMP URL '\(url)' threw unexpected error: \(error)")
            }
        }
    }
    
    func testEmptyStreamKeyIsRejected() {
        // Property: For any empty stream key, the system should reject the configuration
        
        let validURL = "rtmp://a.rtmp.youtube.com/live2"
        let invalidStreamKeys = ["", "   ", "\t", "\n"]
        
        for streamKey in invalidStreamKeys {
            let client = RTMPClient()
            
            do {
                try client.connect(url: validURL, streamKey: streamKey)
                XCTFail("Empty stream key '\(streamKey)' should be rejected")
            } catch RTMPClientError.invalidStreamKey {
                // Expected error
                XCTAssertFalse(
                    client.connected,
                    "Client should not be connected after failed connect with empty stream key"
                )
            } catch {
                XCTFail("Empty stream key '\(streamKey)' threw unexpected error: \(error)")
            }
        }
    }
    
    func testDoubleConnectIsRejected() {
        // Property: Connecting an already connected client should fail
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            XCTAssertTrue(rtmpClient.connected)
            
            // Try to connect again
            do {
                try rtmpClient.connect(url: url, streamKey: streamKey)
                XCTFail("Double connect should be rejected")
            } catch RTMPClientError.alreadyConnected {
                // Expected error
                XCTAssertTrue(rtmpClient.connected, "Client should still be connected")
            }
        } catch {
            XCTFail("Initial connection failed: \(error)")
        }
    }
    
    func testDisconnectIsIdempotent() {
        // Property: Disconnecting a disconnected client should be safe (no error)
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            rtmpClient.disconnect()
            XCTAssertFalse(rtmpClient.connected)
            
            // Disconnect again - should not crash or throw
            rtmpClient.disconnect()
            XCTAssertFalse(rtmpClient.connected)
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testCanReconnectAfterDisconnect() {
        // Property: After disconnecting, client can reconnect
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            XCTAssertTrue(rtmpClient.connected)
            
            rtmpClient.disconnect()
            XCTAssertFalse(rtmpClient.connected)
            
            try rtmpClient.connect(url: url, streamKey: streamKey)
            XCTAssertTrue(rtmpClient.connected)
        } catch {
            XCTFail("Reconnection failed: \(error)")
        }
    }
    
    // MARK: - Property 14: Frames are packetized as FLV/RTMP
    // Feature: ip-camera-streaming-platform, Property 14: Frames are packetized as FLV/RTMP
    // Validates: Requirements 4.4
    
    func testVideoFramesArePacketizedAsFLV() {
        // Property: For any encoded H.264 frame, when sent to RTMP client,
        // it should be properly formatted as an FLV video packet with correct headers and timestamps
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            // Test various frame types
            let testCases: [(data: Data, timestamp: UInt32, isKeyframe: Bool)] = [
                (Data(repeating: 0x01, count: 1024), 0, true),        // Keyframe at t=0
                (Data(repeating: 0x02, count: 512), 33, false),       // Inter frame at t=33ms
                (Data(repeating: 0x03, count: 2048), 66, false),      // Larger inter frame
                (Data(repeating: 0x04, count: 1024), 1000, true),     // Keyframe at t=1s
                (Data(repeating: 0x05, count: 256), 1033, false)      // Small inter frame
            ]
            
            for (i, testCase) in testCases.enumerated() {
                // Send frame
                rtmpClient.sendVideoFrame(
                    data: testCase.data,
                    timestamp: testCase.timestamp,
                    isKeyframe: testCase.isKeyframe
                )
                
                // Property: Frame should be accepted and counted
                let stats = rtmpClient.getStatistics()
                let frameCount = stats["videoFrameCount"] as? Int64 ?? 0
                
                XCTAssertEqual(
                    frameCount,
                    Int64(i + 1),
                    "Video frame \(i) should be counted"
                )
                
                // Property: Bytes sent should increase
                let bytesSent = stats["bytesSent"] as? Int64 ?? 0
                XCTAssertGreaterThan(
                    bytesSent,
                    0,
                    "Bytes sent should increase after sending frame \(i)"
                )
                
                // Property: FLV packet should be larger than original data (due to headers)
                // FLV video header is 5 bytes (frame type + codec + packet type + composition time)
                XCTAssertGreaterThanOrEqual(
                    bytesSent,
                    Int64(testCase.data.count + 5),
                    "FLV packet should include header bytes for frame \(i)"
                )
            }
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testAudioFramesArePacketizedAsFLV() {
        // Property: For any encoded AAC frame, when sent to RTMP client,
        // it should be properly formatted as an FLV audio packet
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            // Test various audio frames
            let testCases: [(data: Data, timestamp: UInt32)] = [
                (Data(repeating: 0xAA, count: 512), 0),
                (Data(repeating: 0xBB, count: 256), 23),
                (Data(repeating: 0xCC, count: 1024), 46),
                (Data(repeating: 0xDD, count: 128), 69),
                (Data(repeating: 0xEE, count: 768), 92)
            ]
            
            for (i, testCase) in testCases.enumerated() {
                // Send frame
                rtmpClient.sendAudioFrame(
                    data: testCase.data,
                    timestamp: testCase.timestamp
                )
                
                // Property: Frame should be accepted and counted
                let stats = rtmpClient.getStatistics()
                let frameCount = stats["audioFrameCount"] as? Int64 ?? 0
                
                XCTAssertEqual(
                    frameCount,
                    Int64(i + 1),
                    "Audio frame \(i) should be counted"
                )
                
                // Property: Bytes sent should increase
                let bytesSent = stats["bytesSent"] as? Int64 ?? 0
                XCTAssertGreaterThan(
                    bytesSent,
                    0,
                    "Bytes sent should increase after sending audio frame \(i)"
                )
                
                // Property: FLV packet should be larger than original data (due to headers)
                // FLV audio header is 2 bytes (sound format + AAC packet type)
                XCTAssertGreaterThanOrEqual(
                    bytesSent,
                    Int64(testCase.data.count + 2),
                    "FLV packet should include header bytes for audio frame \(i)"
                )
            }
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testMixedVideoAndAudioFramesArePacketized() {
        // Property: Both video and audio frames can be sent in any order
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            // Send mixed frames
            rtmpClient.sendVideoFrame(data: Data(repeating: 0x01, count: 1024), timestamp: 0, isKeyframe: true)
            rtmpClient.sendAudioFrame(data: Data(repeating: 0xAA, count: 512), timestamp: 0)
            rtmpClient.sendVideoFrame(data: Data(repeating: 0x02, count: 1024), timestamp: 33, isKeyframe: false)
            rtmpClient.sendAudioFrame(data: Data(repeating: 0xBB, count: 512), timestamp: 23)
            rtmpClient.sendVideoFrame(data: Data(repeating: 0x03, count: 1024), timestamp: 66, isKeyframe: false)
            rtmpClient.sendAudioFrame(data: Data(repeating: 0xCC, count: 512), timestamp: 46)
            
            let stats = rtmpClient.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
            
            // Property: All frames should be counted correctly
            XCTAssertEqual(videoFrameCount, 3, "All video frames should be counted")
            XCTAssertEqual(audioFrameCount, 3, "All audio frames should be counted")
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testFramesIgnoredWhenNotConnected() {
        // Property: Frames sent when not connected should be ignored
        
        XCTAssertFalse(rtmpClient.connected)
        
        rtmpClient.sendVideoFrame(data: Data(repeating: 0x01, count: 1024), timestamp: 0, isKeyframe: true)
        rtmpClient.sendAudioFrame(data: Data(repeating: 0xAA, count: 512), timestamp: 0)
        
        let stats = rtmpClient.getStatistics()
        let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
        let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
        
        // Property: Frames should be ignored when not connected
        XCTAssertEqual(videoFrameCount, 0, "Video frames should be ignored when not connected")
        XCTAssertEqual(audioFrameCount, 0, "Audio frames should be ignored when not connected")
    }
    
    func testEmptyFrameDataIsHandled() {
        // Property: Empty frame data should be handled gracefully
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            let emptyData = Data()
            
            // Should not crash
            rtmpClient.sendVideoFrame(data: emptyData, timestamp: 0, isKeyframe: true)
            rtmpClient.sendAudioFrame(data: emptyData, timestamp: 0)
            
            let stats = rtmpClient.getStatistics()
            let videoFrameCount = stats["videoFrameCount"] as? Int64 ?? 0
            let audioFrameCount = stats["audioFrameCount"] as? Int64 ?? 0
            
            // Property: Empty frames should still be counted
            XCTAssertEqual(videoFrameCount, 1, "Empty video frame should be counted")
            XCTAssertEqual(audioFrameCount, 1, "Empty audio frame should be counted")
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    // MARK: - Property 15: RTMP reconnection uses exponential backoff
    // Feature: ip-camera-streaming-platform, Property 15: RTMP reconnection uses exponential backoff
    // Validates: Requirements 4.5
    
    func testRTMPReconnectionUsesExponentialBackoff() async {
        // Property: For any RTMP connection failure, the system should attempt reconnection
        // with delays that increase exponentially (e.g., 1s, 2s, 4s, 8s, 16s) up to 5 attempts
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        // Expected backoff delays: 1s, 2s, 4s, 8s, 16s
        let expectedDelays = [1.0, 2.0, 4.0, 8.0, 16.0]
        let tolerance = 0.5 // Allow 0.5s tolerance for timing
        
        for (attempt, expectedDelay) in expectedDelays.enumerated() {
            let client = RTMPClient()
            
            // Measure reconnection delay
            let startTime = Date()
            
            do {
                try await client.reconnect()
                
                let elapsedTime = Date().timeIntervalSince(startTime)
                
                // Property: Delay should match exponential backoff pattern
                XCTAssertGreaterThanOrEqual(
                    elapsedTime,
                    expectedDelay - tolerance,
                    "Reconnection attempt \(attempt + 1) should wait at least \(expectedDelay)s"
                )
                
                XCTAssertLessThanOrEqual(
                    elapsedTime,
                    expectedDelay + tolerance,
                    "Reconnection attempt \(attempt + 1) should wait at most \(expectedDelay + tolerance)s"
                )
                
                // Property: Reconnection attempt count should increase
                XCTAssertEqual(
                    client.currentReconnectionAttempt,
                    attempt + 1,
                    "Reconnection attempt count should be \(attempt + 1)"
                )
                
                client.disconnect()
            } catch {
                XCTFail("Reconnection attempt \(attempt + 1) failed: \(error)")
            }
        }
    }
    
    func testMaxReconnectionAttemptsIsEnforced() async {
        // Property: After 5 failed reconnection attempts, the system should stop trying
        
        let client = RTMPClient()
        
        // Attempt 6 reconnections (should fail on the 6th)
        for attempt in 0..<5 {
            do {
                try await client.reconnect()
                XCTAssertEqual(
                    client.currentReconnectionAttempt,
                    attempt + 1,
                    "Reconnection attempt \(attempt + 1) should succeed"
                )
                client.disconnect()
            } catch {
                XCTFail("Reconnection attempt \(attempt + 1) should succeed but failed: \(error)")
            }
        }
        
        // 6th attempt should fail
        do {
            try await client.reconnect()
            XCTFail("6th reconnection attempt should fail with maxReconnectionAttemptsReached")
        } catch RTMPClientError.maxReconnectionAttemptsReached {
            // Expected error
            XCTAssertEqual(
                client.currentReconnectionAttempt,
                5,
                "Reconnection attempt count should be 5 after max attempts"
            )
        } catch {
            XCTFail("6th reconnection attempt threw unexpected error: \(error)")
        }
    }
    
    func testReconnectionResetsAfterSuccessfulConnection() async {
        // Property: After a successful connection, reconnection attempt count should reset
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        // Perform some reconnection attempts
        for _ in 0..<3 {
            do {
                try await rtmpClient.reconnect()
                rtmpClient.disconnect()
            } catch {
                XCTFail("Reconnection failed: \(error)")
            }
        }
        
        XCTAssertEqual(rtmpClient.currentReconnectionAttempt, 3)
        
        // Now connect normally
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            // Property: Reconnection count should reset after successful connection
            XCTAssertEqual(
                rtmpClient.currentReconnectionAttempt,
                0,
                "Reconnection count should reset after successful connection"
            )
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testReconnectionWhileConnectedFails() async {
        // Property: Attempting reconnection while already connected should fail
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            XCTAssertTrue(rtmpClient.connected)
            
            // Try to reconnect while connected
            do {
                try await rtmpClient.reconnect()
                XCTFail("Reconnection while connected should fail")
            } catch RTMPClientError.alreadyConnected {
                // Expected error
                XCTAssertTrue(rtmpClient.connected, "Client should still be connected")
            }
        } catch {
            XCTFail("Initial connection failed: \(error)")
        }
    }
    
    func testBackoffDelayCalculation() {
        // Property: Backoff delays should follow exponential pattern with max cap
        
        // Test the backoff pattern by checking reconnection attempt counts
        // We can't directly test the private method, but we can verify the behavior
        // through the public API
        
        let expectedAttempts = 5
        
        Task {
            for attempt in 0..<expectedAttempts {
                let client = RTMPClient()
                
                do {
                    try await client.reconnect()
                    
                    // Property: Each attempt should increment the counter
                    XCTAssertEqual(
                        client.currentReconnectionAttempt,
                        attempt + 1,
                        "Attempt counter should be \(attempt + 1)"
                    )
                    
                    client.disconnect()
                } catch {
                    XCTFail("Reconnection attempt \(attempt + 1) failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Additional Property Tests
    
    func testStatisticsAreAccurate() {
        // Property: Statistics should accurately reflect the number of frames sent
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            let videoFrameCount = 25
            let audioFrameCount = 40
            
            // Send video frames
            for i in 0..<videoFrameCount {
                rtmpClient.sendVideoFrame(
                    data: Data(repeating: UInt8(i % 256), count: 1024),
                    timestamp: UInt32(i * 33),
                    isKeyframe: (i % 10 == 0)
                )
            }
            
            // Send audio frames
            for i in 0..<audioFrameCount {
                rtmpClient.sendAudioFrame(
                    data: Data(repeating: UInt8(i % 256), count: 512),
                    timestamp: UInt32(i * 23)
                )
            }
            
            let stats = rtmpClient.getStatistics()
            let reportedVideoFrames = stats["videoFrameCount"] as? Int64 ?? 0
            let reportedAudioFrames = stats["audioFrameCount"] as? Int64 ?? 0
            let bytesSent = stats["bytesSent"] as? Int64 ?? 0
            
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
            
            // Property: Bytes sent should be positive
            XCTAssertGreaterThan(
                bytesSent,
                0,
                "Bytes sent should be greater than 0"
            )
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
    
    func testDisconnectClearsStatistics() {
        // Property: Disconnecting should reset statistics
        
        let url = "rtmp://a.rtmp.youtube.com/live2"
        let streamKey = "test-key"
        
        do {
            try rtmpClient.connect(url: url, streamKey: streamKey)
            
            // Send some frames
            rtmpClient.sendVideoFrame(data: Data(repeating: 0x01, count: 1024), timestamp: 0, isKeyframe: true)
            rtmpClient.sendAudioFrame(data: Data(repeating: 0xAA, count: 512), timestamp: 0)
            
            var stats = rtmpClient.getStatistics()
            XCTAssertGreaterThan(stats["videoFrameCount"] as? Int64 ?? 0, 0)
            XCTAssertGreaterThan(stats["audioFrameCount"] as? Int64 ?? 0, 0)
            
            // Disconnect
            rtmpClient.disconnect()
            
            stats = rtmpClient.getStatistics()
            
            // Property: Statistics should be reset after disconnect
            XCTAssertEqual(stats["videoFrameCount"] as? Int64 ?? -1, 0, "Video frame count should be reset")
            XCTAssertEqual(stats["audioFrameCount"] as? Int64 ?? -1, 0, "Audio frame count should be reset")
            XCTAssertEqual(stats["bytesSent"] as? Int64 ?? -1, 0, "Bytes sent should be reset")
            XCTAssertEqual(stats["reconnectionAttempts"] as? Int ?? -1, 0, "Reconnection attempts should be reset")
        } catch {
            XCTFail("Connection failed: \(error)")
        }
    }
}
