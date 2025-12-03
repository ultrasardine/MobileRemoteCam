/// Represents a video resolution
class Resolution {
  final int width;
  final int height;

  Resolution({required this.width, required this.height});

  String get displayName => '${width}x$height';

  String get commonName {
    if (width == 1280 && height == 720) return '720p';
    if (width == 1920 && height == 1080) return '1080p';
    if (width == 3840 && height == 2160) return '4K';
    return displayName;
  }

  Map<String, dynamic> toMap() {
    return {'width': width, 'height': height};
  }

  factory Resolution.fromMap(Map<String, dynamic> map) {
    return Resolution(width: map['width'] as int, height: map['height'] as int);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Resolution &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => width.hashCode ^ height.hashCode;
}
