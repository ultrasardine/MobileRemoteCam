import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/streaming_controller.dart';
import 'models/stream_config.dart';
import 'models/resolution.dart';
import 'screens/configuration_screen.dart';
import 'screens/statistics_screen.dart';
import 'services/settings_persistence_service.dart';
import 'services/rtmp_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IPCameraApp());
}

class IPCameraApp extends StatelessWidget {
  const IPCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Camera Streaming',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final StreamingController _controller = StreamingController();
  bool _isStreaming = false;
  String _statusMessage = 'Ready to stream';
  StreamConfig? _currentConfig;
  SettingsPersistenceService? _settingsService;
  RtmpStorageService? _rtmpStorageService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      // Initialize services
      final prefs = await SharedPreferences.getInstance();
      _settingsService = SettingsPersistenceService(prefs);
      _rtmpStorageService = RtmpStorageService();

      // Restore settings
      final cameraId = _settingsService!.loadCameraId();
      final resolution = _settingsService!.loadResolution();
      final frameRate = _settingsService!.loadFrameRate();
      final bitrate = _settingsService!.loadBitrate();
      final audioEnabled = _settingsService!.loadAudioEnabled();
      final rtspEnabled = _settingsService!.loadRtspEnabled();
      final rtspPort = _settingsService!.loadRtspPort();
      final rtmpTargets = await _rtmpStorageService!.loadTargets();

      setState(() {
        _currentConfig = StreamConfig(
          cameraId: cameraId,
          resolution: resolution,
          frameRate: frameRate,
          bitrate: bitrate,
          audioEnabled: audioEnabled,
          rtspEnabled: rtspEnabled,
          rtspPort: rtspPort,
          rtmpTargets: rtmpTargets,
        );
        _isInitialized = true;
        _statusMessage = 'Settings restored';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to restore settings: $e';
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('IP Camera Streaming'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _openStatistics,
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openConfiguration,
            tooltip: 'Configuration',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview placeholder
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Center(
                child: _isStreaming
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Camera Preview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white54),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_off,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Preview',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: Colors.white24),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          // Status and controls
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isStreaming ? _stopStreaming : _startStreaming,
                    icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                    label: Text(
                        _isStreaming ? 'Stop Streaming' : 'Start Streaming'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                  ),
                  if (_currentConfig != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Config: ${_currentConfig!.resolution.commonName} @ ${_currentConfig!.frameRate}fps',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startStreaming() async {
    try {
      // Use current config or default
      final config = _currentConfig ??
          StreamConfig(
            cameraId: '0',
            resolution: Resolution(width: 1920, height: 1080),
            frameRate: 30,
            bitrate: 5000000,
            audioEnabled: false,
            rtspEnabled: true,
            rtspPort: 8554,
            rtmpTargets: [],
          );

      await _controller.startStreaming(config);
      setState(() {
        _isStreaming = true;
        _statusMessage = 'Streaming...';
        _currentConfig = config;
      });
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _stopStreaming() async {
    try {
      await _controller.stopStreaming();
      setState(() {
        _isStreaming = false;
        _statusMessage = 'Stopped';
      });
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.message}';
      });
    }
  }

  Future<void> _openConfiguration() async {
    final config = await Navigator.push<StreamConfig>(
      context,
      MaterialPageRoute(
        builder: (context) => ConfigurationScreen(
          currentConfig: _currentConfig,
        ),
      ),
    );

    if (config != null) {
      await _handleConfigurationChange(config);
    }
  }

  /// Handle configuration changes with automatic restart if streaming
  Future<void> _handleConfigurationChange(StreamConfig newConfig) async {
    final wasStreaming = _isStreaming;
    final oldConfig = _currentConfig;

    // Check if configuration actually changed
    final configChanged = oldConfig == null || oldConfig != newConfig;

    // Save settings to persistence
    await _saveSettings(newConfig);

    setState(() {
      _currentConfig = newConfig;
      _statusMessage = configChanged
          ? 'Configuration updated'
          : 'Configuration saved (no changes)';
    });

    // If streaming and configuration changed, restart the stream
    if (wasStreaming && configChanged) {
      await _restartStreamingWithNewConfig(newConfig);
    }
  }

  /// Restart streaming with new configuration ensuring minimal interruption
  Future<void> _restartStreamingWithNewConfig(StreamConfig newConfig) async {
    setState(() {
      _statusMessage = 'Restarting stream with new configuration...';
    });

    try {
      // Stop current stream
      await _controller.stopStreaming();

      // Brief delay to ensure clean shutdown
      await Future.delayed(const Duration(milliseconds: 300));

      // Start with new configuration
      await _controller.startStreaming(newConfig);

      setState(() {
        _isStreaming = true;
        _statusMessage = 'Streaming with updated configuration';
        _currentConfig = newConfig;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stream restarted with new configuration'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PlatformException catch (e) {
      setState(() {
        _isStreaming = false;
        _statusMessage = 'Failed to restart: ${e.message}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restart stream: ${e.message}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _restartStreamingWithNewConfig(newConfig),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings(StreamConfig config) async {
    if (_settingsService == null || _rtmpStorageService == null) return;

    try {
      await _settingsService!.saveCameraId(config.cameraId);
      await _settingsService!.saveResolution(config.resolution);
      await _settingsService!.saveFrameRate(config.frameRate);
      await _settingsService!.saveBitrate(config.bitrate);
      await _settingsService!.saveAudioEnabled(config.audioEnabled);
      await _settingsService!.saveRtspEnabled(config.rtspEnabled);
      await _settingsService!.saveRtspPort(config.rtspPort);
      await _rtmpStorageService!.saveTargets(config.rtmpTargets);
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  void _openStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StatisticsScreen(),
      ),
    );
  }
}
