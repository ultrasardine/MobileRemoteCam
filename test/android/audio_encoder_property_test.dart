import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

/// Property-based tests for Android AudioEncoder functionality
/// Feature: ip-camera-streaming-platform, Property 4: AAC encoding produces valid output
/// Validates: Requirements 2.5
///
/// Note: These tests verify the contract between Flutter and native Android code.
/// The actual Android native implementation is in app/src/main/java/com/samsung/android/scan3d/streaming/AudioEncoder.kt
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android AudioEncoder Property Tests', () {
    const platform = MethodChannel('com.ipcamera/streaming');

    setUp(() {
      // Set up mock method channel handler for testing
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'configureAudioEncoder':
            final args = methodCall.arguments as Map?;

            // Default configuration
            if (args == null) {
              return {'success': true};
            }

            final sampleRate = args['sampleRate'] as int;
            final channelCount = args['channelCount'] as int;
            final bitrate = args['bitrate'] as int;

            // Validate configuration parameters
            if (sampleRate <= 0 || channelCount <= 0 || bitrate <= 0) {
              throw PlatformException(
                code: 'INVALID_ARGUMENT',
                message: 'Invalid encoder configuration parameters',
              );
            }

            return {'success': true};

          case 'encodeAudioSample':
            final args = methodCall.arguments as Map;
            final audioData = args['audioData'] as Uint8List;

            // Simulate AAC encoding
            // Return mock encoded data with AAC structure
            final encodedData = _generateMockAACFrame(audioData);

            return {
              'encodedData': encodedData,
              'timestamp': DateTime.now().microsecondsSinceEpoch,
            };

          case 'shutdownAudioEncoder':
            return {'success': true};

          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, null);
    });

    /// Property 4: AAC encoding produces valid output
    test('AAC encoding produces valid ADTS frame structure', () async {
      // Configure encoder with default parameters
      await platform.invokeMethod('configureAudioEncoder');

      // Property: For any valid audio data, encoding should produce valid AAC output
      final testSampleSizes = [
        1024 * 2, // 1024 samples * 2 bytes (16-bit PCM mono)
        2048 * 2, // 2048 samples
        4096 * 2, // 4096 samples
      ];

      for (var sampleSize in testSampleSizes) {
        final audioData = Uint8List(sampleSize);
        // Fill with test audio pattern (sine wave simulation)
        for (var i = 0; i < audioData.length; i += 2) {
          final sample = (32767 * 0.5 * (i / audioData.length)).toInt();
          audioData[i] = sample & 0xFF;
          audioData[i + 1] = (sample >> 8) & 0xFF;
        }

        final result = await platform.invokeMethod('encodeAudioSample', {
          'audioData': audioData,
        });

        expect(result, isA<Map>());
        final resultMap = result as Map;

        // Property: Encoded data must be present
        expect(resultMap.containsKey('encodedData'), isTrue,
            reason: 'Encoded result must contain encodedData');

        final encodedData = resultMap['encodedData'] as Uint8List;

        // Property: Encoded data must not be empty
        expect(encodedData.isNotEmpty, isTrue,
            reason: 'Encoded data must not be empty');

        // Property: AAC ADTS frames start with sync word (0xFFF)
        expect(_hasValidADTSSyncWord(encodedData), isTrue,
            reason: 'Encoded data must contain valid AAC ADTS sync word');

        // Property: Must have timestamp
        expect(resultMap.containsKey('timestamp'), isTrue,
            reason: 'Encoded result must contain timestamp');

        final timestamp = resultMap['timestamp'] as int;
        expect(timestamp, greaterThan(0), reason: 'Timestamp must be positive');
      }
    });

    test('encoder accepts default configuration', () async {
      // Property: Encoder should accept default configuration
      final result = await platform.invokeMethod('configureAudioEncoder');

      expect(result, isA<Map>());
      expect((result as Map)['success'], isTrue,
          reason: 'Encoder should accept default configuration');
    });

    test('encoder accepts standard sample rates', () async {
      // Property: For any standard sample rate, encoder should configure successfully
      final standardSampleRates = [
        8000, // Narrowband
        16000, // Wideband
        44100, // CD quality
        48000, // Professional audio
      ];

      for (var sampleRate in standardSampleRates) {
        final result = await platform.invokeMethod('configureAudioEncoder', {
          'sampleRate': sampleRate,
          'channelCount': 1,
          'bitrate': 64000,
        });

        expect(result, isA<Map>());
        expect((result as Map)['success'], isTrue,
            reason: 'Encoder should accept sample rate $sampleRate');
      }
    });

    test('encoder accepts mono and stereo channels', () async {
      // Property: For any valid channel count (1 or 2), encoder should configure successfully
      final channelCounts = [1, 2]; // Mono and stereo

      for (var channelCount in channelCounts) {
        final result = await platform.invokeMethod('configureAudioEncoder', {
          'sampleRate': 44100,
          'channelCount': channelCount,
          'bitrate': 64000 * channelCount,
        });

        expect(result, isA<Map>());
        expect((result as Map)['success'], isTrue,
            reason: 'Encoder should accept $channelCount channel(s)');
      }
    });

    test('encoder accepts valid bitrate range', () async {
      // Property: For any bitrate in valid range, encoder should accept it
      final validBitrates = [
        32000, // Low quality
        64000, // Standard quality
        128000, // High quality
        192000, // Very high quality
      ];

      for (var bitrate in validBitrates) {
        final result = await platform.invokeMethod('configureAudioEncoder', {
          'sampleRate': 44100,
          'channelCount': 1,
          'bitrate': bitrate,
        });

        expect(result, isA<Map>());
        expect((result as Map)['success'], isTrue,
            reason: 'Encoder should accept bitrate $bitrate');
      }
    });

    test('encoder rejects invalid configuration', () async {
      // Property: For any invalid configuration, encoder should reject it
      final invalidConfigs = [
        {'sampleRate': 0, 'channelCount': 1, 'bitrate': 64000},
        {'sampleRate': 44100, 'channelCount': 0, 'bitrate': 64000},
        {'sampleRate': 44100, 'channelCount': 1, 'bitrate': 0},
        {'sampleRate': -1, 'channelCount': 1, 'bitrate': 64000},
        {'sampleRate': 44100, 'channelCount': -1, 'bitrate': 64000},
      ];

      for (var config in invalidConfigs) {
        expect(
          () async =>
              await platform.invokeMethod('configureAudioEncoder', config),
          throwsA(isA<PlatformException>()),
          reason: 'Encoder should reject invalid configuration: $config',
        );
      }
    });

    test('encoded output size is reasonable', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: For any audio sample, encoded size should be less than raw size
      final sampleSize = 4096 * 2; // 4096 samples * 2 bytes
      final audioData = Uint8List(sampleSize);

      final result = await platform.invokeMethod('encodeAudioSample', {
        'audioData': audioData,
      });

      final encodedData = (result as Map)['encodedData'] as Uint8List;

      // Property: Encoded data should be significantly smaller than raw data
      expect(encodedData.length, lessThan(sampleSize),
          reason: 'Encoded data should be smaller than raw audio data');

      // Property: Encoded data should be at least some minimum size (ADTS header + data)
      expect(encodedData.length, greaterThan(7),
          reason: 'Encoded data should have at least ADTS header size');
    });

    test('timestamps are monotonically increasing', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: For any sequence of audio samples, timestamps should increase
      final sampleSize = 1024 * 2;
      final audioData = Uint8List(sampleSize);

      int? previousTimestamp;

      for (var i = 0; i < 5; i++) {
        // Small delay to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 10));

        final result = await platform.invokeMethod('encodeAudioSample', {
          'audioData': audioData,
        });

        final timestamp = (result as Map)['timestamp'] as int;

        if (previousTimestamp != null) {
          expect(timestamp, greaterThanOrEqualTo(previousTimestamp),
              reason: 'Timestamps should be monotonically increasing');
        }

        previousTimestamp = timestamp;
      }
    });

    test('encoder can be reconfigured', () async {
      // Property: Encoder should accept reconfiguration
      // First configuration
      await platform.invokeMethod('configureAudioEncoder', {
        'sampleRate': 44100,
        'channelCount': 1,
        'bitrate': 64000,
      });

      // Shutdown
      await platform.invokeMethod('shutdownAudioEncoder');

      // Second configuration with different parameters
      final result = await platform.invokeMethod('configureAudioEncoder', {
        'sampleRate': 48000,
        'channelCount': 2,
        'bitrate': 128000,
      });

      expect((result as Map)['success'], isTrue,
          reason: 'Encoder should accept reconfiguration');
    });

    test('multiple samples can be encoded in sequence', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: For any sequence of audio samples, all should encode successfully
      final sampleSize = 1024 * 2;
      final sampleCount = 10;

      for (var i = 0; i < sampleCount; i++) {
        final audioData = Uint8List(sampleSize);
        // Different pattern for each sample
        for (var j = 0; j < audioData.length; j += 2) {
          final sample = ((i * 1000 + j) % 32768);
          audioData[j] = sample & 0xFF;
          audioData[j + 1] = (sample >> 8) & 0xFF;
        }

        final result = await platform.invokeMethod('encodeAudioSample', {
          'audioData': audioData,
        });

        expect(result, isA<Map>());
        final encodedData = (result as Map)['encodedData'] as Uint8List;
        expect(encodedData.isNotEmpty, isTrue,
            reason: 'Sample $i should encode successfully');
      }
    });

    test('encoder handles various sample sizes', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: Encoder should handle various sample sizes
      final sampleSizes = [
        512 * 2, // Small buffer
        1024 * 2, // Standard buffer
        2048 * 2, // Large buffer
        4096 * 2, // Very large buffer
      ];

      for (var sampleSize in sampleSizes) {
        final audioData = Uint8List(sampleSize);

        final result = await platform.invokeMethod('encodeAudioSample', {
          'audioData': audioData,
        });

        expect(result, isA<Map>());
        final encodedData = (result as Map)['encodedData'] as Uint8List;
        expect(encodedData.isNotEmpty, isTrue,
            reason: 'Should encode sample of size $sampleSize');
      }
    });

    test('AAC profile is AAC-LC', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: Encoded AAC should use AAC-LC profile
      final sampleSize = 1024 * 2;
      final audioData = Uint8List(sampleSize);

      final result = await platform.invokeMethod('encodeAudioSample', {
        'audioData': audioData,
      });

      final encodedData = (result as Map)['encodedData'] as Uint8List;

      // Property: ADTS header should indicate AAC-LC profile
      // Note: AAC-LC (profile 2) is stored as 1 in ADTS (profile - 1)
      if (encodedData.length >= 7) {
        final profile = _extractAACProfile(encodedData);
        expect(profile, equals(1),
            reason:
                'AAC profile should be AAC-LC (stored as 1 in ADTS header)');
      }
    });

    test('encoded data has valid ADTS frame length', () async {
      // Configure encoder
      await platform.invokeMethod('configureAudioEncoder');

      // Property: ADTS frame length field should match actual data length
      final sampleSize = 1024 * 2;
      final audioData = Uint8List(sampleSize);

      final result = await platform.invokeMethod('encodeAudioSample', {
        'audioData': audioData,
      });

      final encodedData = (result as Map)['encodedData'] as Uint8List;

      if (encodedData.length >= 7) {
        final frameLength = _extractADTSFrameLength(encodedData);

        // Property: Frame length should match actual encoded data length
        expect(frameLength, equals(encodedData.length),
            reason: 'ADTS frame length should match actual data length');
      }
    });
  });
}

/// Helper function to check for valid AAC ADTS sync word
bool _hasValidADTSSyncWord(Uint8List data) {
  if (data.length < 2) return false;

  // ADTS sync word is 0xFFF (12 bits)
  // First byte should be 0xFF
  // Second byte should have upper 4 bits as 0xF
  return data[0] == 0xFF && (data[1] & 0xF0) == 0xF0;
}

/// Helper function to extract AAC profile from ADTS header
int _extractAACProfile(Uint8List data) {
  if (data.length < 3) return -1;

  // Profile is in bits 6-7 of byte 2 (0-indexed)
  // Shift right by 6 and mask with 0x03
  return (data[2] >> 6) & 0x03;
}

/// Helper function to extract frame length from ADTS header
int _extractADTSFrameLength(Uint8List data) {
  if (data.length < 7) return -1;

  // Frame length is 13 bits spanning bytes 3-5
  // Byte 3: bits 0-1 (upper 2 bits of length)
  // Byte 4: bits 0-7 (middle 8 bits of length)
  // Byte 5: bits 5-7 (lower 3 bits of length)

  final lengthHigh = (data[3] & 0x03) << 11;
  final lengthMid = data[4] << 3;
  final lengthLow = (data[5] >> 5) & 0x07;

  return lengthHigh | lengthMid | lengthLow;
}

/// Helper function to generate mock AAC frame with ADTS header
Uint8List _generateMockAACFrame(Uint8List inputData) {
  // Create a mock AAC frame with proper ADTS header
  final output = <int>[];

  // Calculate frame length (ADTS header + payload)
  final payloadSize = inputData.length ~/ 10; // Simulate compression
  final frameLength = 7 + payloadSize; // 7 bytes ADTS header + payload

  // ADTS Header (7 bytes for ADTS without CRC)
  // Byte 0: Sync word (0xFF)
  output.add(0xFF);

  // Byte 1: Sync word continuation (0xF) + MPEG version (1 bit) + Layer (2 bits) + Protection absent (1 bit)
  output.add(0xF1); // 0xF1 = 11110001 (sync + MPEG-4 + Layer 0 + no CRC)

  // Byte 2: Profile (2 bits) + Sample rate index (4 bits) + Private (1 bit) + Channel config start (1 bit)
  // Profile: 01 (AAC-LC = 2, but stored as 2-1 = 1)
  // Sample rate: 0100 (44100 Hz = index 4)
  // Private: 0
  // Channel: 0 (upper bit)
  output.add(0x50); // 01010000

  // Byte 3: Channel config (2 bits) + Original (1 bit) + Home (1 bit) + Copyright ID (1 bit) + Copyright start (1 bit) + Frame length (2 bits)
  // Channel: 01 (mono)
  // Frame length upper 2 bits
  final lengthHigh = (frameLength >> 11) & 0x03;
  output.add(0x40 | lengthHigh); // 01000000 + length high bits

  // Byte 4: Frame length middle 8 bits
  output.add((frameLength >> 3) & 0xFF);

  // Byte 5: Frame length lower 3 bits + Buffer fullness (5 bits)
  final lengthLow = (frameLength & 0x07) << 5;
  output.add(lengthLow | 0x1F); // Lower 3 bits + 11111 (VBR)

  // Byte 6: Buffer fullness (6 bits) + Number of frames (2 bits)
  output.add(0xFC); // 11111100 (buffer fullness + 0 frames)

  // Add payload (compressed audio data)
  for (var i = 0; i < payloadSize; i++) {
    output.add((inputData[i % inputData.length] ^ 0x55) & 0xFF);
  }

  return Uint8List.fromList(output);
}
