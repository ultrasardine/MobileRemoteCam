# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Open source compliance documentation
- CODE_OF_CONDUCT.md following Contributor Covenant 2.1
- CONTRIBUTING.md with development guidelines
- SECURITY.md with security policy and reporting process
- GitHub issue templates (bug report, feature request)
- GitHub pull request template
- Enhanced .gitignore for cross-platform development
- Flutter Android plugin structure with method channels
- NetworkMonitor service for Android platform
- CI/CD workflow for automated testing on all branches
- Build and release workflow for automatic binary generation
- Semantic versioning automation based on PR labels
- Version bump script for local development
- Comprehensive CI/CD documentation (docs/CI_CD_WORKFLOW.md)
- GitHub Actions badges in README.md

### Changed
- **BREAKING**: Migrated from standalone Gradle build to Flutter plugin architecture
- Updated README.md with comprehensive project information
- Clarified MIT License in documentation
- Updated CONTRIBUTING.md with Flutter development guidelines
- Migrated Android native code to Flutter plugin structure (package: com.ipcamera.ip_camera_streaming)
- Updated Makefile to use Flutter build system instead of Gulp
- Updated .gitignore for Flutter project structure

### Removed
- Gulp build system (gulpfile.js, package.json, package-lock.json)
- Standalone Gradle configuration (build.gradle, settings.gradle, gradle.properties, gradlew)
- Node.js dependencies
- Old Android app module structure

## [0.0.4] - 2023-XX-XX

### Added
- Initial Android implementation
- Basic camera capture functionality
- MJPEG streaming support

### Changed
- Updated to Android SDK 33
- Migrated to Kotlin

## [0.0.3] - 2023-XX-XX

### Added
- Camera2 API integration
- Network streaming capabilities

## [0.0.2] - 2023-XX-XX

### Added
- Basic UI implementation
- Camera permission handling

## [0.0.1] - 2023-XX-XX

### Added
- Initial project setup
- Basic Android project structure

[Unreleased]: https://github.com/ORIGINAL_OWNER/ip-camera-streaming/compare/v0.0.4...HEAD
[0.0.4]: https://github.com/ORIGINAL_OWNER/ip-camera-streaming/compare/v0.0.3...v0.0.4
[0.0.3]: https://github.com/ORIGINAL_OWNER/ip-camera-streaming/compare/v0.0.2...v0.0.3
[0.0.2]: https://github.com/ORIGINAL_OWNER/ip-camera-streaming/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/ORIGINAL_OWNER/ip-camera-streaming/releases/tag/v0.0.1
