# Android RTSP Server JNI Implementation

This directory contains the JNI (Java Native Interface) wrapper for the Live555 RTSP server library.

## Overview

The RTSP server implementation provides local network streaming capabilities for the IP Camera Streaming Platform. It allows clients like OBS and VLC to connect and receive H.264 video and AAC audio streams.

## Files

- `rtsp_server_jni.cpp` - JNI wrapper implementation for Live555 RTSP server
- `Android.mk` - NDK build configuration
- `Application.mk` - NDK application configuration

## Building

To build the native library, use the Android NDK:

```bash
# From the project root
ndk-build -C app/src/main/jni

# Or using the Makefile
make build-android
```

The build will produce `librtsp_server_jni.so` for each target architecture (armeabi-v7a, arm64-v8a, x86, x86_64).

## Integration with Live555

### Current Implementation

The current implementation provides a mock RTSP server for testing and development purposes. It implements the full JNI interface but does not yet integrate with the actual Live555 library.

### Production Integration

To integrate with the actual Live555 library:

1. **Download and build Live555:**
   ```bash
   # Download Live555 source
   wget http://www.live555.com/liveMedia/public/live555-latest.tar.gz
   tar -xzf live555-latest.tar.gz
   
   # Build for Android using NDK
   cd live
   ./genMakefiles android
   make
   ```

2. **Update Android.mk:**
   ```makefile
   LOCAL_C_INCLUDES += $(LOCAL_PATH)/live555/include
   LOCAL_STATIC_LIBRARIES := live555
   ```

3. **Update rtsp_server_jni.cpp:**
   - Replace `MockRTSPServer` with actual Live555 classes
   - Implement `RTSPServer`, `ServerMediaSession`, and `H264VideoStreamFramer`
   - Handle Live555 event loop in a separate thread

## API

The JNI interface provides the following native methods:

### `nativeStart(port: Int): Long`
Starts the RTSP server on the specified port and returns a handle to the server context.

### `nativeStop(handle: Long)`
Stops the RTSP server and releases all resources.

### `nativeFeedVideo(handle: Long, data: ByteArray, timestamp: Long, isKeyframe: Boolean)`
Feeds an H.264 video frame to the RTSP server.

### `nativeFeedAudio(handle: Long, data: ByteArray, timestamp: Long)`
Feeds an AAC audio frame to the RTSP server.

## Kotlin Interface

The Kotlin class `RTSPServer` in `app/src/main/java/com/samsung/android/scan3d/streaming/RTSPServer.kt` provides a high-level interface to the JNI layer.

Example usage:

```kotlin
val rtspServer = RTSPServer()

// Start server
rtspServer.start(port = 8554)

// Feed video frames
rtspServer.feedVideoFrame(encodedData, timestamp, isKeyframe)

// Feed audio frames
rtspServer.feedAudioFrame(encodedData, timestamp)

// Stop server
rtspServer.stop()
```

## Testing

Property-based tests are located in `test/android/rtsp_server_property_test.dart`. These tests verify:

- Port binding for valid port ranges (1024-65535)
- Rejection of invalid ports
- Video and audio frame feeding
- Start/stop lifecycle
- Stream URL format validation

Run tests with:

```bash
flutter test test/android/rtsp_server_property_test.dart
```

## License

This implementation is designed to work with Live555, which is licensed under LGPL 3.0. The JNI wrapper code follows the same license to ensure compatibility.

## References

- [Live555 Streaming Media](http://www.live555.com/)
- [Android NDK Documentation](https://developer.android.com/ndk)
- [RTSP RFC 2326](https://tools.ietf.org/html/rfc2326)
