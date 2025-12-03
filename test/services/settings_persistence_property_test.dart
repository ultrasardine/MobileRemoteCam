import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ip_camera_streaming/services/settings_persistence_service.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'dart:math';

/// Feature: ip-camera-streaming-platform, Property 39: Settings persistence round-trip
/// Validates: Requirements 11.1, 11.2, 11.3, 11.5
///
/// Property: For any configuration setting (resolution, frame rate, bitrate, camera selection),
/// changing the setting, restarting the app, and reading the setting should return
/// the same value that was set.

void main() {
  group('Property 39: Settings persistence round-trip', () {
    late SettingsPersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = SettingsPersistenceService(prefs);
    });

    test('camera ID round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random camera ID
        final cameraIds = [
          'front',
          'back',
          'telephoto',
          'ultra-wide',
          'external-0'
        ];
        final cameraId = cameraIds[random.nextInt(cameraIds.length)];

        // Save the camera ID
        await service.saveCameraId(cameraId);

        // Simulate app restart by creating new service instance
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the camera ID
        final loadedCameraId = newService.loadCameraId();

        // Verify round-trip
        expect(loadedCameraId, equals(cameraId),
            reason: 'Camera ID should be preserved after save/load cycle');
      }
    });

    test('resolution round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random resolution
        final resolutions = [
          Resolution(width: 1280, height: 720),
          Resolution(width: 1920, height: 1080),
          Resolution(width: 3840, height: 2160),
          Resolution(width: 640, height: 480),
          Resolution(width: 2560, height: 1440),
        ];
        final resolution = resolutions[random.nextInt(resolutions.length)];

        // Save the resolution
        await service.saveResolution(resolution);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the resolution
        final loadedResolution = newService.loadResolution();

        // Verify round-trip
        expect(loadedResolution.width, equals(resolution.width),
            reason: 'Resolution width should be preserved');
        expect(loadedResolution.height, equals(resolution.height),
            reason: 'Resolution height should be preserved');
      }
    });

    test('frame rate round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random frame rate (30 or 60)
        final frameRates = [30, 60];
        final frameRate = frameRates[random.nextInt(frameRates.length)];

        // Save the frame rate
        await service.saveFrameRate(frameRate);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the frame rate
        final loadedFrameRate = newService.loadFrameRate();

        // Verify round-trip
        expect(loadedFrameRate, equals(frameRate),
            reason: 'Frame rate should be preserved after save/load cycle');
      }
    });

    test('bitrate round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random bitrate between 1 Mbps and 10 Mbps
        final bitrate = 1000000 + random.nextInt(9000000); // 1-10 Mbps

        // Save the bitrate
        await service.saveBitrate(bitrate);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the bitrate
        final loadedBitrate = newService.loadBitrate();

        // Verify round-trip
        expect(loadedBitrate, equals(bitrate),
            reason: 'Bitrate should be preserved after save/load cycle');
      }
    });

    test('audio enabled round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random boolean
        final audioEnabled = random.nextBool();

        // Save the audio enabled state
        await service.saveAudioEnabled(audioEnabled);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the audio enabled state
        final loadedAudioEnabled = newService.loadAudioEnabled();

        // Verify round-trip
        expect(loadedAudioEnabled, equals(audioEnabled),
            reason:
                'Audio enabled state should be preserved after save/load cycle');
      }
    });

    test('RTSP enabled round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random boolean
        final rtspEnabled = random.nextBool();

        // Save the RTSP enabled state
        await service.saveRtspEnabled(rtspEnabled);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the RTSP enabled state
        final loadedRtspEnabled = newService.loadRtspEnabled();

        // Verify round-trip
        expect(loadedRtspEnabled, equals(rtspEnabled),
            reason:
                'RTSP enabled state should be preserved after save/load cycle');
      }
    });

    test('RTSP port round-trip preserves value', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random port between 1024 and 65535
        final port = 1024 + random.nextInt(64512);

        // Save the RTSP port
        await service.saveRtspPort(port);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load the RTSP port
        final loadedPort = newService.loadRtspPort();

        // Verify round-trip
        expect(loadedPort, equals(port),
            reason: 'RTSP port should be preserved after save/load cycle');
      }
    });

    test('multiple settings round-trip preserves all values', () async {
      final random = Random();
      final testCases = 100;

      for (int i = 0; i < testCases; i++) {
        // Generate random settings
        final cameraId = 'camera-${random.nextInt(5)}';
        final resolution = Resolution(
          width: 1280 + random.nextInt(2560),
          height: 720 + random.nextInt(1440),
        );
        final frameRate = random.nextBool() ? 30 : 60;
        final bitrate = 1000000 + random.nextInt(9000000);
        final audioEnabled = random.nextBool();
        final rtspEnabled = random.nextBool();
        final rtspPort = 1024 + random.nextInt(64512);

        // Save all settings
        await service.saveCameraId(cameraId);
        await service.saveResolution(resolution);
        await service.saveFrameRate(frameRate);
        await service.saveBitrate(bitrate);
        await service.saveAudioEnabled(audioEnabled);
        await service.saveRtspEnabled(rtspEnabled);
        await service.saveRtspPort(rtspPort);

        // Simulate app restart
        final prefs = await SharedPreferences.getInstance();
        final newService = SettingsPersistenceService(prefs);

        // Load all settings
        final loadedCameraId = newService.loadCameraId();
        final loadedResolution = newService.loadResolution();
        final loadedFrameRate = newService.loadFrameRate();
        final loadedBitrate = newService.loadBitrate();
        final loadedAudioEnabled = newService.loadAudioEnabled();
        final loadedRtspEnabled = newService.loadRtspEnabled();
        final loadedRtspPort = newService.loadRtspPort();

        // Verify all round-trips
        expect(loadedCameraId, equals(cameraId));
        expect(loadedResolution.width, equals(resolution.width));
        expect(loadedResolution.height, equals(resolution.height));
        expect(loadedFrameRate, equals(frameRate));
        expect(loadedBitrate, equals(bitrate));
        expect(loadedAudioEnabled, equals(audioEnabled));
        expect(loadedRtspEnabled, equals(rtspEnabled));
        expect(loadedRtspPort, equals(rtspPort));
      }
    });
  });
}
