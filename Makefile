.PHONY: all clean build-ios build-android test install-deps dev-ios dev-android

all: build-ios build-android

# Install dependencies
install-deps:
	@echo "Installing Flutter dependencies..."
	flutter pub get
	@echo "Installing iOS dependencies..."
	cd ios && pod install || echo "iOS dependencies will be installed when iOS project is created"

# iOS build
build-ios:
	@echo "Building iOS app..."
	cd ios && pod install || echo "Skipping pod install - iOS project not yet created"
	flutter build ios --release

# Android build (using Flutter)
build-android:
	@echo "Building Android app with Flutter..."
	flutter build apk --release

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	flutter clean
	cd ios && rm -rf Pods build || echo "iOS clean skipped"
	cd android && ./gradlew clean || echo "Android clean skipped"

# Run tests
test:
	@echo "Running Flutter tests..."
	flutter test

# Development builds
dev-ios:
	@echo "Running iOS development build..."
	flutter run -d ios

dev-android:
	@echo "Running Android development build..."
	flutter run -d android

# Format code
format:
	@echo "Formatting Dart code..."
	dart format lib/ test/

# Analyze code
analyze:
	@echo "Analyzing Dart code..."
	flutter analyze

# Get Flutter dependencies
deps:
	flutter pub get
