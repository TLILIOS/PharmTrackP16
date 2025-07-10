import XCTest
@testable import MediStock

@MainActor
final class RealAddMedicineUseCaseTests: XCTestCase {
    
    var sut: RealAddMedicineUseCase!
    var mockMedicineRepository: MockMedicineRepository!
    var mockHistoryRepository: MockHistoryRepository!
    
    override func setUp() {
        super.setUp()
        mockMedicineRepository = MockMedicineRepository()
        mockHistoryRepository = MockHistoryRepository()
        
        sut = RealAddMedicineUseCase(
            medicineRepository: mockMedicineRepository,
            historyRepository: mockHistoryRepository
        )
    }
    
    override func tearDown() {
        sut = nil
        mockMedicineRepository = nil
        mockHistoryRepository = nil
        super.tearDown()
    }
    
    // MARK: - Success Tests
    
    func testExecute_Success() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            name: "Test Medicine",
            description: "Test Description",
            currentQuantity: 50
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        XCTAssertEqual(mockMedicineRepository.addedMedicines.count, 1)
        XCTAssertEqual(mockMedicineRepository.addedMedicines.first?.name, medicine.name)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertEqual(mockHistoryRepository.addedEntries.first?.action, "Medicine Added")
    }
    
    func testExecute_MedicineWithAllFields_Success() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            id: "med-123",
            name: "Complete Medicine",
            description: "Complete Description",
            dosage: "500mg",
            form: "Tablet",
            reference: "REF-001",
            unit: "tablet",
            currentQuantity: 100,
            maxQuantity: 200,
            warningThreshold: 50,
            criticalThreshold: 20,
            aisleId: "aisle-1"
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let addedMedicine = mockMedicineRepository.addedMedicines.first!
        XCTAssertEqual(addedMedicine.id, medicine.id)
        XCTAssertEqual(addedMedicine.name, medicine.name)
        XCTAssertEqual(addedMedicine.dosage, medicine.dosage)
        XCTAssertEqual(addedMedicine.form, medicine.form)
        XCTAssertEqual(addedMedicine.reference, medicine.reference)
        XCTAssertEqual(addedMedicine.unit, medicine.unit)
        XCTAssertEqual(addedMedicine.currentQuantity, medicine.currentQuantity)
        XCTAssertEqual(addedMedicine.maxQuantity, medicine.maxQuantity)
        XCTAssertEqual(addedMedicine.warningThreshold, medicine.warningThreshold)
        XCTAssertEqual(addedMedicine.criticalThreshold, medicine.criticalThreshold)
        XCTAssertEqual(addedMedicine.aisleId, medicine.aisleId)
        
        let historyEntry = mockHistoryRepository.addedEntries.first!
        XCTAssertEqual(historyEntry.medicineId, medicine.id)
        XCTAssertEqual(historyEntry.action, "Medicine Added")
        XCTAssertTrue(historyEntry.details.contains(medicine.name))
    }
    
    // MARK: - Repository Failure Tests
    
    func testExecute_MedicineRepositoryFailure() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add medicine"]
        )
        
        // When & Then
        do {
            try await sut.execute(medicine: medicine)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Failed to add medicine")
            XCTAssertTrue(mockMedicineRepository.addedMedicines.isEmpty)
            XCTAssertTrue(mockHistoryRepository.addedEntries.isEmpty)
        }
    }
    
    func testExecute_HistoryRepositoryFailure() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        mockHistoryRepository.shouldThrowError = true
        mockHistoryRepository.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add history"]
        )
        
        // When & Then
        do {
            try await sut.execute(medicine: medicine)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Failed to add history")
            XCTAssertEqual(mockMedicineRepository.addedMedicines.count, 1)
            XCTAssertTrue(mockHistoryRepository.addedEntries.isEmpty)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testExecute_MedicineWithEmptyFields() async throws {
        // Given
        let medicine = Medicine(
            id: "empty-medicine",
            name: "",
            description: "",
            dosage: "",
            form: "",
            reference: "",
            unit: "",
            currentQuantity: 0,
            maxQuantity: 0,
            warningThreshold: 0,
            criticalThreshold: 0,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        XCTAssertEqual(mockMedicineRepository.addedMedicines.count, 1)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
    }
    
    func testExecute_MedicineWithNegativeQuantities() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            currentQuantity: -10,
            maxQuantity: -5,
            warningThreshold: -20,
            criticalThreshold: -30
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let addedMedicine = mockMedicineRepository.addedMedicines.first!
        XCTAssertEqual(addedMedicine.currentQuantity, -10)
        XCTAssertEqual(addedMedicine.maxQuantity, -5)
        XCTAssertEqual(addedMedicine.warningThreshold, -20)
        XCTAssertEqual(addedMedicine.criticalThreshold, -30)
    }
    
    func testExecute_MedicineWithVeryLargeQuantities() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            currentQuantity: 999999,
            maxQuantity: 1000000,
            warningThreshold: 100000,
            criticalThreshold: 50000
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let addedMedicine = mockMedicineRepository.addedMedicines.first!
        XCTAssertEqual(addedMedicine.currentQuantity, 999999)
        XCTAssertEqual(addedMedicine.maxQuantity, 1000000)
    }
    
    func testExecute_MedicineWithLongStrings() async throws {
        // Given
        let longString = String(repeating: "a", count: 1000)
        let medicine = TestDataFactory.createTestMedicine(
            name: longString,
            description: longString,
            dosage: longString
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let addedMedicine = mockMedicineRepository.addedMedicines.first!
        XCTAssertEqual(addedMedicine.name.count, 1000)
        XCTAssertEqual(addedMedicine.description.count, 1000)
        XCTAssertEqual(addedMedicine.dosage.count, 1000)
    }
    
    // MARK: - History Entry Tests
    
    func testExecute_HistoryEntryCreation() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            id: "med-123",
            name: "Test Medicine",
            currentQuantity: 75
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let historyEntry = mockHistoryRepository.addedEntries.first!
        XCTAssertEqual(historyEntry.medicineId, "med-123")
        XCTAssertEqual(historyEntry.action, "Medicine Added")
        XCTAssertTrue(historyEntry.details.contains("Test Medicine"))
        XCTAssertTrue(historyEntry.details.contains("75"))
        XCTAssertFalse(historyEntry.userId.isEmpty)
        XCTAssertNotNil(historyEntry.timestamp)
    }
    
    func testExecute_HistoryEntryWithExpiryDate() async throws {
        // Given
        let expiryDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        let medicine = TestDataFactory.createTestMedicine(
            name: "Expiring Medicine",
            expiryDate: expiryDate
        )
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let historyEntry = mockHistoryRepository.addedEntries.first!
        XCTAssertTrue(historyEntry.details.contains("Expiring Medicine"))
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testExecute_ConcurrentOperations() async throws {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine 1"),
            TestDataFactory.createTestMedicine(id: "med-2", name: "Medicine 2"),
            TestDataFactory.createTestMedicine(id: "med-3", name: "Medicine 3")
        ]
        
        // When
        try await withThrowingTaskGroup(of: Void.self) { group in
            for medicine in medicines {
                group.addTask {
                    try await self.sut.execute(medicine: medicine)
                }
            }
            
            try await group.waitForAll()
        }
        
        // Then
        XCTAssertEqual(mockMedicineRepository.addedMedicines.count, 3)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 3)
        
        let addedIds = Set(mockMedicineRepository.addedMedicines.map { $0.id })
        XCTAssertEqual(addedIds, Set(["med-1", "med-2", "med-3"]))
    }
    
    // MARK: - Memory Management Tests
    
    func testExecute_MemoryManagement() async throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        weak var weakMedicine: Medicine? = medicine
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        XCTAssertNotNil(weakMedicine) // Should still exist due to repository storage
    }
    
    // MARK: - Timestamp Tests
    
    func testExecute_TimestampHandling() async throws {
        // Given
        let startTime = Date()
        let medicine = TestDataFactory.createTestMedicine()
        
        // When
        try await sut.execute(medicine: medicine)
        
        // Then
        let endTime = Date()
        let historyEntry = mockHistoryRepository.addedEntries.first!
        
        XCTAssertGreaterThanOrEqual(historyEntry.timestamp, startTime)
        XCTAssertLessThanOrEqual(historyEntry.timestamp, endTime)
    }
}