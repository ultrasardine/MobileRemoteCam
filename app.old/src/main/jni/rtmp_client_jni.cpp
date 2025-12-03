#include <jni.h>
#include <string>
#include <memory>
#include <vector>
#include <android/log.h>
#include <pthread.h>
#include <unistd.h>
#include <cmath>

#define LOG_TAG "RTMPClientJNI"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

// RTMP Client Context
struct RTMPClientContext {
    std::string url;
    std::string streamKey;
    bool isConnected;
    pthread_mutex_t mutex;
    int reconnectionAttempts;
    int64_t videoFrameCount;
    int64_t audioFrameCount;
    int64_t bytesSent;
};

// Mock RTMP Client implementation
// In production, this would use actual librtmp library
class MockRTMPClient {
private:
    std::string url;
    std::string streamKey;
    bool connected;
    int reconnectionAttempts;
    static const int MAX_RECONNECTION_ATTEMPTS = 5;
    
public:
    MockRTMPClient(const std::string& rtmpUrl, const std::string& key) 
        : url(rtmpUrl), streamKey(key), connected(false), reconnectionAttempts(0) {}
    
    bool connect() {
        if (connected) {
            LOGW("Already connected");
            return true;
        }
        
        // Validate URL format
        if (!isValidRTMPURL(url)) {
            LOGE("Invalid RTMP URL format: %s", url.c_str());
            return false;
        }
        
        // Validate stream key
        if (streamKey.empty()) {
            LOGE("Stream key is empty");
            return false;
        }
        
        // In real implementation, this would:
        // 1. Initialize librtmp
        // 2. Set connection parameters (URL, stream key)
        // 3. Perform RTMP handshake
        // 4. Send connect and createStream commands
        
        LOGI("Connecting to RTMP server: %s", url.c_str());
        
        // Simulate connection delay
        usleep(100000); // 100ms
        
        connected = true;
        reconnectionAttempts = 0;
        
        LOGI("Successfully connected to RTMP server");
        return true;
    }
    
    void disconnect() {
        if (!connected) {
            return;
        }
        
        LOGI("Disconnecting from RTMP server");
        
        // In real implementation, this would:
        // 1. Send deleteStream command
        // 2. Close RTMP connection
        // 3. Clean up librtmp resources
        
        connected = false;
        reconnectionAttempts = 0;
        
        LOGI("Disconnected from RTMP server");
    }
    
    bool sendVideoFrame(const uint8_t* data, size_t size, uint32_t timestamp, bool isKeyframe) {
        if (!connected) {
            LOGE("Cannot send video frame: not connected");
            return false;
        }
        
        // In real implementation, this would:
        // 1. Packetize H.264 data as FLV
        // 2. Send via librtmp
        // 3. Handle send errors
        
        LOGI("Sent video frame: size=%zu, timestamp=%u, keyframe=%d", 
             size, timestamp, isKeyframe);
        
        return true;
    }
    
    bool sendAudioFrame(const uint8_t* data, size_t size, uint32_t timestamp) {
        if (!connected) {
            LOGE("Cannot send audio frame: not connected");
            return false;
        }
        
        // In real implementation, this would:
        // 1. Packetize AAC data as FLV
        // 2. Send via librtmp
        // 3. Handle send errors
        
        LOGI("Sent audio frame: size=%zu, timestamp=%u", size, timestamp);
        
        return true;
    }
    
    bool isConnected() const {
        return connected;
    }
    
    bool reconnect() {
        if (connected) {
            LOGW("Already connected, no need to reconnect");
            return true;
        }
        
        if (reconnectionAttempts >= MAX_RECONNECTION_ATTEMPTS) {
            LOGE("Maximum reconnection attempts (%d) reached", MAX_RECONNECTION_ATTEMPTS);
            return false;
        }
        
        // Calculate exponential backoff delay
        double delay = calculateBackoffDelay(reconnectionAttempts);
        
        LOGI("Reconnection attempt %d/%d after %.1fs", 
             reconnectionAttempts + 1, MAX_RECONNECTION_ATTEMPTS, delay);
        
        // Wait for backoff period
        usleep(static_cast<useconds_t>(delay * 1000000));
        
        reconnectionAttempts++;
        
        // Attempt connection
        return connect();
    }
    
    int getReconnectionAttempts() const {
        return reconnectionAttempts;
    }
    
private:
    bool isValidRTMPURL(const std::string& rtmpUrl) const {
        // RTMP URL format: rtmp://[host]/[app]
        if (rtmpUrl.find("rtmp://") != 0 && rtmpUrl.find("rtmps://") != 0) {
            return false;
        }
        
        // Remove protocol
        std::string withoutProtocol = rtmpUrl;
        size_t protocolEnd = withoutProtocol.find("://");
        if (protocolEnd != std::string::npos) {
            withoutProtocol = withoutProtocol.substr(protocolEnd + 3);
        }
        
        // Should have at least host/app format
        size_t firstSlash = withoutProtocol.find('/');
        if (firstSlash == std::string::npos || firstSlash == 0) {
            return false;
        }
        
        // Check if there's an app name after the slash
        if (firstSlash + 1 >= withoutProtocol.length()) {
            return false;
        }
        
        return true;
    }
    
    double calculateBackoffDelay(int attempt) const {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        double baseDelay = 1.0;
        double maxDelay = 16.0;
        double delay = baseDelay * std::pow(2.0, static_cast<double>(attempt));
        return std::min(delay, maxDelay);
    }
};

extern "C" {

JNIEXPORT jlong JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeConnect(
    JNIEnv* env,
    jobject /* this */,
    jstring url,
    jstring streamKey) {
    
    const char* urlStr = env->GetStringUTFChars(url, nullptr);
    const char* keyStr = env->GetStringUTFChars(streamKey, nullptr);
    
    LOGI("nativeConnect called with URL: %s", urlStr);
    
    try {
        // Create RTMP client context
        RTMPClientContext* context = new RTMPClientContext();
        context->url = std::string(urlStr);
        context->streamKey = std::string(keyStr);
        context->isConnected = false;
        context->reconnectionAttempts = 0;
        context->videoFrameCount = 0;
        context->audioFrameCount = 0;
        context->bytesSent = 0;
        pthread_mutex_init(&context->mutex, nullptr);
        
        // Create and connect mock RTMP client
        MockRTMPClient* client = new MockRTMPClient(context->url, context->streamKey);
        
        env->ReleaseStringUTFChars(url, urlStr);
        env->ReleaseStringUTFChars(streamKey, keyStr);
        
        if (!client->connect()) {
            delete client;
            delete context;
            LOGE("Failed to connect to RTMP server");
            return 0;
        }
        
        context->isConnected = true;
        
        LOGI("RTMP client connected successfully");
        
        // Store client pointer in context (simplified for mock)
        // In real implementation, we'd store the client pointer properly
        return reinterpret_cast<jlong>(context);
        
    } catch (const std::exception& e) {
        LOGE("Exception in nativeConnect: %s", e.what());
        env->ReleaseStringUTFChars(url, urlStr);
        env->ReleaseStringUTFChars(streamKey, keyStr);
        return 0;
    }
}

JNIEXPORT void JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeDisconnect(
    JNIEnv* env,
    jobject /* this */,
    jlong handle) {
    
    if (handle == 0) {
        LOGE("Invalid handle in nativeDisconnect");
        return;
    }
    
    try {
        RTMPClientContext* context = reinterpret_cast<RTMPClientContext*>(handle);
        
        pthread_mutex_lock(&context->mutex);
        if (context->isConnected) {
            LOGI("Disconnecting RTMP client");
            context->isConnected = false;
        }
        pthread_mutex_unlock(&context->mutex);
        
        pthread_mutex_destroy(&context->mutex);
        delete context;
        
        LOGI("RTMP client disconnected");
        
    } catch (const std::exception& e) {
        LOGE("Exception in nativeDisconnect: %s", e.what());
    }
}

JNIEXPORT jboolean JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeSendVideo(
    JNIEnv* env,
    jobject /* this */,
    jlong handle,
    jbyteArray data,
    jint timestamp,
    jboolean isKeyframe) {
    
    if (handle == 0) {
        LOGE("Invalid handle in nativeSendVideo");
        return JNI_FALSE;
    }
    
    try {
        RTMPClientContext* context = reinterpret_cast<RTMPClientContext*>(handle);
        
        if (!context->isConnected) {
            LOGE("Client not connected, cannot send video");
            return JNI_FALSE;
        }
        
        jsize dataLen = env->GetArrayLength(data);
        jbyte* dataPtr = env->GetByteArrayElements(data, nullptr);
        
        if (dataPtr != nullptr) {
            // In real implementation, send via librtmp
            LOGI("Sending video frame: size=%d, timestamp=%d, keyframe=%d",
                 dataLen, timestamp, isKeyframe);
            
            context->videoFrameCount++;
            context->bytesSent += dataLen;
            
            env->ReleaseByteArrayElements(data, dataPtr, JNI_ABORT);
            return JNI_TRUE;
        }
        
        return JNI_FALSE;
        
    } catch (const std::exception& e) {
        LOGE("Exception in nativeSendVideo: %s", e.what());
        return JNI_FALSE;
    }
}

JNIEXPORT jboolean JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeSendAudio(
    JNIEnv* env,
    jobject /* this */,
    jlong handle,
    jbyteArray data,
    jint timestamp) {
    
    if (handle == 0) {
        LOGE("Invalid handle in nativeSendAudio");
        return JNI_FALSE;
    }
    
    try {
        RTMPClientContext* context = reinterpret_cast<RTMPClientContext*>(handle);
        
        if (!context->isConnected) {
            LOGE("Client not connected, cannot send audio");
            return JNI_FALSE;
        }
        
        jsize dataLen = env->GetArrayLength(data);
        jbyte* dataPtr = env->GetByteArrayElements(data, nullptr);
        
        if (dataPtr != nullptr) {
            // In real implementation, send via librtmp
            LOGI("Sending audio frame: size=%d, timestamp=%d",
                 dataLen, timestamp);
            
            context->audioFrameCount++;
            context->bytesSent += dataLen;
            
            env->ReleaseByteArrayElements(data, dataPtr, JNI_ABORT);
            return JNI_TRUE;
        }
        
        return JNI_FALSE;
        
    } catch (const std::exception& e) {
        LOGE("Exception in nativeSendAudio: %s", e.what());
        return JNI_FALSE;
    }
}

JNIEXPORT jboolean JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeReconnect(
    JNIEnv* env,
    jobject /* this */,
    jlong handle) {
    
    if (handle == 0) {
        LOGE("Invalid handle in nativeReconnect");
        return JNI_FALSE;
    }
    
    try {
        RTMPClientContext* context = reinterpret_cast<RTMPClientContext*>(handle);
        
        if (context->isConnected) {
            LOGW("Already connected, no need to reconnect");
            return JNI_TRUE;
        }
        
        if (context->reconnectionAttempts >= 5) {
            LOGE("Maximum reconnection attempts (5) reached");
            return JNI_FALSE;
        }
        
        // Calculate exponential backoff delay
        double baseDelay = 1.0;
        double delay = baseDelay * std::pow(2.0, static_cast<double>(context->reconnectionAttempts));
        delay = std::min(delay, 16.0);
        
        LOGI("Reconnection attempt %d/5 after %.1fs", 
             context->reconnectionAttempts + 1, delay);
        
        // Wait for backoff period
        usleep(static_cast<useconds_t>(delay * 1000000));
        
        context->reconnectionAttempts++;
        
        // Simulate reconnection
        MockRTMPClient client(context->url, context->streamKey);
        if (client.connect()) {
            context->isConnected = true;
            LOGI("Reconnection successful");
            return JNI_TRUE;
        }
        
        LOGE("Reconnection failed");
        return JNI_FALSE;
        
    } catch (const std::exception& e) {
        LOGE("Exception in nativeReconnect: %s", e.what());
        return JNI_FALSE;
    }
}

JNIEXPORT jint JNICALL
Java_com_samsung_android_scan3d_streaming_RTMPClient_nativeGetReconnectionAttempts(
    JNIEnv* env,
    jobject /* this */,
    jlong handle) {
    
    if (handle == 0) {
        LOGE("Invalid handle in nativeGetReconnectionAttempts");
        return 0;
    }
    
    try {
        RTMPClientContext* context = reinterpret_cast<RTMPClientContext*>(handle);
        return context->reconnectionAttempts;
    } catch (const std::exception& e) {
        LOGE("Exception in nativeGetReconnectionAttempts: %s", e.what());
        return 0;
    }
}

} // extern "C"
