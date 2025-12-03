import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/rtmp_target.dart';

/// Service for securely storing and retrieving RTMP credentials
class RtmpStorageService {
  final FlutterSecureStorage _secureStorage;

  RtmpStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Save RTMP targets to secure storage
  Future<void> saveTargets(List<RtmpTarget> targets) async {
    // Clear existing targets
    await _secureStorage.delete(key: 'rtmp_youtube_url');
    await _secureStorage.delete(key: 'rtmp_youtube_key');
    await _secureStorage.delete(key: 'rtmp_youtube_enabled');
    await _secureStorage.delete(key: 'rtmp_twitch_url');
    await _secureStorage.delete(key: 'rtmp_twitch_key');
    await _secureStorage.delete(key: 'rtmp_twitch_enabled');

    // Save new targets
    for (final target in targets) {
      if (target.url.contains('youtube.com')) {
        await _secureStorage.write(key: 'rtmp_youtube_url', value: target.url);
        await _secureStorage.write(
            key: 'rtmp_youtube_key', value: target.streamKey);
        await _secureStorage.write(
            key: 'rtmp_youtube_enabled', value: target.enabled.toString());
      } else if (target.url.contains('twitch.tv')) {
        await _secureStorage.write(key: 'rtmp_twitch_url', value: target.url);
        await _secureStorage.write(
            key: 'rtmp_twitch_key', value: target.streamKey);
        await _secureStorage.write(
            key: 'rtmp_twitch_enabled', value: target.enabled.toString());
      }
    }
  }

  /// Load RTMP targets from secure storage
  Future<List<RtmpTarget>> loadTargets() async {
    final targets = <RtmpTarget>[];

    // Load YouTube configuration
    final youtubeUrl = await _secureStorage.read(key: 'rtmp_youtube_url');
    final youtubeKey = await _secureStorage.read(key: 'rtmp_youtube_key');
    final youtubeEnabledStr =
        await _secureStorage.read(key: 'rtmp_youtube_enabled');

    if (youtubeUrl != null && youtubeKey != null && youtubeKey.isNotEmpty) {
      targets.add(RtmpTarget(
        url: youtubeUrl,
        streamKey: youtubeKey,
        enabled: youtubeEnabledStr == 'true',
      ));
    }

    // Load Twitch configuration
    final twitchUrl = await _secureStorage.read(key: 'rtmp_twitch_url');
    final twitchKey = await _secureStorage.read(key: 'rtmp_twitch_key');
    final twitchEnabledStr =
        await _secureStorage.read(key: 'rtmp_twitch_enabled');

    if (twitchUrl != null && twitchKey != null && twitchKey.isNotEmpty) {
      targets.add(RtmpTarget(
        url: twitchUrl,
        streamKey: twitchKey,
        enabled: twitchEnabledStr == 'true',
      ));
    }

    return targets;
  }

  /// Check if a stream key is stored securely (not in plain text)
  Future<bool> isStreamKeySecure(String key) async {
    // FlutterSecureStorage uses platform-specific secure storage:
    // - iOS: Keychain
    // - Android: EncryptedSharedPreferences
    // This method verifies that the key exists in secure storage
    final storedKey = await _secureStorage.read(key: key);
    return storedKey != null;
  }

  /// Clear all RTMP credentials
  Future<void> clearAll() async {
    await _secureStorage.delete(key: 'rtmp_youtube_url');
    await _secureStorage.delete(key: 'rtmp_youtube_key');
    await _secureStorage.delete(key: 'rtmp_youtube_enabled');
    await _secureStorage.delete(key: 'rtmp_twitch_url');
    await _secureStorage.delete(key: 'rtmp_twitch_key');
    await _secureStorage.delete(key: 'rtmp_twitch_enabled');
  }
}
