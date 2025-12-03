import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stream_config.dart';
import '../models/resolution.dart';
import '../models/camera_info.dart';
import '../models/rtmp_target.dart';
import '../models/streaming_mode.dart';
import '../controllers/streaming_controller.dart';
import '../services/settings_persistence_service.dart';
import '../services/rtmp_storage_service.dart';
import 'rtmp_setup_screen.dart';

/// Configuration screen for streaming parameters
class ConfigurationScreen extends StatefulWidget {
  final StreamConfig? currentConfig;

  const ConfigurationScreen({super.key, this.currentConfig});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final StreamingController _controller = StreamingController();
  final NetworkInfo _networkInfo = NetworkInfo();

  late String _cameraId;
  late Resolution _resolution;
  late int _frameRate;
  late double _bitrate; // in Mbps
  late bool _audioEnabled;
  late bool _rtspEnabled;
  late int _rtspPort;
  List<RtmpTarget> _rtmpTargets = [];
  late StreamingMode _streamingMode;

  // Available options
  List<CameraInfo> _availableCameras = [];
  List<Resolution> _availableResolutions = [
    Resolution(width: 1280, height: 720),
    Resolution(width: 1920, height: 1080),
    Resolution(width: 3840, height: 2160),
  ];

  final List<int> _availableFrameRates = [30, 60];

  bool _isLoading = true;
  String? _errorMessage;
  String? _deviceIp;

  @override
  void initState() {
    super.initState();
    // Initialize with current config or defaults
    _cameraId = widget.currentConfig?.cameraId ?? '0';
    _resolution = widget.currentConfig?.resolution ??
        Resolution(width: 1920, height: 1080);
    _frameRate = widget.currentConfig?.frameRate ?? 30;
    _bitrate = (widget.currentConfig?.bitrate ?? 5000000) /
        1000000.0; // Convert to Mbps
    _audioEnabled = widget.currentConfig?.audioEnabled ?? false;
    _rtspEnabled = widget.currentConfig?.rtspEnabled ?? true;
    _rtspPort = widget.currentConfig?.rtspPort ?? 8554;
    _rtmpTargets = widget.currentConfig?.rtmpTargets ?? [];

    // Determine streaming mode from current config
    _streamingMode = StreamingModeExtension.fromEnabledStates(
      rtspEnabled: _rtspEnabled,
      hasEnabledRtmpTargets: _rtmpTargets.any((t) => t.enabled),
    );

    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await _controller.getCameras();

      // Get device IP address
      String? ip;
      try {
        ip = await _networkInfo.getWifiIP();
      } catch (e) {
        // If WiFi IP is not available, try to get any IP
        ip = null;
      }

      setState(() {
        _availableCameras = cameras;
        _deviceIp = ip;
        _isLoading = false;

        // If current camera ID is not in the list, use the first available
        if (cameras.isNotEmpty && !cameras.any((c) => c.id == _cameraId)) {
          _cameraId = cameras.first.id;
        }
      });

      // Load resolutions for the selected camera
      await _loadResolutionsForCamera(_cameraId);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load cameras: $e';
      });
    }
  }

  Future<void> _loadResolutionsForCamera(String cameraId) async {
    try {
      final resolutions = await _controller.getResolutions(cameraId);
      setState(() {
        _availableResolutions = resolutions;

        // If current resolution is not available, use the first one
        if (resolutions.isNotEmpty &&
            !resolutions.any((r) => r == _resolution)) {
          _resolution = resolutions.first;
        }
      });
    } catch (e) {
      // If we can't get resolutions, keep the default list
      setState(() {
        _availableResolutions = [
          Resolution(width: 1280, height: 720),
          Resolution(width: 1920, height: 1080),
          Resolution(width: 3840, height: 2160),
        ];
      });
    }
  }

  Future<void> _onCameraChanged(String? newCameraId) async {
    if (newCameraId == null || newCameraId == _cameraId) return;

    setState(() {
      _cameraId = newCameraId;
    });

    // Load resolutions for the new camera
    await _loadResolutionsForCamera(newCameraId);
  }

  /// Check if a streaming mode can be selected
  bool _canSelectMode(StreamingMode mode) {
    // RTSP-only is always available
    if (mode == StreamingMode.rtspOnly) {
      return true;
    }

    // RTMP modes require at least one configured RTMP target
    final hasRtmpTargets = _rtmpTargets.isNotEmpty;
    return hasRtmpTargets;
  }

  /// Handle streaming mode change
  void _onStreamingModeChanged(StreamingMode mode) {
    setState(() {
      _streamingMode = mode;

      // Update RTSP and RTMP enabled states based on mode
      _rtspEnabled = mode.rtspEnabled;

      // For RTMP modes, ensure at least one target is enabled
      if (mode.rtmpEnabled && _rtmpTargets.isNotEmpty) {
        // If no targets are enabled, enable the first one
        if (!_rtmpTargets.any((t) => t.enabled)) {
          _rtmpTargets = _rtmpTargets.map((t) {
            if (t == _rtmpTargets.first) {
              return RtmpTarget(
                url: t.url,
                streamKey: t.streamKey,
                enabled: true,
              );
            }
            return t;
          }).toList();
        }
      } else if (!mode.rtmpEnabled) {
        // Disable all RTMP targets when not in RTMP mode
        _rtmpTargets = _rtmpTargets.map((t) {
          return RtmpTarget(
            url: t.url,
            streamKey: t.streamKey,
            enabled: false,
          );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stream Configuration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Stream Configuration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadCameras();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_data') {
                _showClearDataDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_data',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 8),
                    Text('Clear All Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Camera selection
          if (_availableCameras.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Camera',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _cameraId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _availableCameras.map((camera) {
                        return DropdownMenuItem<String>(
                          value: camera.id,
                          child: Row(
                            children: [
                              Icon(
                                camera.position == CameraPosition.front
                                    ? Icons.camera_front
                                    : camera.position == CameraPosition.back
                                        ? Icons.camera_rear
                                        : Icons.camera,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(camera.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _onCameraChanged,
                    ),
                  ],
                ),
              ),
            ),
          if (_availableCameras.isNotEmpty) const SizedBox(height: 16),

          // Resolution selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resolution',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableResolutions.map((res) {
                      final isSelected = res == _resolution;
                      return ChoiceChip(
                        label: Text(res.commonName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _resolution = res;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Frame rate selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frame Rate',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: _availableFrameRates
                        .map((fps) => ButtonSegment<int>(
                              value: fps,
                              label: Text('$fps FPS'),
                            ))
                        .toList(),
                    selected: {_frameRate},
                    onSelectionChanged: (Set<int> selected) {
                      setState(() {
                        _frameRate = selected.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bitrate slider
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bitrate: ${_bitrate.toStringAsFixed(1)} Mbps',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Slider(
                    value: _bitrate,
                    min: 1.0,
                    max: 10.0,
                    divisions: 90,
                    label: '${_bitrate.toStringAsFixed(1)} Mbps',
                    onChanged: (value) {
                      setState(() {
                        _bitrate = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Audio toggle
          Card(
            child: SwitchListTile(
              title: const Text('Audio Enabled'),
              subtitle: const Text('Include audio in stream'),
              value: _audioEnabled,
              onChanged: (value) async {
                if (value) {
                  // Request microphone permission when enabling audio
                  try {
                    final hasPermission =
                        await _controller.hasMicrophonePermission();
                    if (!hasPermission) {
                      final granted =
                          await _controller.requestMicrophonePermission();
                      if (!granted) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Microphone permission is required to enable audio'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        return;
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Failed to request microphone permission: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                    return;
                  }
                }
                setState(() {
                  _audioEnabled = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Streaming Mode Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streaming Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose which protocols to use for streaming',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...StreamingMode.values.map((mode) {
                    final isSelected = _streamingMode == mode;
                    final canSelect = _canSelectMode(mode);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: canSelect
                            ? () => _onStreamingModeChanged(mode)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.3)
                                : canSelect
                                    ? null
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.3),
                          ),
                          child: Row(
                            children: [
                              Text(
                                mode.icon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mode.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: canSelect
                                                ? null
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mode.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: canSelect
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.7)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withOpacity(0.4),
                                          ),
                                    ),
                                    if (!canSelect &&
                                        mode == StreamingMode.rtmpOnly) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Configure RTMP targets first',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                    if (!canSelect &&
                                        mode == StreamingMode.simultaneous) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Configure RTMP targets first',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontStyle: FontStyle.italic,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RTSP settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('RTSP Enabled'),
                    subtitle: const Text('Enable local network streaming'),
                    value: _rtspEnabled,
                    onChanged: (value) {
                      setState(() {
                        _rtspEnabled = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_rtspEnabled) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'RTSP Port',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: _rtspPort.toString()),
                      onChanged: (value) {
                        final port = int.tryParse(value);
                        if (port != null && port >= 1024 && port <= 65535) {
                          _rtspPort = port;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Stream URL',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _copyStreamUrlToClipboard(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getStreamUrl(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.copy,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to copy to clipboard',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RTMP settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'RTMP Streaming',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_rtmpTargets.isNotEmpty)
                        Chip(
                          label: Text(
                              '${_rtmpTargets.where((t) => t.enabled).length} active'),
                          avatar: const Icon(Icons.cloud_upload, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stream to YouTube, Twitch, and other platforms',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _openRtmpSetup,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure RTMP Targets'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save button
          ElevatedButton(
            onPressed: _saveConfiguration,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Configuration'),
          ),
        ],
      ),
    );
  }

  String _getStreamUrl() {
    final ip = _deviceIp ?? '0.0.0.0';
    return 'rtsp://$ip:$_rtspPort/live';
  }

  Future<void> _copyStreamUrlToClipboard() async {
    final url = _getStreamUrl();
    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stream URL copied to clipboard: $url'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openRtmpSetup() async {
    final targets = await Navigator.push<List<RtmpTarget>>(
      context,
      MaterialPageRoute(
        builder: (context) => RtmpSetupScreen(
          currentTargets: _rtmpTargets,
        ),
      ),
    );

    if (targets != null) {
      setState(() {
        _rtmpTargets = targets;

        // Recalculate streaming mode based on new targets
        final hasEnabledRtmpTargets = _rtmpTargets.any((t) => t.enabled);
        _streamingMode = StreamingModeExtension.fromEnabledStates(
          rtspEnabled: _rtspEnabled,
          hasEnabledRtmpTargets: hasEnabledRtmpTargets,
        );

        // Update enabled states to match mode
        _rtspEnabled = _streamingMode.rtspEnabled;
      });
    }
  }

  void _saveConfiguration() {
    final config = StreamConfig(
      cameraId: _cameraId,
      resolution: _resolution,
      frameRate: _frameRate,
      bitrate: (_bitrate * 1000000).toInt(), // Convert Mbps to bps
      audioEnabled: _audioEnabled,
      rtspEnabled: _rtspEnabled,
      rtspPort: _rtspPort,
      rtmpTargets: _rtmpTargets,
    );

    Navigator.pop(context, config);
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will reset all settings to their default values and clear all saved RTMP credentials. This action cannot be undone.\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _clearAllData();
    }
  }

  Future<void> _clearAllData() async {
    try {
      // Clear settings
      final prefs = await SharedPreferences.getInstance();
      final settingsService = SettingsPersistenceService(prefs);
      await settingsService.clearAllSettings();

      // Clear RTMP credentials
      final rtmpService = RtmpStorageService();
      await rtmpService.clearAll();

      // Reset to defaults
      setState(() {
        _cameraId = SettingsPersistenceService.defaultCameraId;
        _resolution = Resolution(
          width: SettingsPersistenceService.defaultResolutionWidth,
          height: SettingsPersistenceService.defaultResolutionHeight,
        );
        _frameRate = SettingsPersistenceService.defaultFrameRate;
        _bitrate = SettingsPersistenceService.defaultBitrate / 1000000.0;
        _audioEnabled = SettingsPersistenceService.defaultAudioEnabled;
        _rtspEnabled = SettingsPersistenceService.defaultRtspEnabled;
        _rtspPort = SettingsPersistenceService.defaultRtspPort;
        _rtmpTargets = [];
        _streamingMode = StreamingMode.rtspOnly; // Default mode
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared and settings reset to defaults'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
