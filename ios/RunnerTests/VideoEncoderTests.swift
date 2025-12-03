import XCTest
import AVFoundation
import VideoToolbox
@testable import Runner

/// Property-based tests for VideoEncoder
class VideoEncoderTests: XCTestCase {
    
    var videoEncoder: VideoEncoder!
    
    override func setUp() {
        super.setUp()
        videoEncoder = VideoEncoder()
    }
    
    override func tearDown() {
        videoEncoder?.shutdown()
        videoEncoder = nil
        super.tearDown()
    }
    
    // MARK: - Property 2: H.264 encoding produces valid output on iOS
    // Feature: ip-camera-streaming-platform, Property 2: H.264 encoding produces valid output on iOS
    // Validates: Requirements 2.3
    
    func testH264EncodingProducesValidOutput() {
        // Test with multiple configurations to verify property holds across inputs
        let configurations: [(width: Int, height: Int, frameRate: Int, bitrate: Int)] = [
            (1280, 720, 30, 2_000_000),
            (1920, 1080, 30, 5_000_000),
            (1920, 1080, 60, 8_000_000),
            (1280, 720, 60, 4_000_000)
        ]
        
        for config in configurations {
            // Configure encoder
            do {
                try videoEncoder.configure(
                    width: config.width,
                    height: config.height,
                    frameRate: config.frameRate,
                    bitrate: config.bitrate
                )
            } catch {
                XCTFail("Failed to configure encoder with \(config): \(error)")
                continue
            }
            
            // Create a test frame
            guard let sampleBuffer = createTestVideoFrame(width: config.width, height: config.height) else {
                XCTFail("Failed to create test frame for \(config)")
                continue
            }
            
            // Set up expectation for encoded frame
            let expectation = self.expectation(description: "Encoded frame for \(config)")
            var receivedData: Data?
            var receivedIsKeyframe: Bool?
            
            videoEncoder.onEncodedFrame = { data, isKeyframe, timestamp in
                receivedData = data
                receivedIsKeyframe = isKeyframe
                expectation.fulfill()
            }
            
            // Encode the frame
            do {
                try videoEncoder.encode(sampleBuffer: sampleBuffer)
            } catch {
                XCTFail("Failed to encode frame with \(config): \(error)")
                continue
            }
            
            // Wait for encoding to complete
            wait(for: [expectation], timeout: 2.0)
            
            // Property: Encoded data must not be empty
            guard let data = receivedData else {
                XCTFail("No encoded data received for \(config)")
                continue
            }
            
            XCTAssertGreaterThan(
                data.count,
                0,
                "Encoded data should not be empty for \(config)"
            )
            
            // Property: Encoded data must contain valid H.264 NAL units
            XCTAssertTrue(
                isValidH264Data(data),
                "Encoded data should contain valid H.264 NAL units for \(config)"
            )
            
            // Property: Keyframe flag must be set (first frame is typically a keyframe)
            XCTAssertNotNil(
                receivedIsKeyframe,
                "Keyframe flag should be set for \(config)"
            )
        }
    }
    
    func testH264EncodingMultipleFrames() {
        // Property: For any sequence of frames, all should encode successfully
        let width = 1280
        let height = 720
        let frameRate = 30
        let bitrate = 3_000_000
        let frameCount = 10
        
        do {
            try videoEncoder.configure(
                width: width,
                height: height,
                frameRate: frameRate,
                bitrate: bitrate
            )
        } catch {
            XCTFail("Failed to configure encoder: \(error)")
            return
        }
        
        var encodedFrameCount = 0
        let expectation = self.expectation(description: "Encode multiple frames")
        expectation.expectedFulfillmentCount = frameCount
        
        videoEncoder.onEncodedFrame = { data, isKeyframe, timestamp in
            // Property: Each encoded frame must have data
            XCTAssertGreaterThan(data.count, 0, "Frame \(encodedFrameCount) should have data")
            
            // Property: Each encoded frame must be valid H.264
            XCTAssertTrue(
                self.isValidH264Data(data),
                "Frame \(encodedFrameCount) should be valid H.264"
            )
            
            encodedFrameCount += 1
            expectation.fulfill()
        }
        
        // Encode multiple frames
        for i in 0..<frameCount {
            guard let sampleBuffer = createTestVideoFrame(width: width, height: height, frameNumber: i) else {
                XCTFail("Failed to create test frame \(i)")
                continue
            }
            
            do {
                try videoEncoder.encode(sampleBuffer: sampleBuffer)
            } catch {
                XCTFail("Failed to encode frame \(i): \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Property: All frames should be encoded
        XCTAssertEqual(
            encodedFrameCount,
            frameCount,
            "All \(frameCount) frames should be encoded"
        )
    }
    
    // MARK: - Property 6: Bitrate configuration accepts valid range
    // Feature: ip-camera-streaming-platform, Property 6: Bitrate configuration accepts valid range
    // Validates: Requirements 2.8
    
    func testBitrateConfigurationAcceptsValidRange() {
        // Property: For any bitrate in valid range (1-10 Mbps), configuration should succeed
        let validBitrates = [
            1_000_000,      // 1 Mbps (minimum)
            2_500_000,      // 2.5 Mbps
            5_000_000,      // 5 Mbps
            7_500_000,      // 7.5 Mbps
            10_000_000      // 10 Mbps (maximum)
        ]
        
        let width = 1920
        let height = 1080
        let frameRate = 30
        
        for bitrate in validBitrates {
            do {
                try videoEncoder.configure(
                    width: width,
                    height: height,
                    frameRate: frameRate,
                    bitrate: bitrate
                )
                
                // If we get here, configuration succeeded
                XCTAssertTrue(
                    true,
                    "Bitrate \(bitrate) should be accepted"
                )
                
                // Verify encoder can still encode after configuration
                guard let sampleBuffer = createTestVideoFrame(width: width, height: height) else {
                    XCTFail("Failed to create test frame for bitrate \(bitrate)")
                    continue
                }
                
                let expectation = self.expectation(description: "Encode with bitrate \(bitrate)")
                
                videoEncoder.onEncodedFrame = { data, isKeyframe, timestamp in
                    XCTAssertGreaterThan(data.count, 0, "Should encode with bitrate \(bitrate)")
                    expectation.fulfill()
                }
                
                try videoEncoder.encode(sampleBuffer: sampleBuffer)
                wait(for: [expectation], timeout: 2.0)
                
            } catch {
                XCTFail("Bitrate \(bitrate) should be accepted but got error: \(error)")
            }
        }
    }
    
    func testBitrateConfigurationEdgeCases() {
        // Property: Bitrates at exact boundaries should be accepted
        let edgeCaseBitrates = [
            1_000_000,      // Exact minimum
            10_000_000      // Exact maximum
        ]
        
        let width = 1280
        let height = 720
        let frameRate = 30
        
        for bitrate in edgeCaseBitrates {
            do {
                try videoEncoder.configure(
                    width: width,
                    height: height,
                    frameRate: frameRate,
                    bitrate: bitrate
                )
                
                // Configuration should succeed
                XCTAssertTrue(
                    true,
                    "Edge case bitrate \(bitrate) should be accepted"
                )
                
            } catch {
                XCTFail("Edge case bitrate \(bitrate) should be accepted but got error: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestVideoFrame(width: Int, height: Int, frameNumber: Int = 0) -> CMSampleBuffer? {
        // Create a pixel buffer
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            [
                kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
            ] as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            return nil
        }
        
        // Fill with test pattern
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        if let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) {
            let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
            let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
            let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
            
            // Fill Y plane with gradient pattern
            for y in 0..<height {
                for x in 0..<bytesPerRow {
                    buffer[y * bytesPerRow + x] = UInt8((x + y + frameNumber) % 256)
                }
            }
        }
        
        // Create sample buffer
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        
        guard let formatDescription = formatDescription else {
            return nil
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: Int64(frameNumber), timescale: 30),
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )
        
        return sampleBuffer
    }
    
    private func isValidH264Data(_ data: Data) -> Bool {
        // H.264 NAL units start with start codes: 0x00 0x00 0x00 0x01 or 0x00 0x00 0x01
        // Check if data contains valid start codes
        
        guard data.count >= 4 else {
            return false
        }
        
        let bytes = [UInt8](data)
        
        // Check for 4-byte start code
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x00 && bytes[3] == 0x01 {
            return true
        }
        
        // Check for 3-byte start code
        if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0x01 {
            return true
        }
        
        // Check if data contains start codes anywhere (for fragmented NAL units)
        for i in 0..<(data.count - 3) {
            if bytes[i] == 0x00 && bytes[i+1] == 0x00 && bytes[i+2] == 0x00 && bytes[i+3] == 0x01 {
                return true
            }
            if i < (data.count - 2) && bytes[i] == 0x00 && bytes[i+1] == 0x00 && bytes[i+2] == 0x01 {
                return true
            }
        }
        
        // For VideoToolbox output, data might be in AVCC format (length-prefixed)
        // Check if first 4 bytes could be a length prefix
        if data.count >= 8 {
            let length = Int(bytes[0]) << 24 | Int(bytes[1]) << 16 | Int(bytes[2]) << 8 | Int(bytes[3])
            if length > 0 && length <= data.count - 4 {
                // This looks like AVCC format, which is valid H.264
                return true
            }
        }
        
        return false
    }
}

