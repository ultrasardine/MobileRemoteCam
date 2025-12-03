# Quick Test Reference Card

## Task 29: Platform-Specific Testing - Quick Start

### Prerequisites Checklist

- [ ] iPhone 12+ or Pixel 5+ device
- [ ] USB cable
- [ ] OBS Studio installed
- [ ] VLC Media Player installed
- [ ] YouTube/Twitch account ready
- [ ] WiFi network available

### Quick Test Commands

```bash
# 1. Run the test runner (easiest method)
./scripts/device_test_runner.sh

# 2. Or run automated tests manually
flutter test test/platform_validation_test.dart -d <device-id>

# 3. List connected devices
flutter devices

# 4. Deploy to iOS
flutter run -d <ios-device-id>

# 5. Deploy to Android
flutter run -d <android-device-id>
```

### Test Sequence

#### Phase 1: Automated Tests (5 minutes)
```bash
./scripts/device_test_runner.sh
# Select: 1 (iOS) or 2 (Android)
# Select: 1 (Automated tests)
```

#### Phase 2: Camera Tests (10 minutes)
1. Open app on device
2. Go to Configuration screen
3. Check camera list - all cameras present?
4. Select each camera - preview works?
5. Check resolutions - 720p/1080p available?

#### Phase 3: RTSP Tests (15 minutes)
1. Enable RTSP in app
2. Start streaming
3. Copy RTSP URL
4. **OBS Test:**
   - Add Media Source
   - Paste URL
   - Verify video/audio
5. **VLC Test:**
   - Open Network Stream
   - Paste URL
   - Verify playback

#### Phase 4: RTMP Tests (20 minutes)
1. **YouTube:**
   - Get stream URL and key from YouTube Studio
   - Configure in app
   - Start streaming
   - Verify in YouTube Studio
2. **Twitch:**
   - Get server URL and key from Twitch Dashboard
   - Configure in app
   - Start streaming
   - Verify in Twitch Dashboard

#### Phase 5: Multi-Camera Test (10 minutes)
1. Start streaming
2. Switch between cameras
3. Verify smooth transitions
4. Check stream continues

### Expected Results

✅ **Pass Criteria:**
- All cameras detected
- Hardware encoding works
- RTSP clients connect successfully
- RTMP streams to YouTube/Twitch
- Device temperature < 45°C
- CPU usage < 40%
- No crashes or errors

❌ **Fail Criteria:**
- Missing cameras
- Encoding failures
- Connection errors
- Overheating
- Crashes

### Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Camera not found | Check permissions, restart app |
| RTSP won't connect | Verify same network, check firewall |
| RTMP fails | Verify URL and key, check internet |
| Poor quality | Reduce resolution/bitrate |
| Overheating | Lower settings, take break |

### Documentation

After testing, document results in:
- `docs/PLATFORM_TESTING_GUIDE.md` (detailed results)
- `docs/TASK_29_COMPLETION_SUMMARY.md` (summary)

### Test Duration

- **Automated Tests:** 5 minutes
- **Manual Tests:** 60 minutes
- **Total per Platform:** ~65 minutes
- **Both Platforms:** ~2.5 hours

### Files to Review

1. `docs/PLATFORM_TESTING_GUIDE.md` - Detailed procedures
2. `docs/DEVICE_TESTING_README.md` - Setup and instructions
3. `test/platform_validation_test.dart` - Automated tests
4. `scripts/device_test_runner.sh` - Test runner

### Support

If you encounter issues:
1. Check Troubleshooting section in PLATFORM_TESTING_GUIDE.md
2. Review error messages carefully
3. Verify all prerequisites are met
4. Check device logs for details

### Sign-Off

After completing all tests:
- [ ] iOS tests complete
- [ ] Android tests complete
- [ ] Results documented
- [ ] Issues logged
- [ ] Performance metrics recorded

**Tester:** _______________
**Date:** _______________
**Result:** ☐ Pass ☐ Pass with Issues ☐ Fail
