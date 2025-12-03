// Basic Flutter widget test for IP Camera Streaming app

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ip_camera_streaming/main.dart';

void main() {
  testWidgets('App launches and shows main screen',
      (WidgetTester tester) async {
    // Mock SharedPreferences with default values
    SharedPreferences.setMockInitialValues({
      'camera_id': '0',
      'resolution_width': 1920,
      'resolution_height': 1080,
      'frame_rate': 30,
      'bitrate': 5000000,
      'audio_enabled': false,
      'rtsp_enabled': true,
      'rtsp_port': 8554,
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const IPCameraApp());

    // Wait for initialization to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed in the AppBar
    expect(find.text('IP Camera Streaming'), findsOneWidget);

    // Verify that the start streaming button is present
    expect(find.text('Start Streaming'), findsOneWidget);
  });
}
