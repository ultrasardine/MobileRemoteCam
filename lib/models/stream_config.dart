import 'resolution.dart';
import 'rtmp_target.dart';

/// Configuration data structure for streaming operations
class StreamConfig {
  final String cameraId;
  final Resolution resolution;
  final int frameRate;
  final int bitrate;
  final bool audioEnabled;
  final bool rtspEnabled;
  final int rtspPort;
  final List<RtmpTarget> rtmpTargets;

  StreamConfig({
    required this.cameraId,
    required this.resolution,
    required this.frameRate,
    required this.bitrate,
    required this.audioEnabled,
    required this.rtspEnabled,
    required this.rtspPort,
    required this.rtmpTargets,
  });

  Map<String, dynamic> toMap() {
    return {
      'cameraId': cameraId,
      'resolution': resolution.toMap(),
      'frameRate': frameRate,
      'bitrate': bitrate,
      'audioEnabled': audioEnabled,
      'rtspEnabled': rtspEnabled,
      'rtspPort': rtspPort,
      'rtmpTargets': rtmpTargets.map((t) => t.toMap()).toList(),
    };
  }

  factory StreamConfig.fromMap(Map<String, dynamic> map) {
    return StreamConfig(
      cameraId: map['cameraId'] as String,
      resolution: Resolution.fromMap(map['resolution'] as Map<String, dynamic>),
      frameRate: map['frameRate'] as int,
      bitrate: map['bitrate'] as int,
      audioEnabled: map['audioEnabled'] as bool,
      rtspEnabled: map['rtspEnabled'] as bool,
      rtspPort: map['rtspPort'] as int,
      rtmpTargets: (map['rtmpTargets'] as List<dynamic>)
          .map((t) => RtmpTarget.fromMap(t as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StreamConfig) return false;

    return cameraId == other.cameraId &&
        resolution == other.resolution &&
        frameRate == other.frameRate &&
        bitrate == other.bitrate &&
        audioEnabled == other.audioEnabled &&
        rtspEnabled == other.rtspEnabled &&
        rtspPort == other.rtspPort &&
        _rtmpTargetsEqual(rtmpTargets, other.rtmpTargets);
  }

  @override
  int get hashCode {
    return Object.hash(
      cameraId,
      resolution,
      frameRate,
      bitrate,
      audioEnabled,
      rtspEnabled,
      rtspPort,
      Object.hashAll(rtmpTargets),
    );
  }

  bool _rtmpTargetsEqual(List<RtmpTarget> a, List<RtmpTarget> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Creates a copy of this config with the specified fields replaced
  StreamConfig copyWith({
    String? cameraId,
    Resolution? resolution,
    int? frameRate,
    int? bitrate,
    bool? audioEnabled,
    bool? rtspEnabled,
    int? rtspPort,
    List<RtmpTarget>? rtmpTargets,
  }) {
    return StreamConfig(
      cameraId: cameraId ?? this.cameraId,
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
      bitrate: bitrate ?? this.bitrate,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      rtspEnabled: rtspEnabled ?? this.rtspEnabled,
      rtspPort: rtspPort ?? this.rtspPort,
      rtmpTargets: rtmpTargets ?? this.rtmpTargets,
    );
  }
}
