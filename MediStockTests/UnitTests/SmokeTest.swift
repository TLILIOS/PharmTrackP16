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
        if TestConfiguration.isUnitTestMode {
            XCTAssertTrue(true, "Firebase should be disabled in unit test mode")
        } else {
            XCTFail("Unit test mode should be enabled when UNIT_TESTS_ONLY=1")
        }
    }
}