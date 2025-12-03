import Foundation
import VideoToolbox
import AVFoundation

/// Hardware H.264 video encoder using VideoToolbox
class VideoEncoder {
    private var compressionSession: VTCompressionSession?
    private var width: Int = 0
    private var height: Int = 0
    private var frameRate: Int = 30
    private var bitrate: Int = 5_000_000
    
    var onEncodedFrame: ((Data, Bool, CMTime) -> Void)?
    
    /// Configure the encoder with video parameters
    func configure(width: Int, height: Int, frameRate: Int, bitrate: Int) throws {
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.bitrate = bitrate
        
        // Clean up existing session
        if let session = compressionSession {
            VTCompressionSessionInvalidate(session)
            compressionSession = nil
        }
        
        // Create compression session
        var session: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: encodingOutputCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &session
        )
        
        guard status == noErr, let session = session else {
            throw VideoEncoderError.sessionCreationFailed(status)
        }
        
        // Set properties
        try setProperty(session: session, key: kVTCompressionPropertyKey_RealTime, value: true)
        try setProperty(session: session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
        try setProperty(session: session, key: kVTCompressionPropertyKey_AverageBitRate, value: bitrate)
        try setProperty(session: session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: frameRate)
        try setProperty(session: session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: frameRate * 2)
        try setProperty(session: session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: false)
        
        // Prepare to encode
        let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
        guard prepareStatus == noErr else {
            throw VideoEncoderError.prepareFailed(prepareStatus)
        }
        
        self.compressionSession = session
    }
    
    /// Encode a video frame
    func encode(sampleBuffer: CMSampleBuffer) throws {
        guard let session = compressionSession else {
            throw VideoEncoderError.notConfigured
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw VideoEncoderError.invalidSampleBuffer
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: imageBuffer,
            presentationTimeStamp: presentationTimeStamp,
            duration: duration,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
        
        guard status == noErr else {
            throw VideoEncoderError.encodingFailed(status)
        }
    }
    
    /// Shutdown the encoder and release resources
    func shutdown() {
        if let session = compressionSession {
            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(session)
            compressionSession = nil
        }
    }
    
    // MARK: - Private Helpers
    
    private func setProperty<T>(session: VTCompressionSession, key: CFString, value: T) throws {
        let status: OSStatus
        
        if let boolValue = value as? Bool {
            status = VTSessionSetProperty(session, key: key, value: boolValue as CFBoolean)
        } else if let intValue = value as? Int {
            status = VTSessionSetProperty(session, key: key, value: intValue as CFNumber)
        } else if let stringValue = value as? CFString {
            status = VTSessionSetProperty(session, key: key, value: stringValue)
        } else {
            throw VideoEncoderError.invalidPropertyValue
        }
        
        guard status == noErr else {
            throw VideoEncoderError.propertySetFailed(key as String, status)
        }
    }
    
    deinit {
        shutdown()
    }
}

// MARK: - Encoding Callback

private func encodingOutputCallback(
    outputCallbackRefCon: UnsafeMutableRawPointer?,
    sourceFrameRefCon: UnsafeMutableRawPointer?,
    status: OSStatus,
    infoFlags: VTEncodeInfoFlags,
    sampleBuffer: CMSampleBuffer?
) {
    guard status == noErr else {
        print("VideoEncoder: Encoding failed with status \(status)")
        return
    }
    
    guard let sampleBuffer = sampleBuffer else {
        print("VideoEncoder: No sample buffer in callback")
        return
    }
    
    guard let encoder = outputCallbackRefCon else {
        print("VideoEncoder: No encoder reference in callback")
        return
    }
    
    let videoEncoder = Unmanaged<VideoEncoder>.fromOpaque(encoder).takeUnretainedValue()
    
    // Check if this is a keyframe
    let isKeyframe = !sampleBuffer.isNotKeyframe
    
    // Extract encoded data
    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
        print("VideoEncoder: No data buffer in sample buffer")
        return
    }
    
    var length: Int = 0
    var dataPointer: UnsafeMutablePointer<Int8>?
    let result = CMBlockBufferGetDataPointer(
        dataBuffer,
        atOffset: 0,
        lengthAtOffsetOut: nil,
        totalLengthOut: &length,
        dataPointerOut: &dataPointer
    )
    
    guard result == kCMBlockBufferNoErr, let dataPointer = dataPointer else {
        print("VideoEncoder: Failed to get data pointer")
        return
    }
    
    let data = Data(bytes: dataPointer, count: length)
    let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    
    // Call the callback
    videoEncoder.onEncodedFrame?(data, isKeyframe, presentationTimeStamp)
}

// MARK: - CMSampleBuffer Extension

extension CMSampleBuffer {
    var isNotKeyframe: Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(self, createIfNecessary: false) as? [[CFString: Any]] else {
            return true
        }
        
        guard let firstAttachment = attachments.first else {
            return true
        }
        
        if let notSync = firstAttachment[kCMSampleAttachmentKey_NotSync] as? Bool {
            return notSync
        }
        
        return false
    }
}

// MARK: - Error Types

enum VideoEncoderError: Error {
    case sessionCreationFailed(OSStatus)
    case prepareFailed(OSStatus)
    case notConfigured
    case invalidSampleBuffer
    case encodingFailed(OSStatus)
    case propertySetFailed(String, OSStatus)
    case invalidPropertyValue
}

