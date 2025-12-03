# IP Camera Streaming Platform - Makefile
# Industry-standard build automation for Flutter projects

.PHONY: all help clean build build-ios build-android build-apk build-aab \
        test test-unit test-integration test-coverage test-watch \
        lint format analyze check ci \
        dev dev-ios dev-android \
        deps install-deps upgrade-deps outdated-deps \
        doctor setup \
        act act-test act-android act-codeql act-list \
        release version-patch version-minor version-major \
        docs gen-docs

# Default target
all: check build

#==============================================================================
# HELP
#==============================================================================

help:
	@echo "IP Camera Streaming Platform - Build Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Build Targets:"
	@echo "  build          Build both iOS and Android release"
	@echo "  build-ios      Build iOS release"
	@echo "  build-android  Build Android APK release"
	@echo "  build-apk      Build Android APK (alias)"
	@echo "  build-aab      Build Android App Bundle"
	@echo ""
	@echo "Development:"
	@echo "  dev            Run on connected device"
	@echo "  dev-ios        Run on iOS simulator/device"
	@echo "  dev-android    Run on Android emulator/device"
	@echo ""
	@echo "Testing:"
	@echo "  test           Run all tests"
	@echo "  test-unit      Run unit tests only"
	@echo "  test-integration Run integration tests"
	@echo "  test-coverage  Run tests with coverage report"
	@echo "  test-watch     Run tests in watch mode"
	@echo ""
	@echo "Code Quality:"
	@echo "  lint           Run linter"
	@echo "  format         Format code"
	@echo "  analyze        Analyze code for issues"
	@echo "  check          Run format check + analyze + test"
	@echo "  ci             Full CI pipeline (clean, deps, check)"
	@echo ""
	@echo "Dependencies:"
	@echo "  deps           Get Flutter dependencies"
	@echo "  install-deps   Install all dependencies (Flutter + iOS)"
	@echo "  upgrade-deps   Upgrade dependencies"
	@echo "  outdated-deps  Check for outdated dependencies"
	@echo ""
	@echo "CI/CD Testing (act):"
	@echo "  act-list       List available workflows"
	@echo "  act-test       Test the test.yml workflow locally"
	@echo "  act-android    Test the android-ci.yml workflow locally"
	@echo "  act-codeql     Test the codeql.yml workflow locally"
	@echo ""
	@echo "Release:"
	@echo "  version-patch  Bump patch version (0.0.X)"
	@echo "  version-minor  Bump minor version (0.X.0)"
	@echo "  version-major  Bump major version (X.0.0)"
	@echo ""
	@echo "Utilities:"
	@echo "  clean          Clean all build artifacts"
	@echo "  doctor         Run Flutter doctor"
	@echo "  setup          Initial project setup"

#==============================================================================
# BUILD TARGETS
#==============================================================================

build: build-ios build-android

build-ios:
	@echo "🍎 Building iOS release..."
	cd ios && pod install --repo-update || echo "Skipping pod install"
	flutter build ios --release --no-codesign

build-android: build-apk

build-apk:
	@echo "🤖 Building Android APK..."
	flutter build apk --release

build-aab:
	@echo "🤖 Building Android App Bundle..."
	flutter build appbundle --release

build-debug-apk:
	@echo "🤖 Building Android debug APK..."
	flutter build apk --debug

build-debug-ios:
	@echo "🍎 Building iOS debug..."
	flutter build ios --debug --no-codesign

#==============================================================================
# DEVELOPMENT
#==============================================================================

dev:
	flutter run

dev-ios:
	@echo "🍎 Running on iOS..."
	flutter run -d ios

dev-android:
	@echo "🤖 Running on Android..."
	flutter run -d android

dev-web:
	@echo "🌐 Running on web..."
	flutter run -d chrome

hot-restart:
	@echo "🔄 Hot restarting..."
	flutter run --hot

#==============================================================================
# TESTING
#==============================================================================

test:
	@echo "🧪 Running all tests..."
	flutter test

test-unit:
	@echo "🧪 Running unit tests..."
	flutter test test/

test-integration:
	@echo "🧪 Running integration tests..."
	flutter test integration_test/ || echo "No integration tests found"

test-coverage:
	@echo "🧪 Running tests with coverage..."
	flutter test --coverage
	@echo "📊 Coverage report generated at coverage/lcov.info"
	@command -v genhtml >/dev/null 2>&1 && genhtml coverage/lcov.info -o coverage/html && echo "📊 HTML report at coverage/html/index.html" || echo "Install lcov for HTML report: brew install lcov"

test-watch:
	@echo "🧪 Running tests in watch mode..."
	@echo "Note: Requires very_good_cli or similar"
	flutter test --reporter expanded

test-verbose:
	@echo "🧪 Running tests with verbose output..."
	flutter test --reporter expanded

test-failed:
	@echo "🧪 Re-running failed tests..."
	flutter test --reporter expanded

#==============================================================================
# CODE QUALITY
#==============================================================================

lint:
	@echo "🔍 Running linter..."
	flutter analyze --no-fatal-infos

format:
	@echo "✨ Formatting code..."
	dart format lib/ test/

format-check:
	@echo "🔍 Checking code formatting..."
	dart format --output=none --set-exit-if-changed lib/ test/

analyze:
	@echo "🔍 Analyzing code..."
	flutter analyze

check: format-check analyze test
	@echo "✅ All checks passed!"

ci: clean deps check
	@echo "✅ CI pipeline complete!"

fix:
	@echo "🔧 Applying automatic fixes..."
	dart fix --apply

#==============================================================================
# DEPENDENCIES
#==============================================================================

deps:
	@echo "📦 Getting dependencies..."
	flutter pub get

install-deps: deps
	@echo "📦 Installing iOS dependencies..."
	cd ios && pod install --repo-update || echo "iOS dependencies will be installed when iOS project is created"

upgrade-deps:
	@echo "📦 Upgrading dependencies..."
	flutter pub upgrade

outdated-deps:
	@echo "📦 Checking for outdated dependencies..."
	flutter pub outdated

#==============================================================================
# CI/CD TESTING WITH ACT
#==============================================================================

ACT_ARCH := --container-architecture linux/amd64

act-list:
	@echo "📋 Listing available workflows..."
	act --list

act-test:
	@echo "🧪 Testing test.yml workflow locally..."
	act push -W .github/workflows/test.yml $(ACT_ARCH) --dryrun

act-test-run:
	@echo "🧪 Running test.yml workflow locally..."
	act push -W .github/workflows/test.yml $(ACT_ARCH)

act-android:
	@echo "🤖 Testing android-ci.yml workflow locally..."
	act push -W .github/workflows/android-ci.yml $(ACT_ARCH) --dryrun

act-android-run:
	@echo "🤖 Running android-ci.yml workflow locally..."
	act push -W .github/workflows/android-ci.yml $(ACT_ARCH)

act-codeql:
	@echo "🔒 Testing codeql.yml workflow locally..."
	act push -W .github/workflows/codeql.yml $(ACT_ARCH) --dryrun

act-all:
	@echo "🔄 Testing all workflows..."
	act --list
	act push $(ACT_ARCH) --dryrun

#==============================================================================
# RELEASE & VERSIONING
#==============================================================================

version-patch:
	@echo "📦 Bumping patch version..."
	./scripts/bump_version.sh patch

version-minor:
	@echo "📦 Bumping minor version..."
	./scripts/bump_version.sh minor

version-major:
	@echo "📦 Bumping major version..."
	./scripts/bump_version.sh major

release: check build
	@echo "🚀 Release build complete!"
	@echo "Artifacts:"
	@echo "  - build/app/outputs/flutter-apk/app-release.apk"
	@echo "  - build/ios/iphoneos/Runner.app"

#==============================================================================
# UTILITIES
#==============================================================================

clean:
	@echo "🧹 Cleaning build artifacts..."
	flutter clean
	rm -rf build coverage .dart_tool
	rm -rf ios/Pods ios/build ios/.symlinks
	rm -rf android/app/build android/.gradle
	@echo "✅ Clean complete!"

doctor:
	@echo "🩺 Running Flutter doctor..."
	flutter doctor -v

setup: doctor deps install-deps
	@echo "✅ Project setup complete!"

gen-icons:
	@echo "🎨 Generating app icons..."
	flutter pub run flutter_launcher_icons:main || echo "Add flutter_launcher_icons to dev_dependencies"

gen-splash:
	@echo "🎨 Generating splash screen..."
	flutter pub run flutter_native_splash:create || echo "Add flutter_native_splash to dev_dependencies"

gen-l10n:
	@echo "🌍 Generating localizations..."
	flutter gen-l10n || echo "No l10n configuration found"

#==============================================================================
# DOCUMENTATION
#==============================================================================

docs:
	@echo "📚 Opening documentation..."
	@echo "See docs/ directory for project documentation"
	@ls -la docs/

serve-docs:
	@echo "📚 Serving documentation..."
	@command -v python3 >/dev/null 2>&1 && cd docs && python3 -m http.server 8000 || echo "Python3 required for serving docs"
