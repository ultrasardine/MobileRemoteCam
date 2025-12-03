/// Error information model for comprehensive error tracking
class ErrorInfo {
  final String timestamp;
  final String errorType;
  final String errorCode;
  final String message;
  final Map<String, dynamic>? details;
  final String? stackTrace;
  final String component;

  ErrorInfo({
    required this.timestamp,
    required this.errorType,
    required this.errorCode,
    required this.message,
    this.details,
    this.stackTrace,
    required this.component,
  });

  factory ErrorInfo.fromMap(Map<String, dynamic> map) {
    return ErrorInfo(
      timestamp: map['timestamp'] as String,
      errorType: map['errorType'] as String,
      errorCode: map['errorCode'] as String,
      message: map['message'] as String,
      details: map['details'] as Map<String, dynamic>?,
      stackTrace: map['stackTrace'] as String?,
      component: map['component'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'errorType': errorType,
      'errorCode': errorCode,
      'message': message,
      'details': details,
      'stackTrace': stackTrace,
      'component': component,
    };
  }

  @override
  String toString() {
    return 'ErrorInfo{timestamp: $timestamp, errorCode: $errorCode, message: $message, component: $component}';
  }
}

/// Overheating warning information
class OverheatingWarning {
  final bool isOverheating;
  final double temperature;
  final String warningLevel; // 'normal', 'warning', 'critical'
  final List<String> suggestions;

  OverheatingWarning({
    required this.isOverheating,
    required this.temperature,
    required this.warningLevel,
    required this.suggestions,
  });

  factory OverheatingWarning.fromMap(Map<String, dynamic> map) {
    return OverheatingWarning(
      isOverheating: map['isOverheating'] as bool,
      temperature: (map['temperature'] as num).toDouble(),
      warningLevel: map['warningLevel'] as String,
      suggestions: (map['suggestions'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOverheating': isOverheating,
      'temperature': temperature,
      'warningLevel': warningLevel,
      'suggestions': suggestions,
    };
  }

  bool get isCritical => warningLevel == 'critical';
  bool get isWarning => warningLevel == 'warning';
  bool get isNormal => warningLevel == 'normal';
}

/// Encoder information including fallback status
class EncoderInfo {
  final String currentEncoderType; // 'hardware' or 'software'
  final bool hardwareAvailable;
  final bool softwareAvailable;
  final bool fallbackOccurred;
  final String? fallbackReason;

  EncoderInfo({
    required this.currentEncoderType,
    required this.hardwareAvailable,
    required this.softwareAvailable,
    this.fallbackOccurred = false,
    this.fallbackReason,
  });

  factory EncoderInfo.fromMap(Map<String, dynamic> map) {
    return EncoderInfo(
      currentEncoderType: map['currentEncoderType'] as String,
      hardwareAvailable: map['hardwareAvailable'] as bool,
      softwareAvailable: map['softwareAvailable'] as bool,
      fallbackOccurred: map['fallbackOccurred'] as bool? ?? false,
      fallbackReason: map['fallbackReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentEncoderType': currentEncoderType,
      'hardwareAvailable': hardwareAvailable,
      'softwareAvailable': softwareAvailable,
      'fallbackOccurred': fallbackOccurred,
      'fallbackReason': fallbackReason,
    };
  }

  bool get isUsingHardware => currentEncoderType == 'hardware';
  bool get isUsingSoftware => currentEncoderType == 'software';
}

/// Overheating thresholds configuration
class OverheatingThresholds {
  final double warningThreshold;
  final double criticalThreshold;
  final double shutdownThreshold;

  OverheatingThresholds({
    required this.warningThreshold,
    required this.criticalThreshold,
    required this.shutdownThreshold,
  });

  factory OverheatingThresholds.fromMap(Map<String, dynamic> map) {
    return OverheatingThresholds(
      warningThreshold: (map['warningThreshold'] as num).toDouble(),
      criticalThreshold: (map['criticalThreshold'] as num).toDouble(),
      shutdownThreshold: (map['shutdownThreshold'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'warningThreshold': warningThreshold,
      'criticalThreshold': criticalThreshold,
      'shutdownThreshold': shutdownThreshold,
    };
  }

  /// Default thresholds based on requirements
  static OverheatingThresholds get defaults => OverheatingThresholds(
        warningThreshold: 50.0,
        criticalThreshold: 60.0,
        shutdownThreshold: 70.0,
      );
}
