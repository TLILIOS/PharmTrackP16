#!/bin/bash

# Script d'optimisation des tests MediStock
# Objectif: Réduire le temps d'exécution de 30+ min à 5-8 min

echo "🚀 Optimisation des tests MediStock..."

# Nettoyer le build
echo "🧹 Nettoyage du build..."
xcodebuild clean -scheme MediStock -quiet

# Configurer les optimisations
echo "⚙️ Configuration des optimisations..."

# 1. Activer la parallélisation
defaults write com.apple.dt.xcodebuild IDEBuildOperationMaxNumberOfConcurrentCompileTasks 4

# 2. Désactiver les animations pour les tests
defaults write com.apple.dt.XCTest DisableUIAnimations -bool YES

# 3. Configurer les timeouts courts
export XCTEST_TIMEOUT=2.0

# 4. Utiliser le mode Release pour les tests (plus rapide)
export CONFIGURATION=Release

# 5. Désactiver la collection de couverture pendant l'optimisation
export DISABLE_COVERAGE=YES

echo "📊 Configuration actuelle:"
echo "  - Parallélisation: 4 threads"
echo "  - Animations UI: Désactivées"
echo "  - Timeout par test: 2 secondes"
echo "  - Mode: Release"
echo "  - Couverture: Désactivée"

# Exécuter les tests avec mesure du temps
echo "🏃 Exécution des tests optimisés..."

START_TIME=$(date +%s)

xcodebuild test \
    -scheme MediStock \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -configuration Release \
    -parallel-testing-enabled YES \
    -maximum-concurrent-test-simulator-destinations 4 \
    2>&1 | grep -E "(Test Suite|Test Case|Executed|passed|failed|error|seconds)" | tail -100

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "✅ Tests terminés!"
echo "⏱️ Temps total: $DURATION secondes ($(($DURATION / 60)) minutes $(($DURATION % 60)) secondes)"

# Vérifier si on a atteint l'objectif
if [ $DURATION -le 480 ]; then # 8 minutes = 480 secondes
    echo "🎉 OBJECTIF ATTEINT! Temps < 8 minutes"
else
    echo "⚠️ Objectif non atteint. Temps cible: < 8 minutes"
    echo "💡 Suggestions supplémentaires:"
    echo "   - Réduire encore les datasets dans les tests"
    echo "   - Vérifier les tests qui timeout"
    echo "   - Optimiser les mocks Firebase"
fi

# Restaurer les paramètres par défaut (optionnel)
# defaults delete com.apple.dt.xcodebuild IDEBuildOperationMaxNumberOfConcurrentCompileTasks
# defaults delete com.apple.dt.XCTest DisableUIAnimations