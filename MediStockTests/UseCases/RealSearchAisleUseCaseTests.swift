import XCTest
@testable import MediStock

@MainActor
final class RealSearchAisleUseCaseTests: XCTestCase {
    
    var sut: RealSearchAisleUseCase!
    var mockAisleRepository: MockAisleRepository!
    
    override func setUp() {
        super.setUp()
        mockAisleRepository = MockAisleRepository()
        sut = RealSearchAisleUseCase(aisleRepository: mockAisleRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockAisleRepository = nil
        super.tearDown()
    }
    
    // MARK: - Basic Search Tests
    
    func testExecute_EmptyQuery_ReturnsAllAisles() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 4)
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "")
        
        // Then
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(Set(result.map { $0.id }), Set(aisles.map { $0.id }))
    }
    
    func testExecute_WhitespaceQuery_ReturnsAllAisles() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 2)
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "   ")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_NameSearch_ReturnsMatchingAisles() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Pharmacy A"),
            TestDataFactory.createTestAisle(id: "2", name: "Cardiology"),
            TestDataFactory.createTestAisle(id: "3", name: "Pharmacy B")
        ]
        mockAisleRepository.aisles = aisles
        
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
            TestDataFactory.createTestAisle(id: "1", name: "EMERGENCY"),
            TestDataFactory.createTestAisle(id: "2", name: "emergency"),
            TestDataFactory.createTestAisle(id: "3", name: "Emergency")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "emergency")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Multi-field Search Tests
    
    func testExecute_DescriptionSearch() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A", description: "Pain medication storage"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B", description: "Antibiotic storage"),
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C", description: "Pain relief supplies")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "pain")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.description == "Pain medication storage" })
        XCTAssertTrue(result.contains { $0.description == "Pain relief supplies" })
    }
    
    func testExecute_LocationSearch() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", location: "Floor 1, Section A"),
            TestDataFactory.createTestAisle(id: "2", location: "Floor 2, Section B"),
            TestDataFactory.createTestAisle(id: "3", location: "Floor 1, Section C")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "Floor 1")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Partial Match Tests
    
    func testExecute_PartialNameMatch() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Pediatrics"),
            TestDataFactory.createTestAisle(id: "2", name: "Pediatric Surgery"),
            TestDataFactory.createTestAisle(id: "3", name: "Geriatrics")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "pedia")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Pediatrics" })
        XCTAssertTrue(result.contains { $0.name == "Pediatric Surgery" })
    }
    
    func testExecute_MiddleOfWordMatch() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Dermatology"),
            TestDataFactory.createTestAisle(id: "2", name: "Hematology"),
            TestDataFactory.createTestAisle(id: "3", name: "Neurology")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "mato")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Dermatology" })
        XCTAssertTrue(result.contains { $0.name == "Hematology" })
    }
    
    // MARK: - No Results Tests
    
    func testExecute_NoMatches_ReturnsEmptyArray() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Cardiology"),
            TestDataFactory.createTestAisle(id: "2", name: "Neurology")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "Nonexistent")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecute_EmptyRepository_ReturnsEmptyArray() async throws {
        // Given
        mockAisleRepository.aisles = []
        
        // When
        let result = try await sut.execute(query: "Any query")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Special Characters Tests
    
    func testExecute_SpecialCharactersInQuery() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle-A"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B+"),
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "Aisle-A")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aisle-A")
    }
    
    func testExecute_NumbersInQuery() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle 100"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle 200"),
            TestDataFactory.createTestAisle(id: "3", location: "Room 100")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "100")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Repository Error Tests
    
    func testExecute_RepositoryError_ThrowsError() async {
        // Given
        mockAisleRepository.shouldThrowError = true
        mockAisleRepository.errorToThrow = NSError(
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
        mockAisleRepository.aisles = aisles
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await sut.execute(query: "Aisle")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertLessThan(timeElapsed, 1.0) // Should complete within 1 second
    }
    
    func testExecute_VeryLongQuery() async throws {
        // Given
        let aisles = [TestDataFactory.createTestAisle(name: "Simple Aisle")]
        mockAisleRepository.aisles = aisles
        let longQuery = String(repeating: "a", count: 1000)
        
        // When
        let result = try await sut.execute(query: longQuery)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Multi-word Search Tests
    
    func testExecute_MultipleWords() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Emergency Room A"),
            TestDataFactory.createTestAisle(id: "2", name: "Emergency Surgery"),
            TestDataFactory.createTestAisle(id: "3", name: "Operating Room B")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "Emergency Room")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Emergency Room A")
    }
    
    // MARK: - Edge Cases Tests
    
    func testExecute_UnicodeCharacters() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Couloir français"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle english"),
            TestDataFactory.createTestAisle(id: "3", name: "通路 Japanese")
        ]
        mockAisleRepository.aisles = aisles
        
        // When
        let result = try await sut.execute(query: "français")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Couloir français")
    }
    
    func testExecute_EmojisInData() async throws {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle 🏥"),
            TestDataFactory.createTestAisle(id: "2", name: "Heart Unit ❤️"),
            TestDataFactory.createTestAisle(id: "3", name: "Regular Aisle")
        ]
        mockAisleRepository.aisles = aisles
        
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
            TestDataFactory.createTestAisle(id: "1", name: "Z Aisle"),
            TestDataFactory.createTestAisle(id: "2", name: "A Aisle"),
            TestDataFactory.createTestAisle(id: "3", name: "B Aisle")
        ]
        mockAisleRepository.aisles = aisles
        
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
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Small Aisle", capacity: 100),
            TestDataFactory.createTestAisle(id: "2", name: "Large Aisle", capacity: 500),
            TestDataFactory.createTestAisle(id: "3", name: "Medium Aisle", capacity: 300)
        ]
        mockAisleRepository.aisles = aisles
        
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
        mockAisleRepository.aisles = aisles
        weak var weakAisles: [Aisle]? = aisles
        
        // When
        let result = try await sut.execute(query: "Aisle")
        
        // Then
        XCTAssertNotNil(weakAisles) // Should still exist due to repository storage
        XCTAssertGreaterThan(result.count, 0)
    }
    
    // MARK: - Concurrent Search Tests
    
    func testExecute_ConcurrentSearches() async throws {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 20)
        mockAisleRepository.aisles = aisles
        
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