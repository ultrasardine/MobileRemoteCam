# Performance Optimization

This document describes the performance optimization features implemented in the IP Camera Streaming Platform.

## Overview

The performance optimization system provides automatic and manual controls for:
- Frame encoding latency optimization
- Memory usage optimization with buffer pools
- Adaptive bitrate based on network conditions
- Battery optimization strategies

## Features

### 1. Buffer Pooling

Buffer pooling reduces memory allocation overhead by reusing frame buffers.

**Benefits:**
- Reduces garbage collection pressure
- Minimizes memory fragmentation
- Improves frame processing latency

**Implementation:**
- Automatically enabled when performance optimization is active
- Native implementation on both iOS and Android
- Configurable pool size based on resolution and frame rate

### 2. Adaptive Bitrate

Adaptive bitrate automatically adjusts streaming quality based on network conditions.

**Triggers:**
- High dropped frame count (>50 frames)
- Low actual bitrate compared to configured bitrate
- Network bandwidth changes

**Behavior:**
- Reduces bitrate by 20% when >10% frames are dropped
- Increases bitrate by 10% when <2% frames are dropped and below target
- Clamped to 1-10 Mbps range

**Manual Control:**
```dart
await streamingController.adjustBitrate(3000000); // 3 Mbps
```

### 3. Battery Optimization

Automatic battery optimization reduces power consumption when battery is low.

**Thresholds:**
- Low battery: 20% - Moderate optimization
- Critical battery: 10% - Aggressive optimization

**Low Battery Optimization (20%):**
- Reduce frame rate to 24 FPS
- Reduce bitrate to 2 Mbps
- Keep preview enabled

**Critical Battery Optimization (10%):**
- Reduce frame rate to 15 FPS
- Reduce bitrate to 1 Mbps
- Disable preview

### 4. Thermal Throttling

Prevents device overheating by reducing streaming quality.

**Trigger:**
- Device temperature > 50°C

**Behavior:**
- Reduce frame rate to 24 FPS
- Reduce bitrate to 3 Mbps

### 5. Encoding Latency Profiling

Monitor frame encoding performance in real-time.

**Metrics:**
- Average latency (ms)
- Maximum latency (ms)
- Minimum latency (ms)
- Sample count

**Usage:**
```dart
final latency = await streamingController.getEncodingLatency();
print('Average encoding latency: ${latency?.averageLatencyMs}ms');
```

**Target:**
- < 33ms for 30 FPS
- < 16ms for 60 FPS

### 6. Memory Usage Monitoring

Track memory usage and buffer pool statistics.

**Metrics:**
- Buffer pool size (bytes)
- Active buffers count
- Total allocated memory (bytes)
- Peak memory usage (bytes)

**Usage:**
```dart
final memory = await streamingController.getMemoryUsage();
print('Active buffers: ${memory?.activeBuffersCount}');
```

## Usage

### Enabling Performance Optimization

Performance optimization is enabled automatically when starting streaming with a network monitor:

```dart
final networkMonitor = NetworkMonitorService();
await networkMonitor.startMonitoring();

final controller = StreamingController();
await controller.startStreaming(
  config,
  networkMonitor: networkMonitor,
  enablePerformanceOptimization: true,
);
```

### Disabling Performance Optimization

To disable automatic optimization:

```dart
await controller.startStreaming(
  config,
  enablePerformanceOptimization: false,
);
```

### Manual Cleanup

Force cleanup of buffers and memory:

```dart
await controller.forceCleanup();
```

## Performance Targets

### Latency
- End-to-end latency: < 200ms (camera to RTSP client)
- Frame encoding latency: < 33ms for 30fps, < 16ms for 60fps

### CPU Usage
- Target: < 40% on mid-range devices
- Achieved through hardware encoding and buffer pooling

### Memory Usage
- Target: < 200MB total
- Buffer pool limits frame queue depth
- Automatic cleanup on stop

### Battery Drain
- Target: < 15% per hour at 1080p30
- Adaptive optimization reduces drain on low battery

## Implementation Details

### Optimization Check Frequency

Performance checks run every 2 seconds to:
- Monitor battery level
- Check dropped frame count
- Evaluate network conditions
- Monitor device temperature

### Native Integration

Performance optimization requires native platform support:

**iOS:**
- Buffer pooling via CVPixelBufferPool
- Thermal monitoring via ProcessInfo
- Battery monitoring via UIDevice

**Android:**
- Buffer pooling via MediaCodec buffer management
- Thermal monitoring via PowerManager
- Battery monitoring via BatteryManager

## Testing

Property-based tests verify low bandwidth stability:

```dart
// Property 29: Low bandwidth increases dropped frames
// Validates: Requirements 7.5
test('Low bandwidth increases dropped frames without crashing', () async {
  // Test verifies system remains stable under low bandwidth
  // and reports increasing dropped frames
});
```

## Best Practices

1. **Always enable performance optimization** for production streaming
2. **Monitor encoding latency** to detect performance issues early
3. **Use adaptive bitrate** for variable network conditions
4. **Respect battery optimization** - don't override on low battery
5. **Clean up resources** properly when stopping streaming

## Troubleshooting

### High Encoding Latency

If encoding latency exceeds targets:
1. Check if hardware encoder is being used
2. Reduce resolution or frame rate
3. Verify device isn't thermally throttled
4. Check for background processes consuming CPU

### Memory Growth

If memory usage grows over time:
1. Verify buffer pooling is enabled
2. Check for proper cleanup on stop
3. Monitor active buffer count
4. Force cleanup if needed

### Excessive Dropped Frames

If dropped frames remain high despite adaptive bitrate:
1. Check network bandwidth
2. Verify RTMP/RTSP server can handle bitrate
3. Consider reducing resolution
4. Check for network congestion

## Future Enhancements

Potential future optimizations:
- Machine learning-based bitrate prediction
- Per-client adaptive bitrate for RTSP
- Dynamic resolution switching
- Advanced thermal management with device-specific profiles
- GPU-accelerated encoding fallback
