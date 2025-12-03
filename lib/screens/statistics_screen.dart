import 'package:flutter/material.dart';
import 'dart:async';
import '../controllers/streaming_controller.dart';
import '../models/stream_statistics.dart';

/// Statistics screen with real-time updates
/// Displays current bitrate, FPS, dropped frames, connection status,
/// and warning indicators for temperature and battery
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StreamingController _controller = StreamingController();
  StreamStatistics? _statistics;
  Timer? _updateTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startStatisticsUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Start periodic statistics updates at 1 Hz (once per second)
  void _startStatisticsUpdates() {
    _updateStatistics();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStatistics();
    });
  }

  /// Fetch current statistics from the controller
  Future<void> _updateStatistics() async {
    try {
      final stats = await _controller.getStatistics();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to get statistics: $e';
        });
      }
    }
  }

  /// Check if temperature warning should be shown
  bool get _showTemperatureWarning {
    return _statistics != null && _statistics!.deviceTemperature > 45.0;
  }

  /// Check if battery warning should be shown
  bool get _showBatteryWarning {
    return _statistics != null && _statistics!.batteryLevel < 15;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _statistics == null && _errorMessage == null
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _updateStatistics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _updateStatistics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Warning indicators section
                      if (_showTemperatureWarning || _showBatteryWarning)
                        _buildWarningsCard(),

                      // Performance metrics section
                      _buildPerformanceCard(),

                      const SizedBox(height: 16),

                      // Connection status section
                      _buildConnectionCard(),

                      const SizedBox(height: 16),

                      // Device status section
                      _buildDeviceCard(),
                    ],
                  ),
                ),
    );
  }

  /// Build warnings card for temperature and battery
  Widget _buildWarningsCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Performance Warnings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_showTemperatureWarning)
              _buildWarningItem(
                Icons.thermostat,
                'High Temperature',
                'Device temperature is ${_statistics!.deviceTemperature.toStringAsFixed(1)}°C',
                'Consider reducing resolution or frame rate',
              ),
            if (_showTemperatureWarning && _showBatteryWarning)
              const SizedBox(height: 8),
            if (_showBatteryWarning)
              _buildWarningItem(
                Icons.battery_alert,
                'Low Battery',
                'Battery level is ${_statistics!.batteryLevel}%',
                'Connect to power or stop streaming',
              ),
          ],
        ),
      ),
    );
  }

  /// Build individual warning item
  Widget _buildWarningItem(
    IconData icon,
    String title,
    String message,
    String suggestion,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                message,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                suggestion,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build performance metrics card
  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              Icons.speed,
              'Bitrate',
              '${_statistics!.currentBitrate.toStringAsFixed(2)} Mbps',
              Colors.blue,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              Icons.videocam,
              'Frame Rate',
              '${_statistics!.currentFps} fps',
              Colors.green,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              Icons.warning_amber,
              'Dropped Frames',
              '${_statistics!.droppedFrames}',
              _statistics!.droppedFrames > 10 ? Colors.orange : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  /// Build connection status card
  Widget _buildConnectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ..._statistics!.connectionStatus.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildConnectionRow(
                  entry.key.toUpperCase(),
                  entry.value,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build device status card
  Widget _buildDeviceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              Icons.thermostat,
              'Temperature',
              '${_statistics!.deviceTemperature.toStringAsFixed(1)}°C',
              _showTemperatureWarning ? Colors.orange : Colors.grey,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              Icons.battery_std,
              'Battery',
              '${_statistics!.batteryLevel}%',
              _showBatteryWarning ? Colors.orange : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a metric row with icon, label, and value
  Widget _buildMetricRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Build a connection status row
  Widget _buildConnectionRow(String protocol, ConnectionStatus status) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        statusText = 'Connecting';
        break;
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Disconnected';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Error';
        break;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            protocol,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
