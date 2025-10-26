#!/bin/bash

# Script de vérification de l'isolation des tests
# Vérifie qu'aucun test n'effectue d'appels réseau réels

set -e

echo "🔍 Vérification de l'isolation des tests MediStock"
echo "=================================================="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Compteurs
ERRORS=0
WARNINGS=0
SUCCESS=0

# Fonction de vérification
check_pattern() {
    local pattern=$1
    local message=$2
    local severity=$3  # ERROR ou WARNING
    local exclude=$4   # Patterns à exclure (optionnel)

    echo -n "Vérification : $message... "

    if [ -n "$exclude" ]; then
        # Avec exclusion
        results=$(grep -r "$pattern" --include="*.swift" MediStockTests/ | grep -v "$exclude" || true)
    else
        # Sans exclusion
        results=$(grep -r "$pattern" --include="*.swift" MediStockTests/ || true)
    fi

    if [ -n "$results" ]; then
        if [ "$severity" == "ERROR" ]; then
            echo -e "${RED}❌ ÉCHEC${NC}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠️  AVERTISSEMENT${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        echo "$results"
        echo ""
    else
        echo -e "${GREEN}✅ OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    fi
}

echo "📋 Vérifications d'isolation"
echo ""

# 1. Vérifier l'absence d'initialisation de services réels
check_pattern "AuthService()" \
    "Aucune initialisation directe de AuthService" \
    "ERROR" \
    "Mock"

check_pattern "MedicineDataService()" \
    "Aucune initialisation directe de MedicineDataService" \
    "ERROR" \
    "Mock"

check_pattern "AisleDataService()" \
    "Aucune initialisation directe de AisleDataService" \
    "ERROR" \
    "Mock"

check_pattern "HistoryDataService()" \
    "Aucune initialisation directe de HistoryDataService" \
    "ERROR" \
    "Mock"

# 2. Vérifier l'absence d'imports Firebase inappropriés
check_pattern "import FirebaseAuth" \
    "Pas d'import FirebaseAuth dans les tests" \
    "WARNING" \
    "IntegrationTests\|FirebaseTestStubs\|Mock"

check_pattern "import FirebaseFirestore" \
    "Pas d'import FirebaseFirestore dans les tests" \
    "WARNING" \
    "Mock\|FirebaseTestStubs\|TestConfiguration"

# 3. Vérifier l'absence d'appels URLSession
check_pattern "URLSession.shared" \
    "Pas d'utilisation de URLSession.shared" \
    "ERROR"

check_pattern "URLRequest" \
    "Pas d'utilisation de URLRequest" \
    "ERROR" \
    "Mock"

# 4. Vérifier la présence de mocks
echo ""
echo "📦 Vérification de la présence des mocks"
echo ""

check_mock_exists() {
    local mock_file=$1
    local mock_name=$2

    echo -n "Mock $mock_name... "
    if [ -f "MediStockTests/Mocks/$mock_file" ]; then
        echo -e "${GREEN}✅ Présent${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}❌ Manquant${NC}"
        ERRORS=$((ERRORS + 1))
    fi
}

check_mock_exists "MockAuthService.swift" "AuthService"
check_mock_exists "MockMedicineDataService.swift" "MedicineDataService"
check_mock_exists "MockAisleDataService.swift" "AisleDataService"
check_mock_exists "MockHistoryDataService.swift" "HistoryDataService"
check_mock_exists "MockRepositories.swift" "Repositories"
check_mock_exists "MockAuthServiceProtocol.swift" "AuthServiceProtocol (nouveau)"

# 5. Vérifier que les tests utilisent des mocks
echo ""
echo "🧪 Vérification de l'utilisation des mocks dans les tests"
echo ""

check_mock_usage() {
    local test_file=$1
    local mock_pattern=$2
    local test_name=$3

    echo -n "Test $test_name utilise des mocks... "
    if grep -q "$mock_pattern" "$test_file" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${YELLOW}⚠️  À vérifier${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
}

if [ -f "MediStockTests/ViewModels/AuthViewModelTests.swift" ]; then
    check_mock_usage "MediStockTests/ViewModels/AuthViewModelTests.swift" "MockAuthRepository" "AuthViewModel"
fi

if [ -f "MediStockTests/ViewModels/MedicineListViewModelTests.swift" ]; then
    check_mock_usage "MediStockTests/ViewModels/MedicineListViewModelTests.swift" "MockMedicineRepository" "MedicineListViewModel"
fi

if [ -f "MediStockTests/Repositories/MedicineRepositoryTests.swift" ]; then
    check_mock_usage "MediStockTests/Repositories/MedicineRepositoryTests.swift" "MockMedicineDataService" "MedicineRepository"
fi

# 6. Vérifier les tests d'intégration problématiques
echo ""
echo "⚠️  Vérification des tests d'intégration potentiellement problématiques"
echo ""

if [ -f "MediStockTests/IntegrationTests/AuthServiceIntegrationTests.swift" ]; then
    echo -n "AuthServiceIntegrationTests.swift... "
    if grep -q "AuthService()" "MediStockTests/IntegrationTests/AuthServiceIntegrationTests.swift"; then
        echo -e "${RED}❌ PROBLÈME : Utilise Firebase réel !${NC}"
        echo "   → Fichier : MediStockTests/IntegrationTests/AuthServiceIntegrationTests.swift"
        echo "   → Action : Migrer vers des mocks ou désactiver"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅ OK${NC}"
        SUCCESS=$((SUCCESS + 1))
    fi
else
    echo "AuthServiceIntegrationTests.swift : Fichier non trouvé ou désactivé ✅"
    SUCCESS=$((SUCCESS + 1))
fi

# 7. Vérifier la configuration de test
echo ""
echo "⚙️  Vérification de la configuration de test"
echo ""

echo -n "TestConfiguration.swift existe... "
if [ -f "MediStockTests/TestConfiguration.swift" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    SUCCESS=$((SUCCESS + 1))
else
    echo -e "${YELLOW}⚠️  Non trouvé${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "BaseTestCase.swift existe... "
if [ -f "MediStockTests/BaseTestCase.swift" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    SUCCESS=$((SUCCESS + 1))
else
    echo -e "${YELLOW}⚠️  Non trouvé${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Documentation MOCK_PATTERNS_GUIDE.md existe... "
if [ -f "MediStockTests/MOCK_PATTERNS_GUIDE.md" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    SUCCESS=$((SUCCESS + 1))
else
    echo -e "${YELLOW}⚠️  Non trouvé${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo -n "Rapport d'audit AUDIT_REPORT.md existe... "
if [ -f "MediStockTests/AUDIT_REPORT.md" ]; then
    echo -e "${GREEN}✅ OK${NC}"
    SUCCESS=$((SUCCESS + 1))
else
    echo -e "${YELLOW}⚠️  Non trouvé${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# Résumé final
echo ""
echo "=================================================="
echo "📊 RÉSUMÉ"
echo "=================================================="
echo ""
echo -e "${GREEN}✅ Succès       : $SUCCESS${NC}"
echo -e "${YELLOW}⚠️  Avertissements : $WARNINGS${NC}"
echo -e "${RED}❌ Erreurs      : $ERRORS${NC}"
echo ""

# Calcul du score d'isolation
TOTAL=$((SUCCESS + WARNINGS + ERRORS))
if [ $TOTAL -gt 0 ]; then
    SCORE=$((SUCCESS * 100 / TOTAL))
    echo "Score d'isolation : $SCORE%"
    echo ""
fi

# Message final
if [ $ERRORS -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}🎉 PARFAIT ! Tous les tests sont complètement isolés.${NC}"
        exit 0
    else
        echo -e "${YELLOW}✅ BIEN ! Tests isolés avec quelques avertissements mineurs.${NC}"
        exit 0
    fi
else
    echo -e "${RED}❌ ATTENTION ! Des problèmes d'isolation ont été détectés.${NC}"
    echo ""
    echo "Actions recommandées :"
    echo "1. Consultez AUDIT_REPORT.md pour les détails"
    echo "2. Lisez MOCK_PATTERNS_GUIDE.md pour les bonnes pratiques"
    echo "3. Corrigez les fichiers problématiques identifiés ci-dessus"
    echo ""
    exit 1
fi
