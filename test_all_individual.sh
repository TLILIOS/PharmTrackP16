#!/bin/bash

# Script pour tester tous les tests individuellement et identifier les échecs

echo "=== DÉBUT DES TESTS INDIVIDUELS ==="
echo ""

# Tableau pour stocker les résultats
declare -a FAILED_TESTS=()
declare -a PASSED_TESTS=()

# Fonction pour exécuter un test
run_test() {
    local test_class=$1
    local test_method=$2
    local full_test="${test_class}/${test_method}"
    
    echo "Test: $full_test"
    
    # Exécuter le test avec timeout
    if timeout 120 xcodebuild test \
        -scheme MediStock \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:"MediStockTests/$full_test" \
        CODE_SIGNING_ALLOWED=NO \
        -quiet 2>&1 | grep -q "** TEST SUCCEEDED **"; then
        echo "✅ PASS"
        PASSED_TESTS+=("$full_test")
    else
        echo "❌ FAIL"
        FAILED_TESTS+=("$full_test")
    fi
    echo ""
}

# Tests AuthViewModelTests
echo "=== AuthViewModelTests ==="
run_test "AuthViewModelTests" "testSignInSuccess"
run_test "AuthViewModelTests" "testSignInError"
run_test "AuthViewModelTests" "testSignUpSuccess"
run_test "AuthViewModelTests" "testSignUpError"
run_test "AuthViewModelTests" "testSignOutSuccess"
run_test "AuthViewModelTests" "testSignOutError"
run_test "AuthViewModelTests" "testAuthenticationStateObserver"
run_test "AuthViewModelTests" "testLoadingStateDuringSignIn"
run_test "AuthViewModelTests" "testClearError"

# Tests ValidationIntegrationTests
echo "=== ValidationIntegrationTests ==="
run_test "ValidationIntegrationTests" "testCreateAisleWorkflow_ValidData"
run_test "ValidationIntegrationTests" "testCreateAisleWorkflow_InvalidData"
run_test "ValidationIntegrationTests" "testCreateAisleWorkflow_DuplicateName"
run_test "ValidationIntegrationTests" "testCreateMedicineWorkflow_ValidData"
run_test "ValidationIntegrationTests" "testCreateMedicineWorkflow_InvalidThresholds"
run_test "ValidationIntegrationTests" "testCreateMedicineWorkflow_ExpiredDate"
run_test "ValidationIntegrationTests" "testCreateMedicineWorkflow_InvalidAisleReference"
run_test "ValidationIntegrationTests" "testAdjustStockWorkflow_Valid"
run_test "ValidationIntegrationTests" "testAdjustStockWorkflow_NegativeStock"
run_test "ValidationIntegrationTests" "testValidationPerformance"

# Résumé
echo ""
echo "=== RÉSUMÉ DES TESTS ==="
echo "Tests réussis: ${#PASSED_TESTS[@]}"
echo "Tests échoués: ${#FAILED_TESTS[@]}"
echo ""

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo "Tests qui ont échoué:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  ❌ $test"
    done
else
    echo "✅ Tous les tests sont passés!"
fi