# Contributing to IP Camera Streaming Platform

First off, thank you for considering contributing to IP Camera Streaming Platform! It's people like you that make this project such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots, etc.)
- **Describe the behavior you observed** and what you expected
- **Include device information** (OS version, device model, app version)
- **Include logs** if applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Explain why this enhancement would be useful**
- **List any similar features** in other applications if applicable

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:
- `good first issue` - Simple issues for newcomers
- `help wanted` - Issues where we need community help
- `documentation` - Documentation improvements

### Pull Requests

1. Fork the repository and create your branch from `main`
2. Make your changes following our coding standards
3. Add tests for any new functionality
4. Ensure all tests pass
5. Update documentation as needed
6. Submit a pull request

## Development Setup

### Prerequisites

- **Flutter Development:**
  - Flutter SDK 3.0+
  - Dart SDK 3.0+

- **Android Development:**
  - Android Studio or VS Code
  - Android SDK 28+ with NDK
  - Kotlin 1.6+

- **iOS Development:**
  - Xcode 14+
  - CocoaPods
  - Swift 5.5+

### Setup Steps

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/ip-camera-streaming.git
cd ip-camera-streaming

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/ip-camera-streaming.git

# Install dependencies
make install-deps

# Run the app (iOS)
make dev-ios

# Run the app (Android)
make dev-android
```

### Project Structure

```
lib/                   # Flutter/Dart code
├── main.dart
├── controllers/       # Business logic
├── models/           # Data structures
├── screens/          # UI screens
└── services/         # Data services

android/              # Android native plugin
├── app/src/main/kotlin/
│   └── com/ipcamera/ip_camera_streaming/
│       ├── MainActivity.kt
│       ├── serv/     # Streaming services
│       └── streaming/ # Streaming components

ios/                  # iOS native plugin
├── Runner/
│   ├── StreamingManager.swift
│   └── ...
└── Podfile
```

## Pull Request Process

1. **Create a feature branch** from `main` (not from other branches)
2. **Make your changes** following coding standards
3. **Add tests** - All new features must include tests
4. **Update documentation** - Ensure README.md and other docs reflect your changes
5. **Update CHANGELOG** - Add your changes to the unreleased section
6. **Add appropriate label** to your PR:
   - `major` or `breaking` - For breaking changes (triggers major version bump)
   - `feature`, `minor`, or `enhancement` - For new features (triggers minor version bump)
   - `patch` or no label - For bug fixes (triggers patch version bump)
7. **Push to your fork** and create a pull request
8. **Wait for CI checks** - All tests must pass before merging
9. **Request review** - Tag relevant maintainers
10. **Merge to main** - Once approved, the PR will trigger automatic release

### PR Checklist

- [ ] Code follows the project's style guidelines
- [ ] Self-review of code completed
- [ ] Comments added for complex logic
- [ ] Documentation updated (README, DESIGN_SYSTEM, etc.)
- [ ] Tests added/updated and passing
- [ ] No new warnings introduced
- [ ] Dependent changes merged and published
- [ ] Appropriate label added (`major`, `minor`, or `patch`)
- [ ] CHANGELOG.md updated with changes

### CI/CD Workflow

When you push to a non-main branch:
- **Test workflow runs automatically**
- Flutter tests, Android tests, and iOS tests execute
- Code formatting and analysis checks run
- All checks must pass before merging

When your PR is merged to main:
- **Build and release workflow triggers automatically**
- Version is bumped based on PR label
- iOS and Android binaries are built
- GitHub release is created with artifacts
- CHANGELOG.md is updated automatically

See [docs/CI_CD_WORKFLOW.md](docs/CI_CD_WORKFLOW.md) for detailed CI/CD documentation.

## Coding Standards

### Dart Style Guide

Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

```dart
// Good
class StreamingController {
  final StreamConfig config;
  bool _isStreaming = false;
  
  Future<void> startStreaming() async {
    // Implementation
  }
}

// Use meaningful names
final frameRate = 30;
final isStreaming = false;

// Prefer expressions
final status = switch (state) {
  StreamState.idle => 'Ready',
  StreamState.streaming => 'Active',
  _ => 'Unknown',
};
```

### Kotlin Style Guide (for Android native code)

Follow the [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html):

```kotlin
// Good
class StreamingManager(
    private val context: Context
) {
    fun startStreaming(config: Map<String, Any>) {
        // Implementation
    }
}
```

### Code Organization

- **Package structure**: Group by feature, not layer
- **File naming**: PascalCase for classes, camelCase for files
- **Constants**: Use `const val` in companion objects
- **Nullability**: Prefer non-null types, use `?` only when necessary

### Documentation

**Dart:**
```dart
/// Manages streaming operations and coordinates with native platforms.
///
/// This controller handles the lifecycle of streaming sessions,
/// including configuration, starting, stopping, and monitoring.
class StreamingController {
  /// Starts streaming with the provided [config].
  ///
  /// Returns a [Future] that completes when streaming has started.
  /// Throws [StreamingException] if streaming fails to start.
  Future<void> startStreaming(StreamConfig config) async {
    // Implementation
  }
}
```

**Kotlin:**
```kotlin
/**
 * Manages camera capture and streaming operations.
 *
 * @property context Application context
 */
class StreamingManager(
    private val context: Context
) {
    /**
     * Starts streaming with the specified configuration.
     *
     * @param config Streaming configuration map
     */
    fun startStreaming(config: Map<String, Any>) {
        // Implementation
    }
}
```

## Testing Guidelines

### Unit Tests

- Test business logic in isolation
- Use descriptive test names
- Follow AAA pattern: Arrange, Act, Assert

**Dart:**
```dart
test('should start streaming when configuration is valid', () async {
  // Arrange
  final controller = StreamingController();
  final config = StreamConfig(/* ... */);
  
  // Act
  await controller.startStreaming(config);
  
  // Assert
  expect(controller.isStreaming, isTrue);
});
```

**Property-Based Tests:**
```dart
test('streaming bitrate should always be within configured range', () {
  fc.assert(fc.property(
    fc.integer(min: 1000000, max: 10000000),
    (bitrate) async {
      final config = StreamConfig(bitrate: bitrate);
      final stats = await getStatistics();
      expect(stats.bitrate, lessThanOrEqualTo(bitrate * 1.1));
    }
  ));
});
```

### Integration Tests

- Test component interactions
- Use Android instrumentation tests for UI
- Mock external dependencies (network, hardware)

### Running Tests

```bash
# All Flutter tests
flutter test

# Specific test file
flutter test test/controllers/streaming_controller_test.dart

# iOS native tests
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner

# Via Makefile
make test
```

## Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(camera): add support for ultra-wide camera

Implement camera selection for devices with multiple cameras.
Includes support for telephoto and ultra-wide lenses.

Closes #123
```

```
fix(streaming): resolve RTSP connection timeout

Increase connection timeout from 5s to 10s to handle
slower network conditions.

Fixes #456
```

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).

## Questions?

Feel free to:
- Open a [Discussion](https://github.com/ORIGINAL_OWNER/ip-camera-streaming/discussions)
- Join our community chat (if available)
- Email the maintainers

Thank you for contributing! 🎉
