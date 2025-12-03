#!/bin/bash

# Test script for Gulp tasks
# This script verifies that all required Gulp tasks are implemented and functional

echo "=========================================="
echo "Testing Gulp Build System Implementation"
echo "=========================================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test if a task exists
test_task_exists() {
    local task_name=$1
    echo -n "Testing if task '$task_name' exists... "
    
    if npx gulp --tasks 2>&1 | grep -q "$task_name"; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to test if a task runs without critical errors
test_task_runs() {
    local task_name=$1
    local allow_warnings=$2
    echo -n "Testing if task '$task_name' runs... "
    
    # Run the task and capture output
    output=$(npx gulp "$task_name" 2>&1)
    exit_code=$?
    
    # Check for critical errors (but allow warnings about missing SDK)
    if [[ $exit_code -eq 0 ]] || [[ $allow_warnings == "true" && $output =~ "Warning:" ]]; then
        echo -e "${GREEN}PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        echo "  Output: $output"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "1. Testing Required Gulp Tasks Exist"
echo "-------------------------------------"
test_task_exists "android:compile-kotlin"
test_task_exists "android:compile-native"
test_task_exists "android:process-resources"
test_task_exists "android:package"
test_task_exists "android:build"
test_task_exists "android:clean"
test_task_exists "android:test"
echo ""

echo "2. Testing Task Execution"
echo "-------------------------"
test_task_runs "android:clean" "false"
test_task_runs "android:test" "false"
echo ""

echo "3. Testing Makefile Integration"
echo "--------------------------------"
echo -n "Testing 'make clean' integration... "
if make clean 2>&1 | grep -q "Gulp"; then
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "4. Testing Package.json Scripts"
echo "--------------------------------"
echo -n "Testing npm script 'clean'... "
if npm run clean 2>&1 | grep -q "Cleaning build artifacts"; then
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((TESTS_FAILED++))
fi

echo -n "Testing npm script 'test'... "
if npm run test 2>&1 | grep -q "Running Android tests"; then
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((TESTS_FAILED++))
fi
echo ""

echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All Gulp tasks are properly implemented!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the output above.${NC}"
    exit 1
fi
