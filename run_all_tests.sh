#!/bin/bash

echo "=== COMPILATION ET EXÉCUTION DES TESTS ==="
echo ""

# D'abord, compiler le projet pour les tests
echo "1. Compilation du projet pour les tests..."
if xcodebuild build-for-testing \
    -scheme MediStock \
    -sdk iphonesimulator \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    -derivedDataPath build_test; then
    echo "✅ Compilation réussie"
else
    echo "❌ Échec de la compilation"
    exit 1
fi

echo ""
echo "2. Exécution de tous les tests..."

# Exécuter tous les tests
if xcodebuild test-without-building \
    -scheme MediStock \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -derivedDataPath build_test \
    CODE_SIGNING_ALLOWED=NO; then
    echo ""
    echo "✅ TOUS LES TESTS SONT PASSÉS!"
else
    echo ""
    echo "❌ DES TESTS ONT ÉCHOUÉ"
    exit 1
fi