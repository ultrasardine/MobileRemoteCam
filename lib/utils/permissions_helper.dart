import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/streaming_controller.dart';

/// Helper class for managing permissions and displaying error messages
class PermissionsHelper {
  final StreamingController _controller = StreamingController();

  /// Request camera permission with user-friendly error handling
  Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      final granted = await _controller.requestCameraPermission();
      if (!granted) {
        _showPermissionDeniedDialog(
          context,
          'Camera Permission Required',
          'Camera permission is required to capture video for streaming. '
              'Please grant permission in Settings to enable streaming.',
        );
      }
      return granted;
    } on PlatformException catch (e) {
      _showPermissionErrorDialog(
          context, 'Camera Permission', e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Request microphone permission with user-friendly error handling
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      final granted = await _controller.requestMicrophonePermission();
      if (!granted) {
        _showPermissionDeniedDialog(
          context,
          'Microphone Permission Required',
          'Microphone permission is required to capture audio for streaming. '
              'Please grant permission in Settings to enable audio streaming.',
        );
      }
      return granted;
    } on PlatformException catch (e) {
      _showPermissionErrorDialog(
          context, 'Microphone Permission', e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      return await _controller.hasCameraPermission();
    } catch (e) {
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    try {
      return await _controller.hasMicrophonePermission();
    } catch (e) {
      return false;
    }
  }

  /// Show permission denied dialog
  void _showPermissionDeniedDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // In production, this would open app settings
              // For now, we just close the dialog
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Show permission error dialog
  void _showPermissionErrorDialog(
    BuildContext context,
    String permission,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permission Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show permission revocation error
  void showPermissionRevokedError(
    BuildContext context,
    String permission,
  ) {
    final message = permission == 'camera'
        ? 'Camera permission was revoked. Streaming has been stopped. '
            'Please grant permission to continue streaming.'
        : 'Microphone permission was revoked. Streaming has been stopped. '
            'Please grant permission to continue streaming with audio.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission Revoked'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
