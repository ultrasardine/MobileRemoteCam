/// Real-time streaming statistics
class StreamStatistics {
  final double currentBitrate;
  final int currentFps;
  final int droppedFrames;
  final double deviceTemperature;
  final int batteryLevel;
  final Map<String, ConnectionStatus> connectionStatus;

  StreamStatistics({
    required this.currentBitrate,
    required this.currentFps,
    required this.droppedFrames,
    required this.deviceTemperature,
    required this.batteryLevel,
    required this.connectionStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentBitrate': currentBitrate,
      'currentFps': currentFps,
      'droppedFrames': droppedFrames,
      'deviceTemperature': deviceTemperature,
      'batteryLevel': batteryLevel,
      'connectionStatus': connectionStatus.map(
        (key, value) => MapEntry(key, value.name),
      ),
    };
  }

  factory StreamStatistics.fromMap(Map<String, dynamic> map) {
    final connStatusMap = map['connectionStatus'] as Map<dynamic, dynamic>;
    final connectionStatusConverted = Map<String, ConnectionStatus>.fromEntries(
      connStatusMap.entries.map((entry) => MapEntry(
            entry.key.toString(),
            ConnectionStatus.values.firstWhere(
              (e) => e.name == entry.value.toString(),
              orElse: () => ConnectionStatus.disconnected,
            ),
          )),
    );

    return StreamStatistics(
      currentBitrate: (map['currentBitrate'] as num).toDouble(),
      currentFps: map['currentFps'] as int,
      droppedFrames: map['droppedFrames'] as int,
      deviceTemperature: (map['deviceTemperature'] as num).toDouble(),
      batteryLevel: map['batteryLevel'] as int,
      connectionStatus: connectionStatusConverted,
    );
  }
}

enum ConnectionStatus { disconnected, connecting, connected, error }
