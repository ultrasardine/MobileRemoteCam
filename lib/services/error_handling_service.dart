import 'package:flutter/services.dart';
import '../models/error_info.dart';

/// Service for comprehensive error handling and logging
class ErrorHandlingService {
  static const platform = MethodChannel('com.ipcamera/streaming');

  /// Check if device is overheating and get warnings
  Future<OverheatingWarning> checkOverheating(double temperature) async {
    try {
      final result = await platform.invokeMethod('checkOverheating', {
        'temperature': temperature,
      });
      return OverheatingWarning.fromMap(
        Map<String, dynamic>.from(result as Map),
      );
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to check overheating: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get overheating thresholds
  Future<OverheatingThresholds> getOverheatingThresholds() async {
    try {
      final result = await platform.invokeMethod('getOverheatingThresholds');
      return OverheatingThresholds.fromMap(
        Map<String, dynamic>.from(result as Map),
      );
    } on PlatformException {
      // Return defaults if native implementation not available
      return OverheatingThresholds.defaults;
    }
  }

  /// Get encoder information including fallback status
  Future<EncoderInfo> getEncoderInfo() async {
    try {
      final result = await platform.invokeMethod('getEncoderInfo');
      return EncoderInfo.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get encoder info: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get error logs with optional filtering
  Future<List<ErrorInfo>> getErrorLogs({
    int limit = 100,
    String? errorType,
  }) async {
    try {
      final result = await platform.invokeMethod('getErrorLogs', {
        'limit': limit,
        if (errorType != null) 'errorType': errorType,
      });

      final resultMap = Map<String, dynamic>.from(result as Map);
      final logs = resultMap['logs'] as List;

      return logs
          .map((log) => ErrorInfo.fromMap(Map<String, dynamic>.from(log)))
          .toList();
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get error logs: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Clear all error logs
  Future<void> clearErrorLogs() async {
    try {
      await platform.invokeMethod('clearErrorLogs');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to clear error logs: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Manually log an error
  Future<int> logError({
    required String errorType,
    required String errorCode,
    required String message,
    Map<String, dynamic>? details,
    String? stackTrace,
    required String component,
  }) async {
    try {
      final result = await platform.invokeMethod('logError', {
        'errorType': errorType,
        'errorCode': errorCode,
        'message': message,
        'details': details,
        'stackTrace': stackTrace,
        'component': component,
      });

      return (result as Map)['logId'] as int;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to log error: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Handle camera initialization error
  Future<void> handleCameraError(PlatformException error) async {
    await logError(
      errorType: 'camera_init_failed',
      errorCode: error.code,
      message: error.message ?? 'Camera initialization failed',
      details: error.details as Map<String, dynamic>?,
      stackTrace: error.stacktrace,
      component: 'camera',
    );
  }

  /// Handle encoder initialization error
  Future<void> handleEncoderError(PlatformException error) async {
    await logError(
      errorType: 'encoder_init_failed',
      errorCode: error.code,
      message: error.message ?? 'Encoder initialization failed',
      details: error.details as Map<String, dynamic>?,
      stackTrace: error.stacktrace,
      component: 'encoder',
    );
  }

  /// Handle RTSP server error
  Future<void> handleRTSPError(PlatformException error) async {
    await logError(
      errorType: 'rtsp_server_failed',
      errorCode: error.code,
      message: error.message ?? 'RTSP server failed',
      details: error.details as Map<String, dynamic>?,
      stackTrace: error.stacktrace,
      component: 'rtsp',
    );
  }

  /// Handle RTMP connection error
  Future<void> handleRTMPError(PlatformException error) async {
    await logError(
      errorType: 'rtmp_connection_failed',
      errorCode: error.code,
      message: error.message ?? 'RTMP connection failed',
      details: error.details as Map<String, dynamic>?,
      stackTrace: error.stacktrace,
      component: 'rtmp',
    );
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(String errorCode) {
    switch (errorCode) {
      case 'CAMERA_INIT_FAILED':
        return 'Unable to access camera. Please ensure camera permissions are granted and the camera is not in use by another app.';
      case 'CAMERA_IN_USE':
        return 'Camera is currently in use by another application. Please close other camera apps and try again.';
      case 'ENCODER_INIT_FAILED':
        return 'Failed to initialize video encoder. The app will attempt to use software encoding.';
      case 'RTSP_SERVER_FAILED':
        return 'Failed to start RTSP server. The port may already be in use. Try changing the RTSP port in settings.';
      case 'RTSP_PORT_IN_USE':
        return 'The selected RTSP port is already in use. Please choose a different port.';
      case 'RTMP_CONNECTION_FAILED':
        return 'Failed to connect to RTMP server. Please check your stream URL and stream key.';
      case 'RTMP_AUTH_FAILED':
        return 'RTMP authentication failed. Please verify your stream key is correct.';
      case 'NETWORK_ERROR':
        return 'Network connection lost. Please check your internet connection.';
      case 'PERMISSION_DENIED':
        return 'Required permissions were denied. Please grant camera and microphone permissions in settings.';
      case 'OVERHEATING':
        return 'Device is overheating. Consider reducing resolution, frame rate, or bitrate.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Get troubleshooting steps for error
  List<String> getTroubleshootingSteps(String errorCode) {
    switch (errorCode) {
      case 'CAMERA_INIT_FAILED':
      case 'CAMERA_IN_USE':
        return [
          'Close other apps that might be using the camera',
          'Restart the app',
          'Check camera permissions in device settings',
          'Restart your device if the problem persists',
        ];
      case 'ENCODER_INIT_FAILED':
        return [
          'The app will automatically use software encoding',
          'Reduce resolution to 720p for better performance',
          'Reduce frame rate to 30 FPS',
          'Restart the app if issues persist',
        ];
      case 'RTSP_SERVER_FAILED':
      case 'RTSP_PORT_IN_USE':
        return [
          'Change RTSP port in configuration settings',
          'Try using port 8555 or 8556',
          'Ensure no other streaming apps are running',
          'Restart the app',
        ];
      case 'RTMP_CONNECTION_FAILED':
        return [
          'Verify your stream URL is correct',
          'Check your stream key',
          'Ensure you have a stable internet connection',
          'Try restarting your router',
          'Contact your streaming platform support',
        ];
      case 'RTMP_AUTH_FAILED':
        return [
          'Verify your stream key is correct',
          'Generate a new stream key from your streaming platform',
          'Ensure your account is in good standing',
        ];
      case 'NETWORK_ERROR':
        return [
          'Check your WiFi or cellular connection',
          'Try switching between WiFi and cellular',
          'Move closer to your WiFi router',
          'Restart your router',
        ];
      case 'PERMISSION_DENIED':
        return [
          'Open device Settings',
          'Navigate to Apps > IP Camera Streaming',
          'Grant Camera and Microphone permissions',
          'Restart the app',
        ];
      case 'OVERHEATING':
        return [
          'Reduce resolution to 720p or lower',
          'Reduce frame rate to 30 FPS',
          'Reduce bitrate to 3 Mbps or lower',
          'Remove device case',
          'Move device away from direct sunlight',
          'Allow device to cool before resuming',
        ];
      default:
        return [
          'Restart the app',
          'Check your device settings',
          'Ensure you have the latest app version',
          'Contact support if the problem persists',
        ];
    }
  }
}
