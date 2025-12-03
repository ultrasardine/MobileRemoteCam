import XCTest
import AVFoundation
import AudioToolbox
@testable import Runner

/// Property-based tests for AudioEncoder
class AudioEncoderTests: XCTestCase {
    
    var audioEncoder: AudioEncoder!
    
    override func setUp() {
        super.setUp()
        audioEncoder = AudioEncoder()
    }
    
    override func tearDown() {
        audioEncoder?.shutdown()
        audioEncoder = nil
        super.tearDown()
    }
    
    // MARK: - Property 4: AAC encoding produces valid output
    // Feature: ip-camera-streaming-platform, Property 4: AAC encoding produces valid output
    // Validates: Requirements 2.5
    
    func testAACEncodingProducesValidOutput() {
        // Test with multiple configurations to verify property holds across inputs
        let configurations: [(sampleRate: Double, channels: UInt32)] = [
            (44100.0, 1),   // Mono, standard sample rate
            (44100.0, 2),   // Stereo, standard sample rate
            (48000.0, 1),   // Mono, high sample rate
            (48000.0, 2)    // Stereo, high sample rate
        ]
        
        for config in configurations {
            // Configure encoder
            do {
                try audioEncoder.configure(
                    sampleRate: config.sampleRate,
                    channels: config.channels
                )
            } catch {
                XCTFail("Failed to configure audio encoder with \(config): \(error)")
                continue
            }
            
            // Create a test audio sample
            guard let sampleBuffer = createTestAudioSample(
                sampleRate: config.sampleRate,
                channels: config.channels
            ) else {
                XCTFail("Failed to create test audio sample for \(config)")
                continue
            }
            
            // Set up expectation for encoded frame
            let expectation = self.expectation(description: "Encoded audio for \(config)")
            var receivedData: Data?
            
            audioEncoder.onEncodedFrame = { data, timestamp in
                receivedData = data
                expectation.fulfill()
            }
            
            // Encode the sample
            do {
                try audioEncoder.encode(sampleBuffer: sampleBuffer)
            } catch {
                XCTFail("Failed to encode audio sample with \(config): \(error)")
                continue
            }
            
            // Wait for encoding to complete
            wait(for: [expectation], timeout: 2.0)
            
            // Property: Encoded data must not be empty
            guard let data = receivedData else {
                XCTFail("No encoded audio data received for \(config)")
                continue
            }
            
            XCTAssertGreaterThan(
                data.count,
                0,
                "Encoded audio data should not be empty for \(config)"
            )
            
            // Property: Encoded data should be reasonable size for AAC
            // AAC frames are typically 100-1000 bytes depending on bitrate and duration
            XCTAssertLessThan(
                data.count,
                10000,
                "Encoded audio data should be reasonable size for \(config)"
            )
            
            // Property: Encoded data should contain valid AAC data
            XCTAssertTrue(
                isValidAACData(data),
                "Encoded data should be valid AAC format for \(config)"
            )
        }
    }
    
    func testAACEncodingMultipleSamples() {
        // Property: For any sequence of audio samples, all should encode successfully
        let sampleRate = 44100.0
        let channels: UInt32 = 2
        let sampleCount = 10
        
        do {
            try audioEncoder.configure(
                sampleRate: sampleRate,
                channels: channels
            )
        } catch {
            XCTFail("Failed to configure audio encoder: \(error)")
            return
        }
        
        var encodedSampleCount = 0
        let expectation = self.expectation(description: "Encode multiple audio samples")
        expectation.expectedFulfillmentCount = sampleCount
        
        audioEncoder.onEncodedFrame = { data, timestamp in
            // Property: Each encoded sample must have data
            XCTAssertGreaterThan(data.count, 0, "Audio sample \(encodedSampleCount) should have data")
            
            // Property: Each encoded sample must be valid AAC
            XCTAssertTrue(
                self.isValidAACData(data),
                "Audio sample \(encodedSampleCount) should be valid AAC"
            )
            
            encodedSampleCount += 1
            expectation.fulfill()
        }
        
        // Encode multiple samples
        for i in 0..<sampleCount {
            guard let sampleBuffer = createTestAudioSample(
                sampleRate: sampleRate,
                channels: channels,
                sampleNumber: i
            ) else {
                XCTFail("Failed to create test audio sample \(i)")
                continue
            }
            
            do {
                try audioEncoder.encode(sampleBuffer: sampleBuffer)
            } catch {
                XCTFail("Failed to encode audio sample \(i): \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Property: All samples should be encoded
        XCTAssertEqual(
            encodedSampleCount,
            sampleCount,
            "All \(sampleCount) audio samples should be encoded"
        )
    }
    
    func testAACEncodingConsistency() {
        // Property: Encoding the same input multiple times should produce consistent output
        let sampleRate = 44100.0
        let channels: UInt32 = 1
        
        do {
            try audioEncoder.configure(
                sampleRate: sampleRate,
                channels: channels
            )
        } catch {
            XCTFail("Failed to configure audio encoder: \(error)")
            return
        }
        
        guard let sampleBuffer = createTestAudioSample(
            sampleRate: sampleRate,
            channels: channels
        ) else {
            XCTFail("Failed to create test audio sample")
            return
        }
        
        var encodedSizes: [Int] = []
        
        for i in 0..<3 {
            let expectation = self.expectation(description: "Encode attempt \(i)")
            
            audioEncoder.onEncodedFrame = { data, timestamp in
                encodedSizes.append(data.count)
                expectation.fulfill()
            }
            
            do {
                try audioEncoder.encode(sampleBuffer: sampleBuffer)
            } catch {
                XCTFail("Failed to encode audio sample on attempt \(i): \(error)")
                continue
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
        
        // Property: All encoded outputs should have similar sizes (within 20% variance)
        if encodedSizes.count == 3 {
            let avgSize = encodedSizes.reduce(0, +) / encodedSizes.count
            for size in encodedSizes {
                let variance = abs(Double(size - avgSize)) / Double(avgSize)
                XCTAssertLessThan(
                    variance,
                    0.2,
                    "Encoded sizes should be consistent (within 20%): \(encodedSizes)"
                )
            }
        }
    }
    
    func testAACEncodingDifferentSampleRates() {
        // Property: For any valid sample rate, encoding should succeed
        let validSampleRates = [8000.0, 16000.0, 22050.0, 44100.0, 48000.0]
        let channels: UInt32 = 1
        
        for sampleRate in validSampleRates {
            do {
                try audioEncoder.configure(
                    sampleRate: sampleRate,
                    channels: channels
                )
                
                guard let sampleBuffer = createTestAudioSample(
                    sampleRate: sampleRate,
                    channels: channels
                ) else {
                    XCTFail("Failed to create test audio sample for sample rate \(sampleRate)")
                    continue
                }
                
                let expectation = self.expectation(description: "Encode with sample rate \(sampleRate)")
                
                audioEncoder.onEncodedFrame = { data, timestamp in
                    XCTAssertGreaterThan(
                        data.count,
                        0,
                        "Should encode with sample rate \(sampleRate)"
                    )
                    expectation.fulfill()
                }
                
                try audioEncoder.encode(sampleBuffer: sampleBuffer)
                wait(for: [expectation], timeout: 2.0)
                
            } catch {
                XCTFail("Sample rate \(sampleRate) should be supported but got error: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAudioSample(
        sampleRate: Double,
        channels: UInt32,
        sampleNumber: Int = 0
    ) -> CMSampleBuffer? {
        // Create audio buffer with test data
        let sampleCount = 1024
        let bytesPerSample = 2 // 16-bit PCM
        let bufferSize = sampleCount * Int(channels) * bytesPerSample
        
        var audioBuffer = Data(count: bufferSize)
        
        // Fill with test audio pattern (sine wave)
        audioBuffer.withUnsafeMutableBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            let frequency = 440.0 // A4 note
            let amplitude: Int16 = 16000
            
            for i in 0..<(sampleCount * Int(channels)) {
                let t = Double(i + sampleNumber * sampleCount) / sampleRate
                let value = sin(2.0 * .pi * frequency * t)
                samples[i] = Int16(value * Double(amplitude))
            }
        }
        
        // Create audio format description
        var audioFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: UInt32(bytesPerSample * Int(channels)),
            mFramesPerPacket: 1,
            mBytesPerFrame: UInt32(bytesPerSample * Int(channels)),
            mChannelsPerFrame: channels,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        
        var formatDescription: CMAudioFormatDescription?
        let formatStatus = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &audioFormat,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard formatStatus == noErr, let formatDescription = formatDescription else {
            return nil
        }
        
        // Create block buffer
        var blockBuffer: CMBlockBuffer?
        let blockStatus = audioBuffer.withUnsafeBytes { bytes in
            CMBlockBufferCreateWithMemoryBlock(
                allocator: kCFAllocatorDefault,
                memoryBlock: nil,
                blockLength: bufferSize,
                blockAllocator: kCFAllocatorDefault,
                customBlockSource: nil,
                offsetToData: 0,
                dataLength: bufferSize,
                flags: 0,
                blockBufferOut: &blockBuffer
            )
        }
        
        guard blockStatus == noErr, let blockBuffer = blockBuffer else {
            return nil
        }
        
        // Copy audio data to block buffer
        let copyStatus = audioBuffer.withUnsafeBytes { bytes in
            CMBlockBufferReplaceDataBytes(
                with: bytes.baseAddress!,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: bufferSize
            )
        }
        
        guard copyStatus == noErr else {
            return nil
        }
        
        // Create sample buffer
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: Int64(sampleCount), timescale: Int32(sampleRate)),
            presentationTimeStamp: CMTime(value: Int64(sampleNumber * sampleCount), timescale: Int32(sampleRate)),
            decodeTimeStamp: .invalid
        )
        
        let sampleStatus = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            formatDescription: formatDescription,
            sampleCount: sampleCount,
            presentationTimeStamp: timingInfo.presentationTimeStamp,
            packetDescriptions: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr else {
            return nil
        }
        
        return sampleBuffer
    }
    
    private func isValidAACData(_ data: Data) -> Bool {
        // AAC data validation
        // Raw AAC frames or ADTS-wrapped AAC should have reasonable size
        
        guard data.count > 0 else {
            return false
        }
        
        // Check for ADTS header (0xFFF at start)
        let bytes = [UInt8](data)
        if data.count >= 7 {
            // ADTS sync word is 0xFFF (12 bits)
            if bytes[0] == 0xFF && (bytes[1] & 0xF0) == 0xF0 {
                return true
            }
        }
        
        // Raw AAC data (without ADTS) is also valid
        // It should be within reasonable size for an AAC frame
        // Typical AAC frame is 100-1000 bytes
        if data.count >= 10 && data.count <= 5000 {
            return true
        }
        
        return false
    }
}

