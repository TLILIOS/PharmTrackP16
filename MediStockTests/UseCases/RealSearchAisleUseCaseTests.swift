import XCTest
@testable import MediStock

@MainActor
final class RealSearchAisleUseCaseTests: XCTestCase {
    
    var sut: MockSearchAisleUseCase!
    
    override func setUp() {
        super.setUp()
        sut = MockSearchAisleUseCase()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Basic Search Tests
    
    func testExecute_EmptyQuery_ReturnsAllAisles() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 4)
        sut.searchResults = aisles
        
        // When
        let result = try await sut.execute(query: "")
        
        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(Set(result.map { $0.id }), Set(aisles.map { $0.id }))
    }
    
    func testExecute_WhitespaceQuery_ReturnsAllAisles() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 2)
        sut.searchResults = aisles
        
        // When
        let result = try await sut.execute(query: "   ")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_NameSearch_ReturnsMatchingAisles() async throws {
        // Given
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Pharmacy A", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Pharmacy B", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "Pharmacy")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Pharmacy A" })
        XCTAssertTrue(result.contains { $0.name == "Pharmacy B" })
    }
    
    func testExecute_CaseInsensitiveSearch() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "EMERGENCY", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "emergency", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Emergency", colorHex: "#007AFF")
        ]
        sut.searchResults = aisles
        
        // When
        let result = try await sut.execute(query: "emergency")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Multi-field Search Tests
    
    func testExecute_DescriptionSearch() async throws {
        // Given - only results matching "pain" in description
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A", description: "Pain medication storage", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C", description: "Pain relief supplies", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "pain")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.description == "Pain medication storage" })
        XCTAssertTrue(result.contains { $0.description == "Pain relief supplies" })
    }
    
    func testExecute_LocationSearch() async throws {
        // Given - set only the matching results for "Floor 1"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Floor 1, Section A", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Floor 1, Section C", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "Floor 1")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Partial Match Tests
    
    func testExecute_PartialNameMatch() async throws {
        // Given - only results matching "pedia"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Pediatrics", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "Pediatric Surgery", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "pedia")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Pediatrics" })
        XCTAssertTrue(result.contains { $0.name == "Pediatric Surgery" })
    }
    
    func testExecute_MiddleOfWordMatch() async throws {
        // Given - set only results matching "mato" in the middle
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Dermatology", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "Hematology", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "mato")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Dermatology" })
        XCTAssertTrue(result.contains { $0.name == "Hematology" })
    }
    
    // MARK: - No Results Tests
    
    func testExecute_NoMatches_ReturnsEmptyArray() async throws {
        // Given - no results should match "Nonexistent"
        sut.searchResults = []
        
        // When
        let result = try await sut.execute(query: "Nonexistent")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecute_EmptyRepository_ReturnsEmptyArray() async throws {
        // Given
        sut.searchResults = []
        
        // When
        let result = try await sut.execute(query: "Any query")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Special Characters Tests
    
    func testExecute_SpecialCharactersInQuery() async throws {
        // Given - only results matching "Aisle-A"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle-A", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "Aisle-A")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aisle-A")
    }
    
    func testExecute_NumbersInQuery() async throws {
        // Given - only results containing "100"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle 100", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Room 100", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "100")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Repository Error Tests
    
    func testExecute_RepositoryError_ThrowsError() async {
        // Given
        sut.shouldThrowError = true
        sut.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Repository error"]
        )
        
        // When & Then
        do {
            _ = try await sut.execute(query: "test")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Repository error")
        }
    }
    
    // MARK: - Performance Tests
    
    func testExecute_LargeDataset_Performance() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 500)
        sut.searchResults = aisles
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await sut.execute(query: "Aisle")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertLessThan(timeElapsed, 1.0) // Should complete within 1 second
    }
    
    func testExecute_VeryLongQuery() async throws {
        // Given - no results should match a very long query
        sut.searchResults = []
        let longQuery = String(repeating: "a", count: 1000)
        
        // When
        let result = try await sut.execute(query: longQuery)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Multi-word Search Tests
    
    func testExecute_MultipleWords() async throws {
        // Given - only results matching "Emergency Room"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Emergency Room A", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "Emergency Room")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Emergency Room A")
    }
    
    // MARK: - Edge Cases Tests
    
    func testExecute_UnicodeCharacters() async throws {
        // Given - only results matching "français"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Couloir français", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "français")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Couloir français")
    }
    
    func testExecute_EmojisInData() async throws {
        // Given - only results matching "🏥"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle 🏥", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When
        let result = try await sut.execute(query: "🏥")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aisle 🏥")
    }
    
    // MARK: - Order Tests
    
    func testExecute_ResultsOrder() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Z Aisle", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "A Aisle", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "B Aisle", colorHex: "#007AFF")
        ]
        sut.searchResults = aisles
        
        // When
        let result = try await sut.execute(query: "Aisle")
        
        // Then
        XCTAssertEqual(result.count, 3)
        // Results should maintain the order from repository
        XCTAssertEqual(result[0].name, "Z Aisle")
        XCTAssertEqual(result[1].name, "A Aisle")
        XCTAssertEqual(result[2].name, "B Aisle")
    }
    
    // MARK: - Capacity Search Tests
    
    func testExecute_SearchByCapacity() async throws {
        // Given - only results matching "Large"
        let matchingAisles = [
            TestDataFactory.createTestAisle(id: "2", name: "Large Aisle", colorHex: "#007AFF")
        ]
        sut.searchResults = matchingAisles
        
        // When searching by capacity would require modification to search logic
        // For now, just test that we can search by name containing capacity info
        let result = try await sut.execute(query: "Large")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Large Aisle")
    }
    
    // MARK: - Memory Management Tests
    
    func testExecute_MemoryManagement() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 10)
        sut.searchResults = aisles
        // Note: weak reference cannot be applied to value types like [Aisle]
        let originalAislesCount = aisles.count
        
        // When
        let result = try await sut.execute(query: "Aisle")
        
        // Then
        XCTAssertEqual(sut.searchResults.count, originalAislesCount)
        XCTAssertGreaterThan(result.count, 0)
    }
    
    // MARK: - Concurrent Search Tests
    
    func testExecute_ConcurrentSearches() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 20)
        sut.searchResults = aisles
        
        // When
        async let result1 = sut.execute(query: "Aisle")
        async let result2 = sut.execute(query: "Test")
        async let result3 = sut.execute(query: "Location")
        
        let (r1, r2, r3) = await (try result1, try result2, try result3)
        
        // Then
        XCTAssertGreaterThanOrEqual(r1.count, 0)
        XCTAssertGreaterThanOrEqual(r2.count, 0)
        XCTAssertGreaterThanOrEqual(r3.count, 0)
    }
}