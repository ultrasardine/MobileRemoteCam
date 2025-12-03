import 'package:shared_preferences/shared_preferences.dart';
import '../models/resolution.dart';

/// Service for persisting and restoring application settings
class SettingsPersistenceService {
  final SharedPreferences _prefs;

  // Default values
  static const String defaultCameraId = 'back';
  static const int defaultResolutionWidth = 1920;
  static const int defaultResolutionHeight = 1080;
  static const int defaultFrameRate = 30;
  static const int defaultBitrate = 5000000; // 5 Mbps
  static const bool defaultAudioEnabled = true;
  static const bool defaultRtspEnabled = false;
  static const int defaultRtspPort = 8554;

  // Storage keys
  static const String _keyCameraId = 'camera_id';
  static const String _keyResolutionWidth = 'resolution_width';
  static const String _keyResolutionHeight = 'resolution_height';
  static const String _keyFrameRate = 'frame_rate';
  static const String _keyBitrate = 'bitrate';
  static const String _keyAudioEnabled = 'audio_enabled';
  static const String _keyRtspEnabled = 'rtsp_enabled';
  static const String _keyRtspPort = 'rtsp_port';

  SettingsPersistenceService(this._prefs);

  /// Save camera selection
  Future<void> saveCameraId(String cameraId) async {
    await _prefs.setString(_keyCameraId, cameraId);
  }

  /// Load camera selection
  String loadCameraId() {
    return _prefs.getString(_keyCameraId) ?? defaultCameraId;
  }

  /// Save resolution
  Future<void> saveResolution(Resolution resolution) async {
    await _prefs.setInt(_keyResolutionWidth, resolution.width);
    await _prefs.setInt(_keyResolutionHeight, resolution.height);
  }

  /// Load resolution
  Resolution loadResolution() {
    final width = _prefs.getInt(_keyResolutionWidth) ?? defaultResolutionWidth;
    final height =
        _prefs.getInt(_keyResolutionHeight) ?? defaultResolutionHeight;
    return Resolution(width: width, height: height);
  }

  /// Save frame rate
  Future<void> saveFrameRate(int frameRate) async {
    await _prefs.setInt(_keyFrameRate, frameRate);
  }

  /// Load frame rate
  int loadFrameRate() {
    return _prefs.getInt(_keyFrameRate) ?? defaultFrameRate;
  }

  /// Save bitrate
  Future<void> saveBitrate(int bitrate) async {
    await _prefs.setInt(_keyBitrate, bitrate);
  }

  /// Load bitrate
  int loadBitrate() {
    return _prefs.getInt(_keyBitrate) ?? defaultBitrate;
  }

  /// Save audio enabled state
  Future<void> saveAudioEnabled(bool enabled) async {
    await _prefs.setBool(_keyAudioEnabled, enabled);
  }

  /// Load audio enabled state
  bool loadAudioEnabled() {
    return _prefs.getBool(_keyAudioEnabled) ?? defaultAudioEnabled;
  }

  /// Save RTSP enabled state
  Future<void> saveRtspEnabled(bool enabled) async {
    await _prefs.setBool(_keyRtspEnabled, enabled);
  }

  /// Load RTSP enabled state
  bool loadRtspEnabled() {
    return _prefs.getBool(_keyRtspEnabled) ?? defaultRtspEnabled;
  }

  /// Save RTSP port
  Future<void> saveRtspPort(int port) async {
    await _prefs.setInt(_keyRtspPort, port);
  }

  /// Load RTSP port
  int loadRtspPort() {
    return _prefs.getInt(_keyRtspPort) ?? defaultRtspPort;
  }

  /// Clear all settings and reset to defaults
  Future<void> clearAllSettings() async {
    await _prefs.remove(_keyCameraId);
    await _prefs.remove(_keyResolutionWidth);
    await _prefs.remove(_keyResolutionHeight);
    await _prefs.remove(_keyFrameRate);
    await _prefs.remove(_keyBitrate);
    await _prefs.remove(_keyAudioEnabled);
    await _prefs.remove(_keyRtspEnabled);
    await _prefs.remove(_keyRtspPort);
  }

  /// Check if any settings have been saved
  bool hasSettings() {
    return _prefs.containsKey(_keyCameraId) ||
        _prefs.containsKey(_keyResolutionWidth) ||
        _prefs.containsKey(_keyFrameRate) ||
        _prefs.containsKey(_keyBitrate);
  }
}
