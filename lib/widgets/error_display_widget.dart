import 'package:flutter/material.dart';
import '../models/error_info.dart';
import '../controllers/streaming_controller.dart';

/// Widget for displaying error messages with troubleshooting steps
class ErrorDisplayWidget extends StatelessWidget {
  final String errorCode;
  final String? customMessage;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.errorCode,
    this.customMessage,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final controller = StreamingController();
    final message =
        customMessage ?? controller.getUserFriendlyMessage(errorCode);
    final steps = controller.getTroubleshootingSteps(errorCode);

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Troubleshooting Steps:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. '),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              );
            }),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying overheating warnings
class OverheatingWarningWidget extends StatelessWidget {
  final OverheatingWarning warning;
  final VoidCallback? onDismiss;

  const OverheatingWarningWidget({
    super.key,
    required this.warning,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!warning.isOverheating) {
      return const SizedBox.shrink();
    }

    final color = warning.isCritical ? Colors.red : Colors.orange;
    final icon = warning.isCritical ? Icons.warning : Icons.warning_amber;

    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: color.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning.isCritical
                        ? 'Critical: Device Overheating'
                        : 'Warning: Device Temperature High',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Device temperature: ${warning.temperature.toStringAsFixed(1)}°C',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...warning.suggestions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• '),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying encoder fallback information
class EncoderFallbackWidget extends StatelessWidget {
  final EncoderInfo encoderInfo;
  final VoidCallback? onDismiss;

  const EncoderFallbackWidget({
    super.key,
    required this.encoderInfo,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (!encoderInfo.fallbackOccurred) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using Software Encoding',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              encoderInfo.fallbackReason ??
                  'Hardware encoder initialization failed. Using software encoding instead.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Software encoding may use more battery and CPU. Consider reducing resolution or frame rate for better performance.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying error logs
class ErrorLogsWidget extends StatefulWidget {
  const ErrorLogsWidget({super.key});

  @override
  State<ErrorLogsWidget> createState() => _ErrorLogsWidgetState();
}

class _ErrorLogsWidgetState extends State<ErrorLogsWidget> {
  final StreamingController _controller = StreamingController();
  List<ErrorInfo> _logs = [];
  bool _loading = true;
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    try {
      final logs = await _controller.getErrorLogs(
        limit: 50,
        errorType: _filterType,
      );
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _clearLogs() async {
    await _controller.clearErrorLogs();
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Error Logs',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadLogs,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _clearLogs,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_logs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No error logs'),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                    ),
                    title: Text(log.errorCode),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.message),
                        const SizedBox(height: 4),
                        Text(
                          '${log.component} • ${log.timestamp}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
