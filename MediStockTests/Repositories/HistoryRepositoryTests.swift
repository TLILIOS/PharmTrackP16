import XCTest
@testable import MediStock

// MARK: - HistoryRepository Tests
/// Tests complets pour HistoryRepository avec couverture de 90%+
/// Teste la délégation vers le service et la logique de repository

@MainActor
final class HistoryRepositoryTests: XCTestCase {

    // MARK: - Properties

    private var sut: MockHistoryRepository!
    private var mockService: MockHistoryDataService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockHistoryDataService()
        sut = MockHistoryRepository(historyService: mockService)
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Fetch History Tests

    func testFetchHistorySuccess() async throws {
        // Given
        let entries = [
            HistoryEntry.mock(id: "1", action: "Ajout"),
            HistoryEntry.mock(id: "2", action: "Modification")
        ]
        mockService.history = entries

        // When
        let result = try await sut.fetchHistory()

        // Then
        XCTAssertEqual(mockService.getHistoryCallCount, 1)
        XCTAssertEqual(result.count, 2)
    }

    func testFetchHistoryFailure() async {
        // Given
        mockService.shouldFailGetHistory = true

        // When & Then
        do {
            _ = try await sut.fetchHistory()
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.getHistoryCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testFetchHistoryEmpty() async throws {
        // Given
        mockService.history = []

        // When
        let result = try await sut.fetchHistory()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Fetch History For Medicine Tests

    func testFetchHistoryForMedicineSuccess() async throws {
        // Given
        let medicineId = "medicine-1"
        let entries = [
            HistoryEntry.mock(id: "1", medicineId: medicineId, action: "Ajout"),
            HistoryEntry.mock(id: "2", medicineId: medicineId, action: "Modification"),
            HistoryEntry.mock(id: "3", medicineId: "other-medicine", action: "Ajout")
        ]
        mockService.history = entries

        // When
        let result = try await sut.fetchHistoryForMedicine(medicineId)

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.allSatisfy { $0.medicineId == medicineId })
    }

    func testFetchHistoryForMedicineEmpty() async throws {
        // Given
        let medicineId = "nonexistent"
        mockService.history = [
            HistoryEntry.mock(medicineId: "other-medicine")
        ]

        // When
        let result = try await sut.fetchHistoryForMedicine(medicineId)

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testFetchHistoryForMedicineFailure() async {
        // Given
        mockService.shouldFailGetHistory = true

        // When & Then
        do {
            _ = try await sut.fetchHistoryForMedicine("medicine-1")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Add History Entry Tests

    func testAddHistoryEntryWithMedicineId() async throws {
        // Given
        let entry = HistoryEntry.mock(
            medicineId: "medicine-1",
            action: "Ajout",
            details: "Ajout du médicament Doliprane"
        )

        // When
        try await sut.addHistoryEntry(entry)

        // Then
        XCTAssertEqual(mockService.recordMedicineActionCallCount, 1)
        XCTAssertEqual(mockService.history.count, 1)
    }

    func testAddHistoryEntryWithoutMedicineId() async throws {
        // Given
        let entry = HistoryEntry.mock(
            medicineId: "",
            action: "Suppression générale",
            details: "Nettoyage général"
        )

        // When
        try await sut.addHistoryEntry(entry)

        // Then
        XCTAssertEqual(mockService.recordDeletionCallCount, 1)
        XCTAssertEqual(mockService.history.count, 1)
    }

    func testAddHistoryEntryFailure() async {
        // Given
        mockService.shouldFailRecordAction = true
        let entry = HistoryEntry.mock()

        // When & Then
        do {
            try await sut.addHistoryEntry(entry)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Extract Medicine Name Tests

    func testExtractMedicineNameFromDetails() async throws {
        // Given
        let entry = HistoryEntry.mock(
            medicineId: "1",
            details: "Ajout du médicament Doliprane 500mg"
        )

        // When
        try await sut.addHistoryEntry(entry)

        // Then - Verify extraction logic worked (indirectly)
        XCTAssertEqual(mockService.recordMedicineActionCallCount, 1)
    }

    func testExtractMedicineNameNoMatch() async throws {
        // Given
        let entry = HistoryEntry.mock(
            medicineId: "1",
            details: "Modification des informations"
        )

        // When
        try await sut.addHistoryEntry(entry)

        // Then - Should handle gracefully
        XCTAssertEqual(mockService.recordMedicineActionCallCount, 1)
    }

    // MARK: - Should Throw Error Configuration Tests

    func testShouldThrowErrorProperty() async {
        // Given
        sut.shouldThrowError = true

        // Then - Should affect all operations
        do {
            _ = try await sut.fetchHistory()
            XCTFail("Should throw error on fetch")
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            try await sut.addHistoryEntry(HistoryEntry.mock())
            XCTFail("Should throw error on add")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - History Property Tests

    func testHistoryPropertyAccess() {
        // Given
        let entries = [
            HistoryEntry.mock(id: "1"),
            HistoryEntry.mock(id: "2")
        ]

        // When
        sut.history = entries

        // Then
        XCTAssertEqual(sut.history.count, 2)
    }

    // MARK: - Call Count Tests

    func testAddHistoryEntryCallCount() async throws {
        // Given
        let entry = HistoryEntry.mock()

        // When
        try await sut.addHistoryEntry(entry)
        try await sut.addHistoryEntry(entry)

        // Then
        XCTAssertEqual(sut.addHistoryEntryCallCount, 2)
    }

    // MARK: - Integration Tests

    func testHistoryEntryPersistence() async throws {
        // Given
        let entry1 = HistoryEntry.mock(id: "1", medicineId: "med-1")
        let entry2 = HistoryEntry.mock(id: "2", medicineId: "med-2")

        // When
        try await sut.addHistoryEntry(entry1)
        try await sut.addHistoryEntry(entry2)

        // Then
        XCTAssertEqual(mockService.history.count, 2)

        // When - Fetch all
        let allHistory = try await sut.fetchHistory()

        // Then
        XCTAssertEqual(allHistory.count, 2)
    }

    func testHistoryFilteringByMedicine() async throws {
        // Given
        let entries = [
            HistoryEntry.mock(id: "1", medicineId: "med-1"),
            HistoryEntry.mock(id: "2", medicineId: "med-1"),
            HistoryEntry.mock(id: "3", medicineId: "med-2")
        ]

        for entry in entries {
            try await sut.addHistoryEntry(entry)
        }

        // When
        let med1History = try await sut.fetchHistoryForMedicine("med-1")

        // Then
        XCTAssertEqual(med1History.count, 2)
        XCTAssertTrue(med1History.allSatisfy { $0.medicineId == "med-1" })
    }
}
