/// RTMP streaming target configuration
class RtmpTarget {
  final String url;
  final String streamKey;
  final bool enabled;

  RtmpTarget({
    required this.url,
    required this.streamKey,
    required this.enabled,
  });

  Map<String, dynamic> toMap() {
    return {'url': url, 'streamKey': streamKey, 'enabled': enabled};
  }

  factory RtmpTarget.fromMap(Map<String, dynamic> map) {
    return RtmpTarget(
      url: map['url'] as String,
      streamKey: map['streamKey'] as String,
      enabled: map['enabled'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RtmpTarget &&
        other.url == url &&
        other.streamKey == streamKey &&
        other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(url, streamKey, enabled);
}
