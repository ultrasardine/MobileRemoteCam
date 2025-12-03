import Foundation
import AudioToolbox
import AVFoundation

/// Hardware AAC audio encoder using AudioToolbox
class AudioEncoder {
    private var audioConverter: AudioConverterRef?
    private var outputFormat: AudioStreamBasicDescription
    private var inputFormat: AudioStreamBasicDescription?
    
    var onEncodedFrame: ((Data, CMTime) -> Void)?
    
    init() {
        // Configure output format (AAC)
        outputFormat = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: UInt32(MPEG4ObjectID.AAC_LC.rawValue),
            mBytesPerPacket: 0,
            mFramesPerPacket: 1024,
            mBytesPerFrame: 0,
            mChannelsPerFrame: 1,
            mBitsPerChannel: 0,
            mReserved: 0
        )
    }
    
    /// Configure the encoder with default parameters
    func configure() throws {
        try configure(sampleRate: 44100.0, channels: 1)
    }
    
    /// Configure the encoder with audio parameters
    func configure(sampleRate: Double, channels: UInt32) throws {
        // Clean up existing converter
        if let converter = audioConverter {
            AudioConverterDispose(converter)
            audioConverter = nil
        }
        
        // Configure input format (PCM)
        inputFormat = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 2 * channels,
            mFramesPerPacket: 1,
            mBytesPerFrame: 2 * channels,
            mChannelsPerFrame: channels,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        
        // Update output format with correct sample rate and channels
        outputFormat.mSampleRate = sampleRate
        outputFormat.mChannelsPerFrame = channels
        
        // Create audio converter
        var converter: AudioConverterRef?
        let status = AudioConverterNew(&inputFormat!, &outputFormat, &converter)
        
        guard status == noErr, let converter = converter else {
            throw AudioEncoderError.converterCreationFailed(status)
        }
        
        // Set bitrate
        var bitrate: UInt32 = 64000 * channels // 64 kbps per channel
        let bitrateStatus = AudioConverterSetProperty(
            converter,
            kAudioConverterEncodeBitRate,
            UInt32(MemoryLayout<UInt32>.size),
            &bitrate
        )
        
        guard bitrateStatus == noErr else {
            AudioConverterDispose(converter)
            throw AudioEncoderError.propertySetFailed("bitrate", bitrateStatus)
        }
        
        self.audioConverter = converter
    }
    
    /// Encode an audio sample
    func encode(sampleBuffer: CMSampleBuffer) throws {
        guard let converter = audioConverter else {
            throw AudioEncoderError.notConfigured
        }
        
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            throw AudioEncoderError.invalidSampleBuffer
        }
        
        // Get audio data
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let result = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        guard result == kCMBlockBufferNoErr, let dataPointer = dataPointer else {
            throw AudioEncoderError.dataExtractionFailed
        }
        
        let inputData = Data(bytes: dataPointer, count: length)
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Prepare output buffer
        let outputBufferSize = 1024 * 8 // Sufficient for AAC frame
        var outputBuffer = Data(count: outputBufferSize)
        
        var outputPacketDescription = AudioStreamPacketDescription()
        var ioOutputDataPacketSize: UInt32 = 1
        
        // Create audio buffer list for output
        outputBuffer.withUnsafeMutableBytes { outputBytes in
            var audioBufferList = AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioBuffer(
                    mNumberChannels: outputFormat.mChannelsPerFrame,
                    mDataByteSize: UInt32(outputBufferSize),
                    mData: outputBytes.baseAddress
                )
            )
            
            // Convert audio
            let context = AudioEncoderContext(inputData: inputData, inputFormat: inputFormat!)
            let contextPointer = UnsafeMutablePointer<AudioEncoderContext>.allocate(capacity: 1)
            contextPointer.initialize(to: context)
            defer {
                contextPointer.deinitialize(count: 1)
                contextPointer.deallocate()
            }
            
            let status = AudioConverterFillComplexBuffer(
                converter,
                audioConverterInputCallback,
                contextPointer,
                &ioOutputDataPacketSize,
                &audioBufferList,
                &outputPacketDescription
            )
            
            if status == noErr && ioOutputDataPacketSize > 0 {
                let encodedData = Data(bytes: audioBufferList.mBuffers.mData!, count: Int(audioBufferList.mBuffers.mDataByteSize))
                onEncodedFrame?(encodedData, presentationTimeStamp)
            } else if status != noErr {
                print("AudioEncoder: Encoding failed with status \(status)")
            }
        }
    }
    
    /// Shutdown the encoder and release resources
    func shutdown() {
        if let converter = audioConverter {
            AudioConverterDispose(converter)
            audioConverter = nil
        }
    }
    
    deinit {
        shutdown()
    }
}

// MARK: - Audio Converter Callback

private struct AudioEncoderContext {
    let inputData: Data
    let inputFormat: AudioStreamBasicDescription
    var offset: Int = 0
}

private func audioConverterInputCallback(
    inAudioConverter: AudioConverterRef,
    ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
    ioData: UnsafeMutablePointer<AudioBufferList>,
    outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
    inUserData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let contextPointer = inUserData?.assumingMemoryBound(to: AudioEncoderContext.self) else {
        return kAudioConverterErr_InvalidInputSize
    }
    
    var context = contextPointer.pointee
    let remainingBytes = context.inputData.count - context.offset
    
    if remainingBytes == 0 {
        ioNumberDataPackets.pointee = 0
        return noErr
    }
    
    let bytesToCopy = min(remainingBytes, Int(ioNumberDataPackets.pointee) * Int(context.inputFormat.mBytesPerPacket))
    let packetsToCopy = bytesToCopy / Int(context.inputFormat.mBytesPerPacket)
    
    context.inputData.withUnsafeBytes { bytes in
        let sourcePointer = bytes.baseAddress!.advanced(by: context.offset)
        ioData.pointee.mBuffers.mData?.copyMemory(from: sourcePointer, byteCount: bytesToCopy)
    }
    
    ioData.pointee.mBuffers.mDataByteSize = UInt32(bytesToCopy)
    ioNumberDataPackets.pointee = UInt32(packetsToCopy)
    
    context.offset += bytesToCopy
    contextPointer.pointee = context
    
    return noErr
}

// MARK: - Error Types

enum AudioEncoderError: Error {
    case converterCreationFailed(OSStatus)
    case notConfigured
    case invalidSampleBuffer
    case dataExtractionFailed
    case encodingFailed(OSStatus)
    case propertySetFailed(String, OSStatus)
}

