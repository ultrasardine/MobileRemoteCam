LOCAL_PATH := $(call my-dir)

# RTSP Server JNI Module
include $(CLEAR_VARS)

LOCAL_MODULE := rtsp_server_jni
LOCAL_SRC_FILES := rtsp_server_jni.cpp

# In production, add Live555 library dependencies here:
# LOCAL_C_INCLUDES += $(LOCAL_PATH)/live555/include
# LOCAL_STATIC_LIBRARIES := live555

LOCAL_LDLIBS := -llog -landroid

include $(BUILD_SHARED_LIBRARY)

# RTMP Client JNI Module
include $(CLEAR_VARS)

LOCAL_MODULE := rtmp_client_jni
LOCAL_SRC_FILES := rtmp_client_jni.cpp

# In production, add librtmp library dependencies here:
# LOCAL_C_INCLUDES += $(LOCAL_PATH)/librtmp/include
# LOCAL_STATIC_LIBRARIES := rtmp

LOCAL_LDLIBS := -llog -landroid

include $(BUILD_SHARED_LIBRARY)
