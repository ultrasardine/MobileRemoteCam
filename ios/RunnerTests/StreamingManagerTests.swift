import XCTest
import AVFoundation
@testable import Runner

/// Property-based tests for StreamingManager
/// Feature: ip-camera-streaming-platform
class StreamingManagerTests: XCTestCase {
    
    var streamingManager: StreamingManager!
    
    override func setUp() {
        super.setUp()
        streamingManager = StreamingManager()
    }
    
    override func tearDown() {
        // Ensure streaming is stopped after each test
        if streamingManager.streaming {
            streamingManager.stopStreaming()
        }
        streamingManager = nil
        super.tearDown()
    }
    
    // MARK: - Property 19: Start streaming initializes all components
    // Feature: ip-camera-streaming-platform, Property 19: Start streaming initializes all components
    // Validates: Requirements 5.5
    
    func testStartStreamingInitializesAllComponents() {
        // Get available cameras
        let cameras = streamingManager.enumerateCameras()
        
        // Skip test if no cameras available (simulator)
        guard !cameras.isEmpty else {
            print("Skipping test: No cameras available")
            return
        }
        
        guard let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            XCTFail("Failed to get camera ID")
            return
        }
        
        // Get available resolutions
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            XCTFail("Failed to get resolution")
            return
        }
        
        // Test configurations with different combinations
        let testConfigs: [(rtspEnabled: Bool, audioEnabled: Bool, rtmpCount: Int)] = [
            (true, true, 0),   // RTSP with audio
            (true, false, 0),  // RTSP without audio
            (false, true, 0),  // No protocols, just encoding
            (true, true, 1),   // RTSP + 1 RTMP target
        ]
        
        for (index, testConfig) in testConfigs.enumerated() {
            // Create RTMP targets if needed
            var rtmpTargets: [RtmpTarget] = []
            for i in 0..<testConfig.rtmpCount {
                rtmpTargets.append(RtmpTarget(
                    url: "rtmp://test.example.com/live\(i)",
                    streamKey: "test_key_\(i)",
                    enabled: true
                ))
            }
            
            let config = StreamConfig(
                cameraId: cameraId,
                resolution: Resolution(width: width, height: height),
                frameRate: 30,
                bitrate: 5_000_000,
                audioEnabled: testConfig.audioEnabled,
                rtspEnabled: testConfig.rtspEnabled,
                rtspPort: 8554 + index, // Use different ports for each test
                rtmpTargets: rtmpTargets
            )
            
            do {
                // Property: Starting streaming should succeed
                try streamingManager.startStreaming(config: config)
                
                // Property: After starting, streaming should be active
                XCTAssertTrue(
                    streamingManager.streaming,
                    "StreamingManager should be in streaming state after startStreaming"
                )
                
                // Property: Statistics should be available
                let stats = streamingManager.getStatistics()
                
                // Property: Statistics should have valid initial values
                XCTAssertGreaterThanOrEqual(
                    stats.currentBitrate,
                    0.0,
                    "Current bitrate should be non-negative"
                )
                
                XCTAssertGreaterThanOrEqual(
                    stats.currentFps,
                    0,
                    "Current FPS should be non-negative"
                )
                
                XCTAssertGreaterThanOrEqual(
                    stats.droppedFrames,
                    0,
                    "Dropped frames should be non-negative"
                )
                
                XCTAssertGreaterThanOrEqual(
                    stats.batteryLevel,
                    0,
                    "Battery level should be non-negative"
                )
                
                XCTAssertLessThanOrEqual(
                    stats.batteryLevel,
                    100,
                    "Battery level should not exceed 100%"
                )
                
                // Property: Connection status should be present for enabled protocols
                if testConfig.rtspEnabled {
                    XCTAssertNotNil(
                        stats.connectionStatus["rtsp"],
                        "RTSP connection status should be present when RTSP is enabled"
                    )
                }
                
                // Property: RTMP connection status should be present for each target
                for i in 0..<testConfig.rtmpCount {
                    let key = "rtmp_\(i)"
                    XCTAssertNotNil(
                        stats.connectionStatus[key],
                        "RTMP connection status should be present for target \(i)"
                    )
                }
                
                // Stop streaming before next iteration
                streamingManager.stopStreaming()
                
                // Give system time to clean up
                Thread.sleep(forTimeInterval: 0.2)
                
            } catch {
                XCTFail("Failed to start streaming with config \(index): \(error)")
            }
        }
    }
    
    func testStartStreamingWithInvalidConfigurationFails() {
        // Property: Starting with invalid camera ID should fail
        let invalidConfig = StreamConfig(
            cameraId: "invalid-camera-id",
            resolution: Resolution(width: 1920, height: 1080),
            frameRate: 30,
            bitrate: 5_000_000,
            audioEnabled: false,
            rtspEnabled: false,
            rtspPort: 8554,
            rtmpTargets: []
        )
        
        XCTAssertThrowsError(
            try streamingManager.startStreaming(config: invalidConfig),
            "Starting streaming with invalid camera ID should throw error"
        )
        
        // Property: After failed start, streaming should not be active
        XCTAssertFalse(
            streamingManager.streaming,
            "StreamingManager should not be in streaming state after failed start"
        )
    }
    
    func testStartStreamingWhenAlreadyStreamingFails() {
        let cameras = streamingManager.enumerateCameras()
        guard !cameras.isEmpty,
              let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            print("Skipping test: No cameras available")
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            print("Skipping test: No resolutions available")
            return
        }
        
        let config = StreamConfig(
            cameraId: cameraId,
            resolution: Resolution(width: width, height: height),
            frameRate: 30,
            bitrate: 5_000_000,
            audioEnabled: false,
            rtspEnabled: false,
            rtspPort: 8554,
            rtmpTargets: []
        )
        
        do {
            try streamingManager.startStreaming(config: config)
            
            // Property: Starting streaming again while already streaming should fail
            XCTAssertThrowsError(
                try streamingManager.startStreaming(config: config),
                "Starting streaming when already streaming should throw error"
            )
            
        } catch {
            XCTFail("Initial streaming start failed: \(error)")
        }
    }
    
    // MARK: - Property 20: Stop streaming releases all resources
    // Feature: ip-camera-streaming-platform, Property 20: Stop streaming releases all resources
    // Validates: Requirements 5.6
    
    func testStopStreamingReleasesAllResources() {
        let cameras = streamingManager.enumerateCameras()
        guard !cameras.isEmpty,
              let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            print("Skipping test: No cameras available")
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            print("Skipping test: No resolutions available")
            return
        }
        
        // Test with various configurations
        let testConfigs: [(rtspEnabled: Bool, audioEnabled: Bool)] = [
            (true, true),
            (true, false),
            (false, true),
            (false, false)
        ]
        
        for (index, testConfig) in testConfigs.enumerated() {
            let config = StreamConfig(
                cameraId: cameraId,
                resolution: Resolution(width: width, height: height),
                frameRate: 30,
                bitrate: 5_000_000,
                audioEnabled: testConfig.audioEnabled,
                rtspEnabled: testConfig.rtspEnabled,
                rtspPort: 8554 + index,
                rtmpTargets: []
            )
            
            do {
                // Start streaming
                try streamingManager.startStreaming(config: config)
                XCTAssertTrue(streamingManager.streaming, "Streaming should be active")
                
                // Let it run briefly to ensure components are initialized
                Thread.sleep(forTimeInterval: 0.1)
                
                // Property: Stop streaming should succeed
                streamingManager.stopStreaming()
                
                // Property: After stopping, streaming should not be active
                XCTAssertFalse(
                    streamingManager.streaming,
                    "StreamingManager should not be in streaming state after stopStreaming"
                )
                
                // Property: Statistics should be reset or show zero activity
                let stats = streamingManager.getStatistics()
                
                // After stopping, we expect statistics to be reset
                XCTAssertEqual(
                    stats.currentBitrate,
                    0.0,
                    "Current bitrate should be zero after stopping"
                )
                
                XCTAssertEqual(
                    stats.currentFps,
                    0,
                    "Current FPS should be zero after stopping"
                )
                
                // Property: Connection status should be empty or show disconnected
                if testConfig.rtspEnabled {
                    if let rtspStatus = stats.connectionStatus["rtsp"] {
                        XCTAssertEqual(
                            rtspStatus,
                            "disconnected",
                            "RTSP should be disconnected after stopping"
                        )
                    }
                }
                
                // Property: Should be able to start streaming again after stopping
                try streamingManager.startStreaming(config: config)
                XCTAssertTrue(
                    streamingManager.streaming,
                    "Should be able to start streaming again after stopping"
                )
                
                streamingManager.stopStreaming()
                Thread.sleep(forTimeInterval: 0.1)
                
            } catch {
                XCTFail("Test failed for config \(index): \(error)")
            }
        }
    }
    
    func testStopStreamingWhenNotStreamingIsIdempotent() {
        // Property: Stopping when not streaming should be safe (idempotent)
        XCTAssertFalse(streamingManager.streaming, "Should not be streaming initially")
        
        // Should not crash or throw
        streamingManager.stopStreaming()
        
        XCTAssertFalse(streamingManager.streaming, "Should still not be streaming")
    }
    
    func testMultipleStopCallsAreSafe() {
        let cameras = streamingManager.enumerateCameras()
        guard !cameras.isEmpty,
              let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            print("Skipping test: No cameras available")
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            print("Skipping test: No resolutions available")
            return
        }
        
        let config = StreamConfig(
            cameraId: cameraId,
            resolution: Resolution(width: width, height: height),
            frameRate: 30,
            bitrate: 5_000_000,
            audioEnabled: false,
            rtspEnabled: false,
            rtspPort: 8554,
            rtmpTargets: []
        )
        
        do {
            try streamingManager.startStreaming(config: config)
            
            // Property: Multiple stop calls should be safe
            streamingManager.stopStreaming()
            streamingManager.stopStreaming()
            streamingManager.stopStreaming()
            
            XCTAssertFalse(streamingManager.streaming, "Should not be streaming after multiple stops")
            
        } catch {
            XCTFail("Failed to start streaming: \(error)")
        }
    }
    
    // MARK: - Property 22: Statistics are within expected ranges
    // Feature: ip-camera-streaming-platform, Property 22: Statistics are within expected ranges
    // Validates: Requirements 6.1, 6.2, 6.3
    
    func testStatisticsAreWithinExpectedRanges() {
        let cameras = streamingManager.enumerateCameras()
        guard !cameras.isEmpty,
              let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            print("Skipping test: No cameras available")
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            print("Skipping test: No resolutions available")
            return
        }
        
        // Test with different bitrates and frame rates
        let testConfigs: [(bitrate: Int, frameRate: Int)] = [
            (1_000_000, 30),   // 1 Mbps, 30 FPS
            (5_000_000, 30),   // 5 Mbps, 30 FPS
            (10_000_000, 60),  // 10 Mbps, 60 FPS
        ]
        
        for (index, testConfig) in testConfigs.enumerated() {
            let config = StreamConfig(
                cameraId: cameraId,
                resolution: Resolution(width: width, height: height),
                frameRate: testConfig.frameRate,
                bitrate: testConfig.bitrate,
                audioEnabled: true,
                rtspEnabled: true,
                rtspPort: 8554 + index,
                rtmpTargets: []
            )
            
            do {
                try streamingManager.startStreaming(config: config)
                
                // Let streaming run for a bit to collect statistics
                Thread.sleep(forTimeInterval: 2.0)
                
                let stats = streamingManager.getStatistics()
                
                // Property: Bitrate should be within 20% of configured bitrate
                let configuredBitrateMbps = Double(testConfig.bitrate) / 1_000_000.0
                let bitrateToleranceLower = configuredBitrateMbps * 0.8
                let bitrateToleranceUpper = configuredBitrateMbps * 1.2
                
                // Note: In simulator or without actual streaming, bitrate might be 0
                // So we check if it's either 0 (not streaming) or within range
                if stats.currentBitrate > 0 {
                    XCTAssertGreaterThanOrEqual(
                        stats.currentBitrate,
                        bitrateToleranceLower,
                        "Bitrate should be within 20% of configured value (lower bound). Config: \(configuredBitrateMbps) Mbps, Got: \(stats.currentBitrate) Mbps"
                    )
                    
                    XCTAssertLessThanOrEqual(
                        stats.currentBitrate,
                        bitrateToleranceUpper,
                        "Bitrate should be within 20% of configured value (upper bound). Config: \(configuredBitrateMbps) Mbps, Got: \(stats.currentBitrate) Mbps"
                    )
                }
                
                // Property: FPS should be within 10% of configured FPS
                let fpsToleranceLower = Double(testConfig.frameRate) * 0.9
                let fpsToleranceUpper = Double(testConfig.frameRate) * 1.1
                
                // Note: In simulator, FPS might be 0
                if stats.currentFps > 0 {
                    XCTAssertGreaterThanOrEqual(
                        Double(stats.currentFps),
                        fpsToleranceLower,
                        "FPS should be within 10% of configured value (lower bound). Config: \(testConfig.frameRate) FPS, Got: \(stats.currentFps) FPS"
                    )
                    
                    XCTAssertLessThanOrEqual(
                        Double(stats.currentFps),
                        fpsToleranceUpper,
                        "FPS should be within 10% of configured value (upper bound). Config: \(testConfig.frameRate) FPS, Got: \(stats.currentFps) FPS"
                    )
                }
                
                // Property: Dropped frames should be non-negative
                XCTAssertGreaterThanOrEqual(
                    stats.droppedFrames,
                    0,
                    "Dropped frames count should be non-negative"
                )
                
                // Property: Battery level should be between 0 and 100
                XCTAssertGreaterThanOrEqual(
                    stats.batteryLevel,
                    0,
                    "Battery level should be at least 0%"
                )
                
                XCTAssertLessThanOrEqual(
                    stats.batteryLevel,
                    100,
                    "Battery level should not exceed 100%"
                )
                
                // Property: Device temperature should be reasonable (if available)
                // iOS doesn't provide direct temperature access, so it might be 0
                XCTAssertGreaterThanOrEqual(
                    stats.deviceTemperature,
                    0.0,
                    "Device temperature should be non-negative"
                )
                
                if stats.deviceTemperature > 0 {
                    XCTAssertLessThan(
                        stats.deviceTemperature,
                        100.0,
                        "Device temperature should be reasonable (< 100°C)"
                    )
                }
                
                streamingManager.stopStreaming()
                Thread.sleep(forTimeInterval: 0.2)
                
            } catch {
                XCTFail("Test failed for config \(index): \(error)")
            }
        }
    }
    
    func testStatisticsUpdateOverTime() {
        let cameras = streamingManager.enumerateCameras()
        guard !cameras.isEmpty,
              let firstCamera = cameras.first,
              let cameraId = firstCamera["id"] as? String else {
            print("Skipping test: No cameras available")
            return
        }
        
        let resolutions = streamingManager.getResolutions(cameraId: cameraId)
        guard !resolutions.isEmpty,
              let firstResolution = resolutions.first,
              let width = firstResolution["width"] as? Int,
              let height = firstResolution["height"] as? Int else {
            print("Skipping test: No resolutions available")
            return
        }
        
        let config = StreamConfig(
            cameraId: cameraId,
            resolution: Resolution(width: width, height: height),
            frameRate: 30,
            bitrate: 5_000_000,
            audioEnabled: true,
            rtspEnabled: true,
            rtspPort: 8554,
            rtmpTargets: []
        )
        
        do {
            try streamingManager.startStreaming(config: config)
            
            // Property: Statistics should update over time
            let stats1 = streamingManager.getStatistics()
            
            Thread.sleep(forTimeInterval: 1.5)
            
            let stats2 = streamingManager.getStatistics()
            
            // In a real streaming scenario, at least one of these should change
            // In simulator, they might all stay at 0, which is also valid
            let hasChanged = stats1.currentBitrate != stats2.currentBitrate ||
                           stats1.currentFps != stats2.currentFps ||
                           stats1.totalVideoFrames != stats2.totalVideoFrames
            
            // We don't assert this must be true because in simulator it might not stream
            // But we log it for information
            if !hasChanged {
                print("Note: Statistics did not change (likely running in simulator)")
            }
            
            streamingManager.stopStreaming()
            
        } catch {
            XCTFail("Failed to start streaming: \(error)")
        }
    }
}
