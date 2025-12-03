/// Information about an available camera
class CameraInfo {
  final String id;
  final String name;
  final CameraPosition position;
  final List<String> capabilities;

  CameraInfo({
    required this.id,
    required this.name,
    required this.position,
    required this.capabilities,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position.name,
      'capabilities': capabilities,
    };
  }

  factory CameraInfo.fromMap(Map<String, dynamic> map) {
    return CameraInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      position: CameraPosition.values.firstWhere(
        (e) => e.name == map['position'],
        orElse: () => CameraPosition.back,
      ),
      capabilities: List<String>.from(map['capabilities'] as List),
    );
  }
}

enum CameraPosition { front, back, external }
