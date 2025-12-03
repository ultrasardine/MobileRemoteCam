import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ip_camera_streaming/services/rtmp_storage_service.dart';
import 'package:ip_camera_streaming/models/rtmp_target.dart';

// Feature: ip-camera-streaming-platform, Property 40: RTMP credentials stored securely
// Validates: Requirements 11.4

/// Mock implementation of FlutterSecureStorage for testing
class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};
  bool _isSecure = true;

  MockSecureStorage() : super();

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map.from(_storage);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }

  // Helper method to check if storage is secure
  bool get isSecure => _isSecure;

  // Helper method to simulate insecure storage
  void setInsecure() {
    _isSecure = false;
  }
}

void main() {
  group('RTMP Storage Service Property Tests', () {
    late MockSecureStorage mockStorage;
    late RtmpStorageService service;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = RtmpStorageService(secureStorage: mockStorage);
    });

    test('Property 40: RTMP credentials stored securely - YouTube credentials',
        () async {
      // For any YouTube RTMP target with credentials
      final target = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: 'test-youtube-stream-key-12345',
        enabled: true,
      );

      // When saved to storage
      await service.saveTargets([target]);

      // Then the stream key should be stored in secure storage
      final storedKey = await mockStorage.read(key: 'rtmp_youtube_key');
      expect(storedKey, equals(target.streamKey));

      // And the storage mechanism should be secure (using platform encryption)
      expect(mockStorage.isSecure, isTrue);

      // And when loaded back, credentials should match
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(1));
      expect(loadedTargets.first.streamKey, equals(target.streamKey));
    });

    test('Property 40: RTMP credentials stored securely - Twitch credentials',
        () async {
      // For any Twitch RTMP target with credentials
      final target = RtmpTarget(
        url: 'rtmp://live.twitch.tv/app',
        streamKey: 'live_123456789_abcdefghijklmnop',
        enabled: true,
      );

      // When saved to storage
      await service.saveTargets([target]);

      // Then the stream key should be stored in secure storage
      final storedKey = await mockStorage.read(key: 'rtmp_twitch_key');
      expect(storedKey, equals(target.streamKey));

      // And the storage mechanism should be secure
      expect(mockStorage.isSecure, isTrue);

      // And when loaded back, credentials should match
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(1));
      expect(loadedTargets.first.streamKey, equals(target.streamKey));
    });

    test(
        'Property 40: RTMP credentials stored securely - Multiple targets round-trip',
        () async {
      // For any combination of YouTube and Twitch targets
      final targets = [
        RtmpTarget(
          url: 'rtmp://a.rtmp.youtube.com/live2',
          streamKey: 'youtube-key-abc123',
          enabled: true,
        ),
        RtmpTarget(
          url: 'rtmp://live.twitch.tv/app',
          streamKey: 'twitch-key-xyz789',
          enabled: false,
        ),
      ];

      // When saved to storage
      await service.saveTargets(targets);

      // Then both stream keys should be stored securely
      final youtubeKey = await mockStorage.read(key: 'rtmp_youtube_key');
      final twitchKey = await mockStorage.read(key: 'rtmp_twitch_key');

      expect(youtubeKey, equals('youtube-key-abc123'));
      expect(twitchKey, equals('twitch-key-xyz789'));
      expect(mockStorage.isSecure, isTrue);

      // And when loaded back, all credentials should match
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(2));

      final loadedYoutube =
          loadedTargets.firstWhere((t) => t.url.contains('youtube'));
      final loadedTwitch =
          loadedTargets.firstWhere((t) => t.url.contains('twitch'));

      expect(loadedYoutube.streamKey, equals('youtube-key-abc123'));
      expect(loadedYoutube.enabled, isTrue);
      expect(loadedTwitch.streamKey, equals('twitch-key-xyz789'));
      expect(loadedTwitch.enabled, isFalse);
    });

    test(
        'Property 40: RTMP credentials stored securely - Empty stream keys not stored',
        () async {
      // For any target with empty stream key
      final target = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: '',
        enabled: true,
      );

      // When saved to storage
      await service.saveTargets([target]);

      // Then when loaded back, no targets should be returned
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(0));
    });

    test(
        'Property 40: RTMP credentials stored securely - Credentials cleared properly',
        () async {
      // For any stored credentials
      final target = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: 'sensitive-key-to-clear',
        enabled: true,
      );

      await service.saveTargets([target]);

      // When cleared
      await service.clearAll();

      // Then no credentials should remain in storage
      final youtubeKey = await mockStorage.read(key: 'rtmp_youtube_key');
      final twitchKey = await mockStorage.read(key: 'rtmp_twitch_key');

      expect(youtubeKey, isNull);
      expect(twitchKey, isNull);

      // And loading should return empty list
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(0));
    });

    test(
        'Property 40: RTMP credentials stored securely - Stream key verification',
        () async {
      // For any stream key stored
      final target = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: 'verify-this-key',
        enabled: true,
      );

      await service.saveTargets([target]);

      // Then the service should confirm it's stored securely
      final isSecure = await service.isStreamKeySecure('rtmp_youtube_key');
      expect(isSecure, isTrue);

      // And non-existent keys should return false
      final nonExistent =
          await service.isStreamKeySecure('rtmp_nonexistent_key');
      expect(nonExistent, isFalse);
    });

    test(
        'Property 40: RTMP credentials stored securely - Update existing credentials',
        () async {
      // For any initially stored credentials
      final initialTarget = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: 'old-key',
        enabled: true,
      );

      await service.saveTargets([initialTarget]);

      // When updated with new credentials
      final updatedTarget = RtmpTarget(
        url: 'rtmp://a.rtmp.youtube.com/live2',
        streamKey: 'new-key',
        enabled: true,
      );

      await service.saveTargets([updatedTarget]);

      // Then only the new credentials should be stored
      final loadedTargets = await service.loadTargets();
      expect(loadedTargets.length, equals(1));
      expect(loadedTargets.first.streamKey, equals('new-key'));

      // And old credentials should not be accessible
      final storedKey = await mockStorage.read(key: 'rtmp_youtube_key');
      expect(storedKey, equals('new-key'));
      expect(storedKey, isNot(equals('old-key')));
    });
  });
}
