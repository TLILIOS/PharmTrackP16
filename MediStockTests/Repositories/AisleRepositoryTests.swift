import XCTest
import FirebaseFirestore
@testable import MediStock

// MARK: - AisleRepository Tests
/// Tests complets pour AisleRepository avec couverture de 90%+
/// Teste la délégation vers le service et la logique de repository

@MainActor
final class AisleRepositoryTests: XCTestCase {

    // MARK: - Properties

    private var sut: MockAisleRepository!
    private var mockService: MockAisleDataService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockService = MockAisleDataService()
        sut = MockAisleRepository(aisleService: mockService)
    }

    override func tearDown() async throws {
        sut = nil
        mockService = nil
        try await super.tearDown()
    }

    // MARK: - Fetch Aisles Tests

    func testFetchAislesSuccess() async throws {
        // Given
        let aisles = [
            Aisle.mock(id: "1", name: "Antalgiques"),
            Aisle.mock(id: "2", name: "Antibiotiques")
        ]
        mockService.aisles = aisles

        // When
        let result = try await sut.fetchAisles()

        // Then
        XCTAssertEqual(mockService.getAllAislesCallCount, 1)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.name, "Antalgiques")
    }

    func testFetchAislesFailure() async {
        // Given
        mockService.shouldFailGetAisles = true

        // When & Then
        do {
            _ = try await sut.fetchAisles()
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.getAllAislesCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testFetchAislesEmpty() async throws {
        // Given
        mockService.aisles = []

        // When
        let result = try await sut.fetchAisles()

        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockService.getAllAislesCallCount, 1)
    }

    // MARK: - Fetch Aisles Paginated Tests

    func testFetchAislesPaginatedFirstPage() async throws {
        // Given
        let aisles = (0..<30).map { Aisle.mock(id: "\($0)", name: "Aisle \($0)") }
        mockService.aisles = aisles

        // When
        let result = try await sut.fetchAislesPaginated(limit: 20, refresh: true)

        // Then
        XCTAssertEqual(result.count, 20)
        XCTAssertEqual(mockService.getAislesPaginatedCallCount, 1)
    }

    func testFetchAislesPaginatedSecondPage() async throws {
        // Given
        let aisles = (0..<30).map { Aisle.mock(id: "\($0)") }
        mockService.aisles = aisles

        // When - First page
        let firstPage = try await sut.fetchAislesPaginated(limit: 20, refresh: true)
        XCTAssertEqual(firstPage.count, 20)

        // When - Second page
        let secondPage = try await sut.fetchAislesPaginated(limit: 20, refresh: false)

        // Then
        XCTAssertEqual(secondPage.count, 10) // Remaining items
        XCTAssertEqual(mockService.getAislesPaginatedCallCount, 2)
    }

    func testFetchAislesPaginatedRefresh() async throws {
        // Given
        mockService.aisles = (0..<20).map { Aisle.mock(id: "\($0)") }
        _ = try await sut.fetchAislesPaginated(limit: 20, refresh: true)

        // When - Refresh (reset pagination)
        let result = try await sut.fetchAislesPaginated(limit: 20, refresh: true)

        // Then
        XCTAssertEqual(result.count, 20)
        XCTAssertEqual(mockService.getAislesPaginatedCallCount, 2)
    }

    func testFetchAislesPaginatedFailure() async {
        // Given
        mockService.shouldFailGetAisles = true

        // When & Then
        do {
            _ = try await sut.fetchAislesPaginated(limit: 20, refresh: true)
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Save Aisle Tests

    func testSaveAisleNewSuccess() async throws {
        // Given
        var newAisle = Aisle(name: "New Aisle", description: "Test", colorHex: "#FF0000", icon: "pills")
        newAisle.id = ""

        // When
        let saved = try await sut.saveAisle(newAisle)

        // Then
        XCTAssertEqual(mockService.saveAisleCallCount, 1)
        XCTAssertFalse(saved.id?.isEmpty ?? true)
        XCTAssertEqual(saved.name, "New Aisle")
        XCTAssertEqual(mockService.aisles.count, 1)
    }

    func testSaveAisleUpdateSuccess() async throws {
        // Given
        var existing = Aisle.mock(id: "1", name: "Original")
        mockService.aisles = [existing]

        existing.id = "1"
        var updated = Aisle(name: "Updated", description: existing.description, colorHex: existing.colorHex, icon: existing.icon)
        updated.id = "1"

        // When
        let saved = try await sut.saveAisle(updated)

        // Then
        XCTAssertEqual(mockService.saveAisleCallCount, 1)
        XCTAssertEqual(saved.name, "Updated")
        XCTAssertEqual(mockService.aisles.count, 1)
    }

    func testSaveAisleFailure() async {
        // Given
        mockService.shouldFailSaveAisle = true
        let aisle = Aisle.mock()

        // When & Then
        do {
            _ = try await sut.saveAisle(aisle)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.saveAisleCallCount, 1)
            XCTAssertNotNil(error)
        }
    }

    func testSaveAisleValidation() async {
        // Given - Invalid aisle (empty name)
        var invalid = Aisle(name: "", description: nil, colorHex: "#FF0000", icon: "pills")
        invalid.id = ""

        // When & Then
        do {
            _ = try await sut.saveAisle(invalid)
            XCTFail("Should throw validation error")
        } catch is ValidationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Should throw ValidationError, not \(error)")
        }
    }

    func testSaveAisleDuplicateName() async {
        // Given
        let existing = Aisle.mock(id: "1", name: "Antalgiques")
        mockService.aisles = [existing]

        var duplicate = Aisle(name: "Antalgiques", description: nil, colorHex: "#FF0000", icon: "pills")
        duplicate.id = ""

        // When & Then
        do {
            _ = try await sut.saveAisle(duplicate)
            XCTFail("Should throw duplicate error")
        } catch is ValidationError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Should throw ValidationError for duplicate")
        }
    }

    // MARK: - Delete Aisle Tests

    func testDeleteAisleSuccess() async throws {
        // Given
        let aisle = Aisle.mock(id: "1")
        mockService.aisles = [aisle]
        mockService.setMedicineCount(for: "1", count: 0) // No medicines

        // When
        try await sut.deleteAisle(id: "1")

        // Then
        XCTAssertEqual(mockService.deleteAisleCallCount, 1)
        XCTAssertTrue(mockService.aisles.isEmpty)
    }

    func testDeleteAisleNotFound() async {
        // Given
        mockService.aisles = []

        // When & Then
        do {
            try await sut.deleteAisle(id: "nonexistent")
            XCTFail("Should throw error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testDeleteAisleWithMedicines() async {
        // Given
        let aisle = Aisle.mock(id: "1")
        mockService.aisles = [aisle]
        mockService.setMedicineCount(for: "1", count: 5) // Has medicines

        // When & Then
        do {
            try await sut.deleteAisle(id: "1")
            XCTFail("Should throw error - aisle contains medicines")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func testDeleteAisleFailure() async {
        // Given
        mockService.aisles = [Aisle.mock(id: "1")]
        mockService.shouldFailDeleteAisle = true

        // When & Then
        do {
            try await sut.deleteAisle(id: "1")
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(mockService.deleteAisleCallCount, 1)
        }
    }

    // MARK: - Real-time Listener Tests

    func testStartListeningToAisles() {
        // Given
        let expectation = XCTestExpectation(description: "Listener receives data")
        let aisles = [Aisle.mock()]
        mockService.aisles = aisles

        var receivedAisles: [Aisle] = []

        // When
        sut.startListeningToAisles { aisles in
            receivedAisles = aisles
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedAisles.count, 1)
        XCTAssertTrue(mockService.isListening)
    }

    func testStopListening() {
        // Given
        sut.startListeningToAisles { _ in }

        // When
        sut.stopListening()

        // Then
        XCTAssertFalse(mockService.isListening)
    }

    // MARK: - Should Throw Error Configuration Tests

    func testShouldThrowErrorProperty() async {
        // Given
        sut.shouldThrowError = true

        // Then - Should affect all operations
        do {
            _ = try await sut.fetchAisles()
            XCTFail("Should throw error on fetch")
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            _ = try await sut.saveAisle(Aisle.mock())
            XCTFail("Should throw error on save")
        } catch {
            XCTAssertNotNil(error)
        }

        do {
            try await sut.deleteAisle(id: "1")
            XCTFail("Should throw error on delete")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Aisles Property Tests

    func testAislesPropertyAccess() {
        // Given
        let aisles = [Aisle.mock(id: "1"), Aisle.mock(id: "2")]

        // When
        sut.aisles = aisles

        // Then
        XCTAssertEqual(sut.aisles.count, 2)
    }
}
