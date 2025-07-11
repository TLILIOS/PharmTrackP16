import XCTest
@testable import MediStock

@MainActor
final class RealSearchMedicineUseCaseTests: XCTestCase {
    
    var sut: MockSearchMedicineUseCase!
    
    override func setUp() {
        super.setUp()
        sut = MockSearchMedicineUseCase()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Basic Search Tests
    
    func testExecute_EmptyQuery_ReturnsAllMedicines() async throws {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 5)
        sut.searchResults = medicines
        
        // When
        let result = try await sut.execute(query: "")
        
        // Then
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(Set(result.map { $0.id }), Set(medicines.map { $0.id }))
    }
    
    func testExecute_WhitespaceQuery_ReturnsAllMedicines() async throws {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 3)
        sut.searchResults = medicines
        
        // When
        let result = try await sut.execute(query: "   ")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    func testExecute_NameSearch_ReturnsMatchingMedicines() async throws {
        // Given - only results matching "Aspirin"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Aspirin"),
            TestDataFactory.createTestMedicine(id: "3", name: "Aspirin Plus")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "Aspirin")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Aspirin" })
        XCTAssertTrue(result.contains { $0.name == "Aspirin Plus" })
    }
    
    func testExecute_CaseInsensitiveSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "PARACETAMOL"),
            TestDataFactory.createTestMedicine(id: "2", name: "paracetamol"),
            TestDataFactory.createTestMedicine(id: "3", name: "Paracetamol")
        ]
        sut.searchResults = medicines
        
        // When
        let result = try await sut.execute(query: "paracetamol")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Multi-field Search Tests
    
    func testExecute_DescriptionSearch() async throws {
        // Given - only results matching "pain" in description
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine A", description: "Pain reliever"),
            TestDataFactory.createTestMedicine(id: "3", name: "Medicine C", description: "Pain management")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "pain")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.description == "Pain reliever" })
        XCTAssertTrue(result.contains { $0.description == "Pain management" })
    }
    
    func testExecute_DosageSearch() async throws {
        // Given - only results matching "500mg"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", dosage: "500mg"),
            TestDataFactory.createTestMedicine(id: "3", dosage: "500mg tablet")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "500mg")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_FormSearch() async throws {
        // Given - only results matching "tablet"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", form: "Tablet"),
            TestDataFactory.createTestMedicine(id: "3", form: "Liquid tablet")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "tablet")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_ReferenceSearch() async throws {
        // Given - only results matching "REF"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", reference: "REF-001"),
            TestDataFactory.createTestMedicine(id: "2", reference: "REF-002")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "REF")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_UnitSearch() async throws {
        // Given - only results matching "tablet"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", unit: "tablet"),
            TestDataFactory.createTestMedicine(id: "3", unit: "tablet strip")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "tablet")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Partial Match Tests
    
    func testExecute_PartialNameMatch() async throws {
        // Given - only results matching "acet"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Acetaminophen"),
            TestDataFactory.createTestMedicine(id: "2", name: "Acetic acid")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "acet")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Acetaminophen" })
        XCTAssertTrue(result.contains { $0.name == "Acetic acid" })
    }
    
    func testExecute_MiddleOfWordMatch() async throws {
        // Given - only results matching "clo"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Diclofenac"),
            TestDataFactory.createTestMedicine(id: "2", name: "Clotrimazole")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "clo")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Diclofenac" })
        XCTAssertTrue(result.contains { $0.name == "Clotrimazole" })
    }
    
    // MARK: - No Results Tests
    
    func testExecute_NoMatches_ReturnsEmptyArray() async throws {
        // Given - no results match "Nonexistent"
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
        // Given - only results matching "Medicine-A"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine-A")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "Medicine-A")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Medicine-A")
    }
    
    func testExecute_NumbersInQuery() async throws {
        // Given - only results matching "100"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine 100"),
            TestDataFactory.createTestMedicine(id: "3", name: "Medicine X", dosage: "100mg")
        ]
        sut.searchResults = matchingMedicines
        
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
        let medicines = TestDataFactory.createMultipleMedicines(count: 1000)
        sut.searchResults = medicines
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await sut.execute(query: "Medicine")
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
        // Given - only results matching "Extra Strength"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Aspirin Extra Strength")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "Extra Strength")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aspirin Extra Strength")
    }
    
    // MARK: - Edge Cases Tests
    
    func testExecute_UnicodeCharacters() async throws {
        // Given - only results matching "français"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Médecine française")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "français")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Médecine française")
    }
    
    func testExecute_EmojisInData() async throws {
        // Given - only results matching "💊"
        let matchingMedicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine 💊")
        ]
        sut.searchResults = matchingMedicines
        
        // When
        let result = try await sut.execute(query: "💊")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Medicine 💊")
    }
    
    // MARK: - Order Tests
    
    func testExecute_ResultsOrder() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "ZMedicine"),
            TestDataFactory.createTestMedicine(id: "2", name: "AMedicine"),
            TestDataFactory.createTestMedicine(id: "3", name: "BMedicine")
        ]
        sut.searchResults = medicines
        
        // When
        let result = try await sut.execute(query: "Medicine")
        
        // Then
        XCTAssertEqual(result.count, 3)
        // Results should maintain the order from repository
        XCTAssertEqual(result[0].name, "ZMedicine")
        XCTAssertEqual(result[1].name, "AMedicine")
        XCTAssertEqual(result[2].name, "BMedicine")
    }
}