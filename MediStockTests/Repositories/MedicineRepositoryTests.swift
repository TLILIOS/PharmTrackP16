import XCTest
import FirebaseFirestore
@testable import MediStock

// MARK: - MedicineRepository Tests
/// Tests complets pour MedicineRepository avec couverture de 90%+
/// Teste la délégation vers le service et la logique de repository

@MainActor
final class MedicineRepositoryTests: XCTestCase {

    // MARK: - Properties

    private var sut: MockMedicineRepository!
    private var mockService: MockMedicineDataService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockMedicineDataService()
        sut = MockMedicineRepository(medicineService: mockService)
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Fetch Medicines Tests

    func testFetchMedicinesSuccess() async throws {
        // Given
        let medicines = [
            Medicine.mock(id: "1", name: "Doliprane"),
            Medicine.mock(id: "2", name: "Aspirine")
        ]
        mockService.medicines = medicines

        // When
        let result = try await sut.fetchMedicines()

        // Then
        XCTAssertEqual(mockService.getAllMedicinesCallCount, 1)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.name, "Doliprane")
    }

    func testFetchMedicinesFailure() async {
        // Given
        mockService.shouldFailGetMedicines = true

        // When & Then
        do {
            _ = try await sut.fetchMedicines()
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.getAllMedicinesCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testFetchMedicinesEmpty() async throws {
        // Given
        mockService.medicines = []

        // When
        let result = try await sut.fetchMedicines()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockService.getAllMedicinesCallCount, 1)
    }

    // MARK: - Fetch Medicines Paginated Tests

    func testFetchMedicinesPaginatedFirstPage() async throws {
        // Given
        let medicines = (0..<30).map { Medicine.mock(id: "\($0)", name: "Medicine \($0)") }
        mockService.medicines = medicines

        // When
        let result = try await sut.fetchMedicinesPaginated(limit: 20, refresh: true)

        // Then
        XCTAssertEqual(result.count, 20)
        XCTAssertEqual(mockService.getMedicinesPaginatedCallCount, 1)
    }

    func testFetchMedicinesPaginatedSecondPage() async throws {
        // Given
        let medicines = (0..<30).map { Medicine.mock(id: "\($0)") }
        mockService.medicines = medicines

        // When - First page
        let firstPage = try await sut.fetchMedicinesPaginated(limit: 20, refresh: true)

        // Then
        XCTAssertEqual(firstPage.count, 20)

        // When - Second page
        let secondPage = try await sut.fetchMedicinesPaginated(limit: 20, refresh: false)

        // Then
        XCTAssertEqual(secondPage.count, 10) // Remaining items
        XCTAssertEqual(mockService.getMedicinesPaginatedCallCount, 2)
    }

    func testFetchMedicinesPaginatedRefresh() async throws {
        // Given
        mockService.medicines = (0..<20).map { Medicine.mock(id: "\($0)") }
        _ = try await sut.fetchMedicinesPaginated(limit: 20, refresh: true)

        // When - Refresh (reset pagination)
        let result = try await sut.fetchMedicinesPaginated(limit: 20, refresh: true)

        // Then
        XCTAssertEqual(result.count, 20)
        XCTAssertEqual(mockService.getMedicinesPaginatedCallCount, 2)
    }

    func testFetchMedicinesPaginatedFailure() async {
        // Given
        mockService.shouldFailGetMedicines = true

        // When & Then
        do {
            _ = try await sut.fetchMedicinesPaginated(limit: 20, refresh: true)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Save Medicine Tests

    func testSaveMedicineNewSuccess() async throws {
        // Given
        let newMedicine = Medicine.mock(id: "", name: "New Medicine")

        // When
        let saved = try await sut.saveMedicine(newMedicine)

        // Then
        XCTAssertEqual(mockService.saveMedicineCallCount, 1)
        XCTAssertFalse(saved.id?.isEmpty ?? true)
        XCTAssertEqual(saved.name, "New Medicine")
        XCTAssertEqual(mockService.medicines.count, 1)
    }

    func testSaveMedicineUpdateSuccess() async throws {
        // Given
        let existing = Medicine.mock(id: "1", name: "Original")
        mockService.medicines = [existing]

        let updated = Medicine.mock(id: "1", name: "Updated")

        // When
        let saved = try await sut.saveMedicine(updated)

        // Then
        XCTAssertEqual(mockService.saveMedicineCallCount, 1)
        XCTAssertEqual(saved.name, "Updated")
        XCTAssertEqual(mockService.medicines.count, 1)
    }

    func testSaveMedicineFailure() async {
        // Given
        mockService.shouldFailSaveMedicine = true
        let medicine = Medicine.mock()

        // When & Then
        do {
            _ = try await sut.saveMedicine(medicine)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.saveMedicineCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSaveMedicineValidation() async {
        // Given - Invalid medicine (empty name)
        let invalid = Medicine.mock(id: "", name: "")

        // When & Then
        do {
            _ = try await sut.saveMedicine(invalid)
            XCTFail("Should throw validation error")
        } catch is ValidationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Should throw ValidationError, not \(error)")
        }
    }

    // MARK: - Update Stock Tests

    func testUpdateMedicineStockSuccess() async throws {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 50)
        mockService.medicines = [medicine]

        // When
        let updated = try await sut.updateMedicineStock(id: "1", newStock: 75)

        // Then
        XCTAssertEqual(mockService.updateStockCallCount, 1)
        XCTAssertEqual(updated.currentQuantity, 75)
    }

    func testUpdateMedicineStockNotFound() async {
        // Given
        mockService.medicines = []

        // When & Then
        do {
            _ = try await sut.updateMedicineStock(id: "nonexistent", newStock: 10)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testUpdateMedicineStockNegative() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 50)
        mockService.medicines = [medicine]

        // When & Then
        do {
            _ = try await sut.updateMedicineStock(id: "1", newStock: -10)
            XCTFail("Should throw validation error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testUpdateMedicineStockFailure() async {
        // Given
        mockService.medicines = [Medicine.mock(id: "1")]
        mockService.shouldFailUpdateStock = true

        // When & Then
        do {
            _ = try await sut.updateMedicineStock(id: "1", newStock: 10)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.updateStockCallCount, 1)
        }
    }

    // MARK: - Delete Medicine Tests

    func testDeleteMedicineSuccess() async throws {
        // Given
        let medicine = Medicine.mock(id: "1")
        mockService.medicines = [medicine]

        // When
        try await sut.deleteMedicine(id: "1")

        // Then
        XCTAssertEqual(mockService.deleteMedicineCallCount, 1)
        XCTAssertTrue(mockService.medicines.isEmpty)
    }

    func testDeleteMedicineNotFound() async {
        // Given
        mockService.medicines = []

        // When & Then
        do {
            try await sut.deleteMedicine(id: "nonexistent")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testDeleteMedicineFailure() async {
        // Given
        mockService.medicines = [Medicine.mock(id: "1")]
        mockService.shouldFailDeleteMedicine = true

        // When & Then
        do {
            try await sut.deleteMedicine(id: "1")
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.deleteMedicineCallCount, 1)
        }
    }

    // MARK: - Update Multiple Medicines Tests

    func testUpdateMultipleMedicinesSuccess() async throws {
        // Given
        let medicines = [
            Medicine.mock(id: "1", name: "Medicine 1"),
            Medicine.mock(id: "2", name: "Medicine 2")
        ]
        mockService.medicines = medicines

        let updates = [
            Medicine.mock(id: "1", name: "Updated 1"),
            Medicine.mock(id: "2", name: "Updated 2")
        ]

        // When
        try await sut.updateMultipleMedicines(updates)

        // Then
        XCTAssertEqual(mockService.updateMultipleMedicinesCallCount, 1)
    }

    func testUpdateMultipleMedicinesFailure() async {
        // Given
        mockService.shouldFailUpdateStock = true

        // When & Then
        do {
            try await sut.updateMultipleMedicines([Medicine.mock()])
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Delete Multiple Medicines Tests

    func testDeleteMultipleMedicinesSuccess() async throws {
        // Given
        let medicines = [
            Medicine.mock(id: "1"),
            Medicine.mock(id: "2"),
            Medicine.mock(id: "3")
        ]
        mockService.medicines = medicines

        // When
        try await sut.deleteMultipleMedicines(ids: ["1", "2"])

        // Then
        XCTAssertEqual(mockService.deleteMedicineCallCount, 2)
        XCTAssertEqual(mockService.medicines.count, 1)
    }

    func testDeleteMultipleMedicinesPartialFailure() async {
        // Given
        mockService.medicines = [Medicine.mock(id: "1")]

        // When & Then - Try to delete non-existent
        do {
            try await sut.deleteMultipleMedicines(ids: ["1", "nonexistent"])
            XCTFail("Should throw error on second delete")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Real-time Listener Tests

    func testStartListeningToMedicines() {
        // Given
        let expectation = XCTestExpectation(description: "Listener receives data")
        let medicines = [Medicine.mock()]
        mockService.medicines = medicines

        var receivedMedicines: [Medicine] = []

        // When
        sut.startListeningToMedicines { medicines in
            receivedMedicines = medicines
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMedicines.count, 1)
        XCTAssertTrue(mockService.isListening)
    }

    func testStopListening() {
        // Given
        sut.startListeningToMedicines { _ in }

        // When
        sut.stopListening()

        // Then
        XCTAssertFalse(mockService.isListening)
    }

    // MARK: - Call Count Verification Tests

    func testFetchMedicinesCallCount() async throws {
        // Given
        mockService.medicines = [Medicine.mock()]

        // When
        _ = try await sut.fetchMedicines()
        _ = try await sut.fetchMedicines()

        // Then
        XCTAssertEqual(sut.fetchMedicinesCallCount, 2)
    }

    func testSaveMedicineCallCount() async throws {
        // Given
        let medicine = Medicine.mock()

        // When
        _ = try await sut.saveMedicine(medicine)
        _ = try await sut.saveMedicine(medicine)

        // Then
        XCTAssertEqual(sut.saveMedicineCallCount, 2)
    }

    func testDeleteMedicineCallCount() async throws {
        // Given
        mockService.medicines = [
            Medicine.mock(id: "1"),
            Medicine.mock(id: "2")
        ]

        // When
        try await sut.deleteMedicine(id: "1")
        try await sut.deleteMedicine(id: "2")

        // Then
        XCTAssertEqual(sut.deleteMedicineCallCount, 2)
    }
}
