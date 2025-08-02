#!/bin/bash

# Script pour exécuter un test spécifique sans code signing

TEST_NAME=$1

if [ -z "$TEST_NAME" ]; then
    echo "Usage: ./run_test.sh TestClassName/testMethodName"
    exit 1
fi

echo "Exécution du test : $TEST_NAME"

xcodebuild test \
    -scheme MediStock \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:"MediStockTests/$TEST_NAME" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -derivedDataPath build \
    2>&1 | xcpretty -t