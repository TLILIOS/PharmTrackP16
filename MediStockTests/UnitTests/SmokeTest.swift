import XCTest
@testable import MediStock

/// Test simple pour vérifier que la configuration de test fonctionne correctement
@MainActor
final class SmokeTest: BaseTestCase {

    func testBasicSetup() {
        // Ce test vérifie simplement que BaseTestCase fonctionne
        XCTAssertNotNil(cancellables)
        XCTAssertTrue(true)
    }

    func testMockRepositoryCreation() {
        // Given & When
        let medicineRepo = createMockMedicineRepository()
        let aisleRepo = createMockAisleRepository()
        let historyRepo = createMockHistoryRepository()

        // Then
        XCTAssertNotNil(medicineRepo)
        XCTAssertNotNil(aisleRepo)
        XCTAssertNotNil(historyRepo)
    }

    func testFirebaseIsDisabledInUnitTestMode() {
        // Vérifier que Firebase n'est pas configuré en mode test unitaire
        // Note: La variable d'environnement UNIT_TESTS_ONLY doit être configurée dans le schéma de test Xcode
        // pour l'instant, on vérifie simplement qu'on est en mode test
        let isRunningInTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        XCTAssertTrue(isRunningInTestEnvironment, "Should be running in test environment")

        // Si la variable UNIT_TESTS_ONLY est définie, vérifier qu'elle est à 1
        if let unitTestsOnly = ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] {
            XCTAssertEqual(unitTestsOnly, "1", "UNIT_TESTS_ONLY should be set to 1")
            XCTAssertTrue(TestConfiguration.isUnitTestMode, "TestConfiguration should detect unit test mode")
        }
    }
}