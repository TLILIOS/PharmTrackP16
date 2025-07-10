import XCTest
@testable import MediStock

@MainActor
final class RealSearchMedicineUseCaseTests: XCTestCase {
    
    var sut: RealSearchMedicineUseCase!
    var mockMedicineRepository: MockMedicineRepository!
    
    override func setUp() {
        super.setUp()
        mockMedicineRepository = MockMedicineRepository()
        sut = RealSearchMedicineUseCase(medicineRepository: mockMedicineRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockMedicineRepository = nil
        super.tearDown()
    }
    
    // MARK: - Basic Search Tests
    
    func testExecute_EmptyQuery_ReturnsAllMedicines() async throws {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 5)
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "")
        
        // Then
        XCTAssertEqual(result.count, 5)
        XCTAssertEqual(Set(result.map { $0.id }), Set(medicines.map { $0.id }))
    }
    
    func testExecute_WhitespaceQuery_ReturnsAllMedicines() async throws {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 3)
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "   ")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    func testExecute_NameSearch_ReturnsMatchingMedicines() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Aspirin"),
            TestDataFactory.createTestMedicine(id: "2", name: "Ibuprofen"),
            TestDataFactory.createTestMedicine(id: "3", name: "Aspirin Plus")
        ]
        mockMedicineRepository.medicines = medicines
        
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
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "paracetamol")
        
        // Then
        XCTAssertEqual(result.count, 3)
    }
    
    // MARK: - Multi-field Search Tests
    
    func testExecute_DescriptionSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine A", description: "Pain reliever"),
            TestDataFactory.createTestMedicine(id: "2", name: "Medicine B", description: "Antibiotic"),
            TestDataFactory.createTestMedicine(id: "3", name: "Medicine C", description: "Pain management")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "pain")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.description == "Pain reliever" })
        XCTAssertTrue(result.contains { $0.description == "Pain management" })
    }
    
    func testExecute_DosageSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", dosage: "500mg"),
            TestDataFactory.createTestMedicine(id: "2", dosage: "250mg"),
            TestDataFactory.createTestMedicine(id: "3", dosage: "500mg tablet")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "500mg")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_FormSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", form: "Tablet"),
            TestDataFactory.createTestMedicine(id: "2", form: "Capsule"),
            TestDataFactory.createTestMedicine(id: "3", form: "Liquid tablet")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "tablet")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_ReferenceSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", reference: "REF-001"),
            TestDataFactory.createTestMedicine(id: "2", reference: "REF-002"),
            TestDataFactory.createTestMedicine(id: "3", reference: "SPECIAL-001")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "REF")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecute_UnitSearch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", unit: "tablet"),
            TestDataFactory.createTestMedicine(id: "2", unit: "ml"),
            TestDataFactory.createTestMedicine(id: "3", unit: "tablet strip")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "tablet")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Partial Match Tests
    
    func testExecute_PartialNameMatch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Acetaminophen"),
            TestDataFactory.createTestMedicine(id: "2", name: "Acetic acid"),
            TestDataFactory.createTestMedicine(id: "3", name: "Ibuprofen")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "acet")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Acetaminophen" })
        XCTAssertTrue(result.contains { $0.name == "Acetic acid" })
    }
    
    func testExecute_MiddleOfWordMatch() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Diclofenac"),
            TestDataFactory.createTestMedicine(id: "2", name: "Clotrimazole"),
            TestDataFactory.createTestMedicine(id: "3", name: "Paracetamol")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "clo")
        
        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains { $0.name == "Diclofenac" })
        XCTAssertTrue(result.contains { $0.name == "Clotrimazole" })
    }
    
    // MARK: - No Results Tests
    
    func testExecute_NoMatches_ReturnsEmptyArray() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Aspirin"),
            TestDataFactory.createTestMedicine(id: "2", name: "Ibuprofen")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "Nonexistent")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecute_EmptyRepository_ReturnsEmptyArray() async throws {
        // Given
        mockMedicineRepository.medicines = []
        
        // When
        let result = try await sut.execute(query: "Any query")
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Special Characters Tests
    
    func testExecute_SpecialCharactersInQuery() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine-A"),
            TestDataFactory.createTestMedicine(id: "2", name: "Medicine B+"),
            TestDataFactory.createTestMedicine(id: "3", name: "Medicine C")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "Medicine-A")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Medicine-A")
    }
    
    func testExecute_NumbersInQuery() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine 100"),
            TestDataFactory.createTestMedicine(id: "2", name: "Medicine 200"),
            TestDataFactory.createTestMedicine(id: "3", dosage: "100mg")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "100")
        
        // Then
        XCTAssertEqual(result.count, 2)
    }
    
    // MARK: - Repository Error Tests
    
    func testExecute_RepositoryError_ThrowsError() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
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
        mockMedicineRepository.medicines = medicines
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await sut.execute(query: "Medicine")
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertGreaterThan(result.count, 0)
        XCTAssertLessThan(timeElapsed, 1.0) // Should complete within 1 second
    }
    
    func testExecute_VeryLongQuery() async throws {
        // Given
        let medicines = [TestDataFactory.createTestMedicine(name: "Simple Medicine")]
        mockMedicineRepository.medicines = medicines
        let longQuery = String(repeating: "a", count: 1000)
        
        // When
        let result = try await sut.execute(query: longQuery)
        
        // Then
        XCTAssertTrue(result.isEmpty)
    }
    
    // MARK: - Multi-word Search Tests
    
    func testExecute_MultipleWords() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Aspirin Extra Strength"),
            TestDataFactory.createTestMedicine(id: "2", name: "Extra Virgin Oil"),
            TestDataFactory.createTestMedicine(id: "3", name: "Strength Building Supplement")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "Extra Strength")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Aspirin Extra Strength")
    }
    
    // MARK: - Edge Cases Tests
    
    func testExecute_UnicodeCharacters() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Médecine française"),
            TestDataFactory.createTestMedicine(id: "2", name: "Medicine english"),
            TestDataFactory.createTestMedicine(id: "3", name: "薬 Japanese")
        ]
        mockMedicineRepository.medicines = medicines
        
        // When
        let result = try await sut.execute(query: "français")
        
        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Médecine française")
    }
    
    func testExecute_EmojisInData() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine 💊"),
            TestDataFactory.createTestMedicine(id: "2", name: "Heart Medicine ❤️"),
            TestDataFactory.createTestMedicine(id: "3", name: "Regular Medicine")
        ]
        mockMedicineRepository.medicines = medicines
        
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
        mockMedicineRepository.medicines = medicines
        
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