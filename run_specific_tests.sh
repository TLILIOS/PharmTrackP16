#!/bin/bash

# Script pour exécuter des tests spécifiques et identifier les échecs

echo "=== Running Unit Tests for MediStock ==="
echo ""

# Build the test scheme first
echo "Building test scheme..."
xcodebuild build-for-testing \
    -scheme MediStock \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
    -quiet

# Run the tests
echo "Running tests..."
xcodebuild test-without-building \
    -scheme MediStock \
    -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
    -only-testing:MediStockTests/AuthServiceIntegrationTests \
    -only-testing:MediStockTests/SearchViewModelTests \
    2>&1 | grep -E "(Test Case|failed|Passed|XCTAssert|error:|succeeded)" | grep -v "xctest"

echo ""
echo "=== Test execution completed ==="