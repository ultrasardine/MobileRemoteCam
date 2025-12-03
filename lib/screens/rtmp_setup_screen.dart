import 'package:flutter/material.dart';
import '../models/rtmp_target.dart';
import '../services/rtmp_storage_service.dart';

/// RTMP setup screen for configuring YouTube and Twitch streaming targets
class RtmpSetupScreen extends StatefulWidget {
  final List<RtmpTarget> currentTargets;

  const RtmpSetupScreen({super.key, required this.currentTargets});

  @override
  State<RtmpSetupScreen> createState() => _RtmpSetupScreenState();
}

class _RtmpSetupScreenState extends State<RtmpSetupScreen> {
  final _storageService = RtmpStorageService();

  // YouTube configuration
  final _youtubeUrlController = TextEditingController();
  final _youtubeKeyController = TextEditingController();
  bool _youtubeEnabled = false;

  // Twitch configuration
  final _twitchUrlController = TextEditingController();
  final _twitchKeyController = TextEditingController();
  bool _twitchEnabled = false;

  bool _isLoading = true;
  bool _obscureYoutubeKey = true;
  bool _obscureTwitchKey = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    _youtubeKeyController.dispose();
    _twitchUrlController.dispose();
    _twitchKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    try {
      final targets = await _storageService.loadTargets();

      setState(() {
        // Find YouTube target
        final youtubeTarget = targets.firstWhere(
          (t) => t.url.contains('youtube.com'),
          orElse: () => RtmpTarget(
            url: 'rtmp://a.rtmp.youtube.com/live2',
            streamKey: '',
            enabled: false,
          ),
        );

        _youtubeUrlController.text = youtubeTarget.url;
        _youtubeKeyController.text = youtubeTarget.streamKey;
        _youtubeEnabled = youtubeTarget.enabled;

        // Find Twitch target
        final twitchTarget = targets.firstWhere(
          (t) => t.url.contains('twitch.tv'),
          orElse: () => RtmpTarget(
            url: 'rtmp://live.twitch.tv/app',
            streamKey: '',
            enabled: false,
          ),
        );

        _twitchUrlController.text = twitchTarget.url;
        _twitchKeyController.text = twitchTarget.streamKey;
        _twitchEnabled = twitchTarget.enabled;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load configuration: $e')),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      // Build target list
      final targets = <RtmpTarget>[];

      if (_youtubeEnabled && _youtubeKeyController.text.isNotEmpty) {
        targets.add(RtmpTarget(
          url: _youtubeUrlController.text,
          streamKey: _youtubeKeyController.text,
          enabled: true,
        ));
      }

      if (_twitchEnabled && _twitchKeyController.text.isNotEmpty) {
        targets.add(RtmpTarget(
          url: _twitchUrlController.text,
          streamKey: _twitchKeyController.text,
          enabled: true,
        ));
      }

      // Save to secure storage
      await _storageService.saveTargets(targets);

      if (mounted) {
        Navigator.pop(context, targets);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save configuration: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RTMP Configuration'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('RTMP Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // YouTube section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'YouTube Live',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Switch(
                        value: _youtubeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _youtubeEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _youtubeUrlController,
                    decoration: const InputDecoration(
                      labelText: 'RTMP URL',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., rtmp://a.rtmp.youtube.com/live2',
                    ),
                    enabled: _youtubeEnabled,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _youtubeKeyController,
                    decoration: InputDecoration(
                      labelText: 'Stream Key',
                      border: const OutlineInputBorder(),
                      helperText: 'Get this from YouTube Studio',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureYoutubeKey
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureYoutubeKey = !_obscureYoutubeKey;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureYoutubeKey,
                    enabled: _youtubeEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Twitch section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videogame_asset, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Twitch',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Switch(
                        value: _twitchEnabled,
                        onChanged: (value) {
                          setState(() {
                            _twitchEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _twitchUrlController,
                    decoration: const InputDecoration(
                      labelText: 'RTMP URL',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., rtmp://live.twitch.tv/app',
                    ),
                    enabled: _twitchEnabled,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _twitchKeyController,
                    decoration: InputDecoration(
                      labelText: 'Stream Key',
                      border: const OutlineInputBorder(),
                      helperText: 'Get this from Twitch Dashboard',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureTwitchKey
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureTwitchKey = !_obscureTwitchKey;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureTwitchKey,
                    enabled: _twitchEnabled,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security Notice',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stream keys are stored securely using platform-specific encryption. '
                    'They are never transmitted or logged in plain text.',
                    style: Theme.of(context).textTheme.bodyMedium,
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
}
