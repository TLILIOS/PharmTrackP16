#!/bin/bash

echo "Running performance test for history loading..."

# Run only the specific test
xcodebuild test \
    -scheme MediStock \
    -sdk iphonesimulator \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:MediStockTests/PerformanceTests/testHistoryLoadingOptimization \
    -quiet | grep -E "(Test Case|failed:|Loading|took:|passed)"