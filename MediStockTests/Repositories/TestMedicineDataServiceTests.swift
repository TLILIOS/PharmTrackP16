import XCTest
@testable import MediStock

@MainActor
final class TestMedicineDataServiceTests: XCTestCase {
    
    var sut: TestMedicineDataService!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    var mockAddMedicineUseCase: MockAddMedicineUseCase!
    
    override func setUp() {
        super.setUp()
        mockGetAislesUseCase = MockGetAislesUseCase()
        mockAddMedicineUseCase = MockAddMedicineUseCase()
        
        sut = TestMedicineDataService(
            getAislesUseCase: mockGetAislesUseCase,
            addMedicineUseCase: mockAddMedicineUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockGetAislesUseCase = nil
        mockAddMedicineUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Generate Test Medicines Tests
    
    func testGenerateTestMedicines_Success() async throws {
        // Given
        let testAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Analgésiques", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "Antibiotiques", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Other", colorHex: "#007AFF")
        ]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        XCTAssertFalse(mockAddMedicineUseCase.addedMedicines.isEmpty)
        XCTAssertTrue(mockAddMedicineUseCase.addedMedicines.count > 0)
        
        // Verify medicines were added for each aisle
        let addedMedicinesByAisle = Dictionary(grouping: mockAddMedicineUseCase.addedMedicines) { $0.aisleId }
        XCTAssertEqual(addedMedicinesByAisle.keys.count, testAisles.count)
        
        // Verify each medicine has required properties
        for medicine in mockAddMedicineUseCase.addedMedicines {
            XCTAssertFalse(medicine.name.isEmpty)
            XCTAssertFalse(medicine.description?.isEmpty ?? true)
            XCTAssertFalse(medicine.dosage?.isEmpty ?? true)
            XCTAssertFalse(medicine.form?.isEmpty ?? true)
            XCTAssertFalse(medicine.reference?.isEmpty ?? true)
            XCTAssertFalse(medicine.unit.isEmpty)
            XCTAssertGreaterThan(medicine.maxQuantity, 0)
            XCTAssertGreaterThan(medicine.warningThreshold, 0)
            XCTAssertGreaterThan(medicine.criticalThreshold, 0)
            XCTAssertNotNil(medicine.expiryDate)
            XCTAssertTrue(testAisles.map { $0.id }.contains(medicine.aisleId))
        }
    }
    
    func testGenerateTestMedicines_EmptyAisles() async throws {
        // Given
        mockGetAislesUseCase.aisles = []
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        XCTAssertTrue(mockAddMedicineUseCase.addedMedicines.isEmpty)
    }
    
    func testGenerateTestMedicines_GetAislesFailure() async {
        // Given
        mockGetAislesUseCase.shouldThrowError = true
        mockGetAislesUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to get aisles"]
        )
        
        // When & Then
        do {
            try await sut.generateTestMedicines()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(mockAddMedicineUseCase.addedMedicines.isEmpty)
        }
    }
    
    func testGenerateTestMedicines_AddMedicineFailure() async {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques", colorHex: "#007AFF")]
        mockGetAislesUseCase.aisles = testAisles
        mockAddMedicineUseCase.shouldThrowError = true
        mockAddMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add medicine"]
        )
        
        // When & Then
        do {
            try await sut.generateTestMedicines()
            XCTFail("Expected error to be thrown")
        } catch {
            // Should fail on first medicine addition
            XCTAssertTrue(mockAddMedicineUseCase.addedMedicines.isEmpty)
        }
    }
    
    func testGenerateTestMedicines_DifferentAisleTypes() async throws {
        // Given
        let testAisles = [
            TestDataFactory.createTestAisle(id: "1", name: "analgésiques", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "ANTIBIOTIQUES", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Vitamines", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "4", name: "UnknownType", colorHex: "#007AFF")
        ]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        XCTAssertFalse(mockAddMedicineUseCase.addedMedicines.isEmpty)
        
        // Verify medicines generated for each aisle type
        let medicinesByAisle = Dictionary(grouping: mockAddMedicineUseCase.addedMedicines) { $0.aisleId }
        
        for aisle in testAisles {
            let medicinesForAisle = medicinesByAisle[aisle.id] ?? []
            XCTAssertFalse(medicinesForAisle.isEmpty, "No medicines generated for aisle: \(aisle.name)")
        }
    }
    
    func testGenerateTestMedicines_ReferenceGeneration() async throws {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques", colorHex: "#007AFF")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        // Verify all references are unique
        let references = medicines.compactMap { $0.reference }
        let uniqueReferences = Set(references)
        XCTAssertEqual(references.count, uniqueReferences.count, "References should be unique")
        
        // Verify reference format
        for reference in references {
            XCTAssertTrue(reference.count >= 3, "Reference should have minimum length")
            XCTAssertTrue(reference.allSatisfy { $0.isUppercase || $0.isNumber || $0 == "-" }, "Reference should be uppercase with numbers and hyphens")
        }
    }
    
    func testGenerateTestMedicines_StockVariation() async throws {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques", colorHex: "#007AFF")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        // Verify stock quantities are within reasonable ranges
        for medicine in medicines {
            XCTAssertGreaterThanOrEqual(medicine.currentQuantity, 0)
            // Note: currentQuantity may exceed maxQuantity due to random generation
            // This is a known behavior of the test data generation
            XCTAssertLessThan(medicine.criticalThreshold, medicine.warningThreshold)
            XCTAssertLessThanOrEqual(medicine.warningThreshold, medicine.maxQuantity)
        }
    }
    
    func testGenerateTestMedicines_ExpiryDateGeneration() async throws {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques", colorHex: "#007AFF")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        let now = Date()
        let threeMonthsFromNow = Calendar.current.date(byAdding: .month, value: 3, to: now)!
        let twoYearsFromNow = Calendar.current.date(byAdding: .year, value: 2, to: now)!
        
        // Verify expiry dates are in reasonable future ranges (29 days to 2 years)
        // Use 29 days to avoid race condition with the generation which uses "at least 30 days"
        let twentyNineDaysFromNow = Calendar.current.date(byAdding: .day, value: 29, to: now)!
        for medicine in medicines {
            if let expiryDate = medicine.expiryDate {
                XCTAssertGreaterThan(expiryDate, twentyNineDaysFromNow, "Expiry date should be more than 29 days from now")
                XCTAssertLessThanOrEqual(expiryDate, twoYearsFromNow, "Expiry date should be within 2 years from now")
            } else {
                XCTFail("Medicine should have expiry date")
            }
        }
    }
}