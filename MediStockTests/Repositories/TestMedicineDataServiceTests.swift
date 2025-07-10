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
            TestDataFactory.createTestAisle(id: "1", name: "Analgésiques"),
            TestDataFactory.createTestAisle(id: "2", name: "Antibiotiques"),
            TestDataFactory.createTestAisle(id: "3", name: "Other")
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
            XCTAssertFalse(medicine.description.isEmpty)
            XCTAssertFalse(medicine.dosage.isEmpty)
            XCTAssertFalse(medicine.form.isEmpty)
            XCTAssertFalse(medicine.reference.isEmpty)
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
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques")]
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
            TestDataFactory.createTestAisle(id: "1", name: "analgésiques"),
            TestDataFactory.createTestAisle(id: "2", name: "ANTIBIOTIQUES"),
            TestDataFactory.createTestAisle(id: "3", name: "Vitamines"),
            TestDataFactory.createTestAisle(id: "4", name: "UnknownType")
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
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        // Verify all references are unique
        let references = medicines.map { $0.reference }
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
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        // Verify stock quantities are within reasonable ranges
        for medicine in medicines {
            XCTAssertGreaterThanOrEqual(medicine.currentQuantity, 0)
            XCTAssertLessThanOrEqual(medicine.currentQuantity, medicine.maxQuantity)
            XCTAssertLessThan(medicine.criticalThreshold, medicine.warningThreshold)
            XCTAssertLessThan(medicine.warningThreshold, medicine.maxQuantity)
        }
    }
    
    func testGenerateTestMedicines_ExpiryDateGeneration() async throws {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "1", name: "Analgésiques")]
        mockGetAislesUseCase.aisles = testAisles
        
        // When
        try await sut.generateTestMedicines()
        
        // Then
        let medicines = mockAddMedicineUseCase.addedMedicines
        XCTAssertFalse(medicines.isEmpty)
        
        let now = Date()
        let oneYearFromNow = Calendar.current.date(byAdding: .year, value: 1, to: now)!
        let fiveYearsFromNow = Calendar.current.date(byAdding: .year, value: 5, to: now)!
        
        // Verify expiry dates are in reasonable future ranges
        for medicine in medicines {
            if let expiryDate = medicine.expiryDate {
                XCTAssertGreaterThan(expiryDate, oneYearFromNow, "Expiry date should be at least 1 year from now")
                XCTAssertLessThan(expiryDate, fiveYearsFromNow, "Expiry date should be within 5 years from now")
            } else {
                XCTFail("Medicine should have expiry date")
            }
        }
    }
}