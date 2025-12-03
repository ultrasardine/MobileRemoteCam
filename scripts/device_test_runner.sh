#!/bin/bash

# Device Testing Runner Script
# This script helps run platform validation tests on connected devices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}IP Camera Platform Validation Test Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_success "Flutter found: $(flutter --version | head -n 1)"
echo ""

# List connected devices
print_info "Checking for connected devices..."
flutter devices

echo ""
print_info "Select platform to test:"
echo "  1) iOS Device"
echo "  2) Android Device"
echo "  3) Both (run tests on all connected devices)"
echo "  4) Exit"
echo ""
read -p "Enter choice [1-4]: " platform_choice

case $platform_choice in
    1)
        PLATFORM="ios"
        print_info "Testing on iOS device..."
        ;;
    2)
        PLATFORM="android"
        print_info "Testing on Android device..."
        ;;
    3)
        PLATFORM="all"
        print_info "Testing on all connected devices..."
        ;;
    4)
        print_info "Exiting..."
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "Select test type:"
echo "  1) Platform Validation Tests (automated)"
echo "  2) Manual Testing Guide (opens documentation)"
echo "  3) Both"
echo ""
read -p "Enter choice [1-3]: " test_choice

run_automated_tests() {
    local device_flag=$1
    
    print_info "Running platform validation tests..."
    echo ""
    
    if [ -n "$device_flag" ]; then
        flutter test test/platform_validation_test.dart -d "$device_flag"
    else
        flutter test test/platform_validation_test.dart
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Automated tests completed"
    else
        print_warning "Some automated tests failed - review output above"
    fi
}

open_manual_guide() {
    print_info "Opening manual testing guide..."
    
    if [ -f "docs/PLATFORM_TESTING_GUIDE.md" ]; then
        # Try to open with default markdown viewer
        if command -v open &> /dev/null; then
            # macOS
            open docs/PLATFORM_TESTING_GUIDE.md
        elif command -v xdg-open &> /dev/null; then
            # Linux
            xdg-open docs/PLATFORM_TESTING_GUIDE.md
        else
            print_info "Manual testing guide location: docs/PLATFORM_TESTING_GUIDE.md"
            print_info "Please open this file in your preferred markdown viewer"
        fi
        print_success "Manual testing guide opened"
    else
        print_error "Manual testing guide not found at docs/PLATFORM_TESTING_GUIDE.md"
    fi
}

case $test_choice in
    1)
        # Automated tests only
        if [ "$PLATFORM" = "all" ]; then
            run_automated_tests ""
        else
            # Get specific device ID
            print_info "Available devices:"
            flutter devices --machine | grep -o '"id":"[^"]*"' | cut -d'"' -f4
            echo ""
            read -p "Enter device ID (or press Enter for first available): " device_id
            
            if [ -n "$device_id" ]; then
                run_automated_tests "$device_id"
            else
                run_automated_tests ""
            fi
        fi
        ;;
    2)
        # Manual guide only
        open_manual_guide
        ;;
    3)
        # Both automated and manual
        if [ "$PLATFORM" = "all" ]; then
            run_automated_tests ""
        else
            print_info "Available devices:"
            flutter devices --machine | grep -o '"id":"[^"]*"' | cut -d'"' -f4
            echo ""
            read -p "Enter device ID (or press Enter for first available): " device_id
            
            if [ -n "$device_id" ]; then
                run_automated_tests "$device_id"
            else
                run_automated_tests ""
            fi
        fi
        echo ""
        open_manual_guide
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
print_info "========================================"
print_info "Testing Summary"
print_info "========================================"
echo ""
print_info "Automated tests: Completed"
print_info "Manual tests: See PLATFORM_TESTING_GUIDE.md"
echo ""
print_info "Next steps:"
echo "  1. Review automated test results above"
echo "  2. Complete manual tests from the guide"
echo "  3. Test RTSP streaming with OBS and VLC"
echo "  4. Test RTMP streaming with YouTube and Twitch"
echo "  5. Document results in the testing guide"
echo ""
print_success "Platform validation test runner completed"
