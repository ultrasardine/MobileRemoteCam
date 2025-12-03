import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ip_camera_streaming/services/settings_persistence_service.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'dart:math';

/// Feature: ip-camera-streaming-platform, Property 41: Clear data resets to defaults
/// Validates: Requirements 11.6
///
/// Property: For any configuration setting, after clearing app data,
/// the setting should return to its documented default value.

void main() {
  group('Property 41: Clear data resets to defaults', () {
    late SettingsPersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = SettingsPersistenceService(prefs);
    });

    test('clear data resets camera ID to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random camera ID
        final cameraIds = ['front', 'telephoto', 'ultra-wide', 'external-0'];
        final cameraId = cameraIds[random.nextInt(cameraIds.length)];
        await service.saveCameraId(cameraId);

        // Clear all settings
        await service.clearAllSettings();

        // Load camera ID - should be default
        final loadedCameraId = service.loadCameraId();

        // Verify it's the default value
        expect(
            loadedCameraId, equals(SettingsPersistenceService.defaultCameraId),
            reason: 'Camera ID should reset to default after clear');
      }
    });

    test('clear data resets resolution to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random resolution
        final resolutions = [
          Resolution(width: 1280, height: 720),
          Resolution(width: 3840, height: 2160),
          Resolution(width: 640, height: 480),
        ];
        final resolution = resolutions[random.nextInt(resolutions.length)];
        await service.saveResolution(resolution);

        // Clear all settings
        await service.clearAllSettings();

        // Load resolution - should be default
        final loadedResolution = service.loadResolution();

        // Verify it's the default value
        expect(loadedResolution.width,
            equals(SettingsPersistenceService.defaultResolutionWidth),
            reason: 'Resolution width should reset to default after clear');
        expect(loadedResolution.height,
            equals(SettingsPersistenceService.defaultResolutionHeight),
            reason: 'Resolution height should reset to default after clear');
      }
    });

    test('clear data resets frame rate to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random frame rate
        final frameRate = random.nextBool() ? 30 : 60;
        await service.saveFrameRate(frameRate);

        // Clear all settings
        await service.clearAllSettings();

        // Load frame rate - should be default
        final loadedFrameRate = service.loadFrameRate();

        // Verify it's the default value
        expect(loadedFrameRate,
            equals(SettingsPersistenceService.defaultFrameRate),
            reason: 'Frame rate should reset to default after clear');
      }
    });

    test('clear data resets bitrate to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random bitrate
        final bitrate = 1000000 + random.nextInt(9000000);
        await service.saveBitrate(bitrate);

        // Clear all settings
        await service.clearAllSettings();

        // Load bitrate - should be default
        final loadedBitrate = service.loadBitrate();

        // Verify it's the default value
        expect(loadedBitrate, equals(SettingsPersistenceService.defaultBitrate),
            reason: 'Bitrate should reset to default after clear');
      }
    });

    test('clear data resets audio enabled to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random audio enabled state
        final audioEnabled = random.nextBool();
        await service.saveAudioEnabled(audioEnabled);

        // Clear all settings
        await service.clearAllSettings();

        // Load audio enabled - should be default
        final loadedAudioEnabled = service.loadAudioEnabled();

        // Verify it's the default value
        expect(loadedAudioEnabled,
            equals(SettingsPersistenceService.defaultAudioEnabled),
            reason: 'Audio enabled should reset to default after clear');
      }
    });

    test('clear data resets RTSP enabled to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random RTSP enabled state
        final rtspEnabled = random.nextBool();
        await service.saveRtspEnabled(rtspEnabled);

        // Clear all settings
        await service.clearAllSettings();

        // Load RTSP enabled - should be default
        final loadedRtspEnabled = service.loadRtspEnabled();

        // Verify it's the default value
        expect(loadedRtspEnabled,
            equals(SettingsPersistenceService.defaultRtspEnabled),
            reason: 'RTSP enabled should reset to default after clear');
      }
    });

    test('clear data resets RTSP port to default', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set a random RTSP port
        final port = 1024 + random.nextInt(64512);
        await service.saveRtspPort(port);

        // Clear all settings
        await service.clearAllSettings();

        // Load RTSP port - should be default
        final loadedPort = service.loadRtspPort();

        // Verify it's the default value
        expect(loadedPort, equals(SettingsPersistenceService.defaultRtspPort),
            reason: 'RTSP port should reset to default after clear');
      }
    });

    test('clear data resets all settings to defaults simultaneously', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set random values for all settings
        await service.saveCameraId('camera-${random.nextInt(5)}');
        await service.saveResolution(Resolution(
          width: 1280 + random.nextInt(2560),
          height: 720 + random.nextInt(1440),
        ));
        await service.saveFrameRate(random.nextBool() ? 30 : 60);
        await service.saveBitrate(1000000 + random.nextInt(9000000));
        await service.saveAudioEnabled(random.nextBool());
        await service.saveRtspEnabled(random.nextBool());
        await service.saveRtspPort(1024 + random.nextInt(64512));

        // Clear all settings
        await service.clearAllSettings();

        // Load all settings - should all be defaults
        final loadedCameraId = service.loadCameraId();
        final loadedResolution = service.loadResolution();
        final loadedFrameRate = service.loadFrameRate();
        final loadedBitrate = service.loadBitrate();
        final loadedAudioEnabled = service.loadAudioEnabled();
        final loadedRtspEnabled = service.loadRtspEnabled();
        final loadedPort = service.loadRtspPort();

        // Verify all are default values
        expect(
            loadedCameraId, equals(SettingsPersistenceService.defaultCameraId));
        expect(loadedResolution.width,
            equals(SettingsPersistenceService.defaultResolutionWidth));
        expect(loadedResolution.height,
            equals(SettingsPersistenceService.defaultResolutionHeight));
        expect(loadedFrameRate,
            equals(SettingsPersistenceService.defaultFrameRate));
        expect(
            loadedBitrate, equals(SettingsPersistenceService.defaultBitrate));
        expect(loadedAudioEnabled,
            equals(SettingsPersistenceService.defaultAudioEnabled));
        expect(loadedRtspEnabled,
            equals(SettingsPersistenceService.defaultRtspEnabled));
        expect(loadedPort, equals(SettingsPersistenceService.defaultRtspPort));
      }
    });

    test('hasSettings returns false after clear', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Set some random settings
        await service.saveCameraId('camera-${random.nextInt(5)}');
        await service.saveFrameRate(random.nextBool() ? 30 : 60);

        // Verify settings exist
        expect(service.hasSettings(), isTrue,
            reason: 'Should have settings after saving');

        // Clear all settings
        await service.clearAllSettings();

        // Verify no settings exist
        expect(service.hasSettings(), isFalse,
            reason: 'Should have no settings after clear');
      }
    });
  });
}
