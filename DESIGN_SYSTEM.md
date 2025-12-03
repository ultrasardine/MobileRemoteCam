# Design System

This document defines the design patterns, UI components, and architectural conventions used throughout the IP Camera Streaming Platform.

## Table of Contents

- [Design Principles](#design-principles)
- [Architecture](#architecture)
- [UI Components](#ui-components)
- [Color & Theme](#color--theme)
- [Typography](#typography)
- [Layout Patterns](#layout-patterns)
- [Navigation](#navigation)
- [State Management](#state-management)
- [Error Handling](#error-handling)
- [Accessibility](#accessibility)

## Design Principles

### 1. Clarity Over Cleverness
- Use clear, descriptive names for all components and variables
- Prefer explicit code over implicit behavior
- Document complex logic with inline comments

### 2. Consistency
- Reuse existing components before creating new ones
- Follow established patterns for similar functionality
- Maintain consistent spacing, sizing, and styling

### 3. Progressive Disclosure
- Show essential information first
- Hide advanced options behind clear affordances
- Use expandable sections for detailed settings

### 4. Immediate Feedback
- Provide visual feedback for all user actions
- Show loading states during async operations
- Display clear error messages with actionable steps

### 5. Platform Conventions
- Follow Material Design 3 guidelines
- Use platform-specific patterns where appropriate
- Leverage Flutter's built-in widgets

## Architecture

### Layer Structure

```
┌─────────────────────────────────────┐
│         Screens (UI Layer)          │
│  • StatefulWidget for each screen   │
│  • Handles user interaction         │
│  • Displays data from controllers   │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│      Controllers (Logic Layer)      │
│  • Business logic                   │
│  • Platform channel communication   │
│  • State coordination               │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│       Services (Data Layer)         │
│  • Persistence                      │
│  • Network monitoring               │
│  • Error handling                   │
└─────────────────────────────────────┘
              ↕
┌─────────────────────────────────────┐
│      Models (Data Structures)       │
│  • Immutable data classes           │
│  • Serialization logic              │
│  • Business rules                   │
└─────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart                 # App entry point
├── controllers/              # Business logic
│   └── streaming_controller.dart
├── models/                   # Data structures
│   ├── stream_config.dart
│   ├── resolution.dart
│   ├── streaming_mode.dart
│   ├── rtmp_target.dart
│   ├── camera_info.dart
│   ├── error_info.dart
│   └── stream_statistics.dart
├── screens/                  # Full-screen views
│   ├── configuration_screen.dart
│   ├── statistics_screen.dart
│   └── rtmp_setup_screen.dart
├── services/                 # Data and utility services
│   ├── settings_persistence_service.dart
│   ├── rtmp_storage_service.dart
│   ├── network_monitor_service.dart
│   ├── error_handling_service.dart
│   └── performance_optimization_service.dart
├── utils/                    # Helper functions
│   └── permissions_helper.dart
└── widgets/                  # Reusable UI components
    └── error_display_widget.dart
```

## UI Components

### Card-Based Layout

All major sections use Material `Card` widgets for visual grouping:

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section Title', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        // Section content
      ],
    ),
  ),
)
```

**Usage:**
- Configuration sections (camera, resolution, bitrate)
- Settings groups (RTSP, RTMP, audio)
- Statistics displays
- Error and warning messages

### Choice Chips

For mutually exclusive options with 2-4 choices:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: options.map((option) {
    return ChoiceChip(
      label: Text(option.name),
      selected: option == selectedOption,
      onSelected: (selected) {
        if (selected) {
          setState(() => selectedOption = option);
        }
      },
    );
  }).toList(),
)
```

**Usage:**
- Resolution selection (720p, 1080p, 4K)
- Camera selection (when 2-4 cameras available)

### Segmented Buttons

For binary or small set of options:

```dart
SegmentedButton<int>(
  segments: [
    ButtonSegment(value: 30, label: Text('30 FPS')),
    ButtonSegment(value: 60, label: Text('60 FPS')),
  ],
  selected: {frameRate},
  onSelectionChanged: (Set<int> selected) {
    setState(() => frameRate = selected.first);
  },
)
```

**Usage:**
- Frame rate selection (30 FPS / 60 FPS)
- Binary toggles with labels

### Sliders

For continuous value ranges:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Bitrate: ${value.toStringAsFixed(1)} Mbps'),
    Slider(
      value: value,
      min: 1.0,
      max: 10.0,
      divisions: 90,
      label: '${value.toStringAsFixed(1)} Mbps',
      onChanged: (newValue) {
        setState(() => value = newValue);
      },
    ),
  ],
)
```

**Usage:**
- Bitrate adjustment (1-10 Mbps)
- Any continuous numeric range

### Switch List Tiles

For boolean settings with descriptions:

```dart
SwitchListTile(
  title: const Text('Audio Enabled'),
  subtitle: const Text('Include audio in stream'),
  value: audioEnabled,
  onChanged: (value) {
    setState(() => audioEnabled = value);
  },
)
```

**Usage:**
- Feature toggles (audio, RTSP, RTMP)
- Settings with on/off states

### Dropdown Buttons

For large lists of options:

```dart
DropdownButtonFormField<String>(
  value: selectedId,
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
  items: options.map((option) {
    return DropdownMenuItem(
      value: option.id,
      child: Row(
        children: [
          Icon(option.icon),
          const SizedBox(width: 8),
          Text(option.name),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => selectedId = value);
  },
)
```

**Usage:**
- Camera selection (when many cameras available)
- Large option lists

### Mode Selectors

For streaming mode selection with rich descriptions:

```dart
InkWell(
  onTap: canSelect ? () => onModeChanged(mode) : null,
  borderRadius: BorderRadius.circular(12),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(
        color: isSelected ? primaryColor : dividerColor,
        width: isSelected ? 2 : 1,
      ),
      borderRadius: BorderRadius.circular(12),
      color: isSelected ? primaryContainer : null,
    ),
    child: Row(
      children: [
        Text(mode.icon, style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mode.displayName, style: titleStyle),
              Text(mode.description, style: subtitleStyle),
            ],
          ),
        ),
        if (isSelected) Icon(Icons.check_circle),
      ],
    ),
  ),
)
```

**Usage:**
- Streaming mode selection (RTSP, RTMP, Simultaneous)
- Complex option selection with descriptions

### Error Display Widgets

Specialized widgets for error states:

```dart
ErrorDisplayWidget(
  errorCode: 'CAMERA_UNAVAILABLE',
  customMessage: 'Custom error message',
  onDismiss: () => setState(() => error = null),
  onRetry: () => retryOperation(),
)
```

**Variants:**
- `ErrorDisplayWidget`: General errors with troubleshooting steps
- `OverheatingWarningWidget`: Temperature warnings
- `EncoderFallbackWidget`: Hardware encoder fallback notifications

## Color & Theme

### Material 3 Theme

The app uses Material 3 with a blue seed color:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
)
```

### Semantic Colors

- **Primary**: Main brand color (blue) - used for selected states, primary actions
- **Error**: Red - used for errors, critical warnings
- **Warning**: Orange - used for warnings, cautions
- **Success**: Green - used for success states, confirmations
- **Info**: Blue - used for informational messages

### Color Usage

```dart
// Error states
Card(color: Colors.red.shade50)
Icon(Icons.error_outline, color: Colors.red.shade700)

// Warning states
Card(color: Colors.orange.shade50)
Icon(Icons.warning, color: Colors.orange.shade700)

// Info states
Card(color: Colors.blue.shade50)
Icon(Icons.info_outline, color: Colors.blue.shade700)

// Surface variants
Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
```

## Typography

### Text Styles

Use theme-provided text styles:

```dart
// Headings
Theme.of(context).textTheme.headlineSmall    // Main screen status
Theme.of(context).textTheme.titleLarge       // Card titles
Theme.of(context).textTheme.titleMedium      // Section titles
Theme.of(context).textTheme.titleSmall       // Subsection titles

// Body text
Theme.of(context).textTheme.bodyLarge        // Primary content
Theme.of(context).textTheme.bodyMedium       // Secondary content
Theme.of(context).textTheme.bodySmall        // Tertiary content, captions
```

### Font Weights

```dart
// Emphasis
fontWeight: FontWeight.bold      // Titles, selected states
fontWeight: FontWeight.w500      // Medium emphasis
fontWeight: FontWeight.normal    // Default text
```

### Monospace Font

For technical content (URLs, codes):

```dart
Text(
  'rtsp://192.168.1.50:8554/live',
  style: TextStyle(fontFamily: 'monospace'),
)
```

## Layout Patterns

### Standard Padding

```dart
const EdgeInsets.all(16)              // Card padding, screen padding
const EdgeInsets.symmetric(horizontal: 12, vertical: 8)  // Input padding
const EdgeInsets.only(bottom: 8)      // List item spacing
```

### Spacing

```dart
const SizedBox(height: 8)    // Small spacing (within sections)
const SizedBox(height: 16)   // Medium spacing (between elements)
const SizedBox(height: 24)   // Large spacing (between sections)
const SizedBox(height: 32)   // Extra large spacing (major sections)
```

### Border Radius

```dart
BorderRadius.circular(8)     // Cards, containers
BorderRadius.circular(12)    // Mode selectors, emphasized containers
BorderRadius.circular(4)     // Small elements, chips
```

### Screen Layout

```dart
Scaffold(
  appBar: AppBar(
    title: const Text('Screen Title'),
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    actions: [/* action buttons */],
  ),
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      // Card-based sections
    ],
  ),
)
```

## Navigation

### Navigation Pattern

The app uses standard Flutter navigation with `Navigator.push`:

```dart
// Navigate to screen
final result = await Navigator.push<ReturnType>(
  context,
  MaterialPageRoute(
    builder: (context) => TargetScreen(param: value),
  ),
);

// Handle returned data
if (result != null) {
  handleResult(result);
}
```

### Screen Transitions

- **Configuration Screen**: Returns `StreamConfig` when saved
- **RTMP Setup Screen**: Returns `List<RtmpTarget>` when saved
- **Statistics Screen**: No return value (view-only)

### App Bar Actions

```dart
AppBar(
  actions: [
    IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: openStatistics,
      tooltip: 'Statistics',
    ),
    IconButton(
      icon: const Icon(Icons.settings),
      onPressed: openConfiguration,
      tooltip: 'Configuration',
    ),
  ],
)
```

## State Management

### Local State

Use `StatefulWidget` with `setState` for screen-local state:

```dart
class _ScreenState extends State<Screen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await fetchData();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
```

### Loading States

```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}

if (_errorMessage != null) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(_errorMessage!),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _retry,
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}

// Normal content
return ListView(...);
```

### Periodic Updates

For real-time data (statistics):

```dart
Timer? _updateTimer;

@override
void initState() {
  super.initState();
  _startUpdates();
}

@override
void dispose() {
  _updateTimer?.cancel();
  super.dispose();
}

void _startUpdates() {
  _update();
  _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    _update();
  });
}
```

## Error Handling

### Error Display Pattern

1. **Inline Errors**: Show error state in place of content
2. **Snackbars**: For transient errors or confirmations
3. **Error Widgets**: For persistent errors with troubleshooting

### Snackbar Usage

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Operation completed'),
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.green,
  ),
);

// With action
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Failed to save'),
    duration: const Duration(seconds: 4),
    backgroundColor: Colors.red,
    action: SnackBarAction(
      label: 'Retry',
      textColor: Colors.white,
      onPressed: () => retry(),
    ),
  ),
);
```

### Error Widget Pattern

```dart
Card(
  color: Colors.red.shade50,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text('Error', style: errorTitleStyle),
            if (onDismiss != null) IconButton(icon: Icon(Icons.close), onPressed: onDismiss),
          ],
        ),
        const SizedBox(height: 8),
        Text(errorMessage),
        const SizedBox(height: 12),
        Text('Troubleshooting Steps:', style: boldStyle),
        ...steps.map((step) => Text('• $step')),
      ],
    ),
  ),
)
```

## Accessibility

### Semantic Labels

```dart
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: openSettings,
  tooltip: 'Settings',  // Provides screen reader label
)
```

### Contrast

- All text meets WCAG AA contrast requirements
- Error states use high-contrast colors
- Disabled states are visually distinct

### Touch Targets

- Minimum touch target size: 48x48 dp
- Adequate spacing between interactive elements
- Large buttons for primary actions

### Screen Reader Support

- All interactive elements have semantic labels
- Error messages are announced
- Loading states are communicated

## Best Practices

### 1. Immutability

Models should be immutable:

```dart
class Resolution {
  final int width;
  final int height;
  
  const Resolution({required this.width, required this.height});
  
  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Resolution && width == other.width && height == other.height;
}
```

### 2. Null Safety

- Use non-nullable types by default
- Use `?` only when null is a valid state
- Provide default values where appropriate

### 3. Const Constructors

Use `const` for immutable widgets:

```dart
const Text('Static text')
const SizedBox(height: 16)
const Icon(Icons.camera)
```

### 4. Async/Await

Handle async operations properly:

```dart
Future<void> _operation() async {
  try {
    final result = await asyncCall();
    if (mounted) {  // Check if widget is still mounted
      setState(() => _data = result);
    }
  } catch (e) {
    if (mounted) {
      setState(() => _error = e.toString());
    }
  }
}
```

### 5. Resource Cleanup

Always dispose of resources:

```dart
@override
void dispose() {
  _controller.dispose();
  _timer?.cancel();
  _subscription?.cancel();
  super.dispose();
}
```

## Testing Considerations

### Widget Testing

- Test user interactions
- Verify state changes
- Check error states
- Validate navigation

### Property-Based Testing

- Test business logic with multiple inputs
- Verify invariants hold across state changes
- Test edge cases automatically

### Integration Testing

- Test complete user workflows
- Verify screen transitions
- Test data persistence
- Validate platform channel communication

## Documentation Requirements

When adding new components:

1. **Document the component** in this design system
2. **Add usage examples** showing typical patterns
3. **Explain when to use** the component vs alternatives
4. **Include accessibility considerations**
5. **Update related documentation** (README, CONTRIBUTING, etc.)

## CI/CD Workflow Patterns

### Automated Testing

All code changes trigger automated testing before merge:

**Test Workflow:**
- Runs on all branches except `main`
- Executes Flutter, Android, and iOS tests
- Validates code formatting and analysis
- Uploads coverage reports

**Pattern:**
```yaml
# Triggered automatically on push/PR
on:
  push:
    branches-ignore:
      - main
```

### Automated Releases

Merging to `main` triggers automated build and release:

**Build and Release Workflow:**
- Determines semantic version from PR labels
- Builds Android APK and AAB
- Builds iOS IPA (unsigned)
- Creates GitHub release with binaries
- Updates CHANGELOG.md automatically

**Version Bump Pattern:**
- `major` or `breaking` label → Major version (1.0.0 → 2.0.0)
- `feature`, `minor`, or `enhancement` label → Minor version (1.0.0 → 1.1.0)
- `patch` or no label → Patch version (1.0.0 → 1.0.1)

### Semantic Versioning

**Format:** `MAJOR.MINOR.PATCH+BUILD`

**Usage:**
```bash
# Bump version locally
./scripts/bump_version.sh [major|minor|patch]

# Example
./scripts/bump_version.sh minor
# Updates pubspec.yaml: 1.0.0+1 → 1.1.0+2
# Adds entry to CHANGELOG.md
```

### PR Label Requirements

All PRs to `main` must have one of these labels:
- `major` or `breaking` - Breaking changes
- `feature`, `minor`, or `enhancement` - New features
- `patch` or `bugfix` - Bug fixes

**Pattern:**
```markdown
# In PR description
Labels: feature

# Or add via GitHub UI
```

### Release Artifacts

Each release includes:
- **Android APK** - Direct installation
- **Android AAB** - Google Play Store
- **iOS IPA** - Unsigned, requires signing

**Artifact Locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- IPA: `build/ios/iphoneos/IPCameraStreaming.ipa`

### Documentation Updates

When making changes, update relevant documentation:
- **DESIGN_SYSTEM.md** - New patterns, components, or conventions
- **README.md** - New features or usage changes
- **CONTRIBUTING.md** - Process or guideline changes
- **ROADMAP.md** - Milestone completions
- **CHANGELOG.md** - All changes (automated for releases)

See [docs/CI_CD_WORKFLOW.md](docs/CI_CD_WORKFLOW.md) for complete CI/CD documentation.

---

**Last Updated:** December 3, 2025  
**Version:** 1.1.0
