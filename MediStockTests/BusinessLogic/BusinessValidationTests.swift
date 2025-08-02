import XCTest
@testable import MediStock

@MainActor
final class BusinessValidationTests: XCTestCase {
    
    private var medicineRepo: MedicineRepository!
    private var aisleRepo: AisleRepository!
    private var historyRepo: HistoryRepository!
    private var mockDataService: MockValidationDataServiceAdapter!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockValidationDataServiceAdapter()
        medicineRepo = MedicineRepository(dataService: mockDataService)
        aisleRepo = AisleRepository(dataService: mockDataService)
        historyRepo = HistoryRepository(dataService: mockDataService)
    }
    
    override func tearDown() {
        medicineRepo = nil
        aisleRepo = nil
        historyRepo = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: Medicine Stock Coherence
    
    func testMedicineStockCoherence() async throws {
        // Test 1: Current quantity should not exceed max quantity
        let medicine = Medicine(
            id: "med-1",
            name: "Test Medicine",
            description: nil,
            dosage: "500mg",
            form: "comprimé",
            reference: "REF-1",
            unit: "comprimés",
            currentQuantity: 100,
            maxQuantity: 100,
            warningThreshold: 30,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockDataService.mockMedicines = [medicine]
        mockDataService.enableStockValidation = true
        
        // Try to update stock beyond max
        do {
            _ = try await medicineRepo.updateMedicineStock(id: "med-1", newStock: 150)
            XCTFail("Expected validation error for exceeding max quantity")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test 2: Warning threshold should be greater than critical threshold
        mockDataService.validateThresholds = true
        let invalidMedicine = Medicine(
            id: "med-2",
            name: "Invalid Thresholds",
            description: nil,
            dosage: "100mg",
            form: "comprimé",
            reference: "REF-2",
            unit: "comprimés",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 10,  // Lower than critical!
            criticalThreshold: 20,
            expiryDate: nil,
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await medicineRepo.saveMedicine(invalidMedicine)
            XCTFail("Expected validation error for invalid thresholds")
        } catch ValidationError.invalidThresholds(let critical, let warning) {
            XCTAssertEqual(critical, 20)
            XCTAssertEqual(warning, 10)
        }
        
        // Test 3: Stock status coherence
        let medicines = [
            createMedicine(id: "critical", currentQuantity: 5, criticalThreshold: 10, warningThreshold: 20),
            createMedicine(id: "warning", currentQuantity: 15, criticalThreshold: 10, warningThreshold: 20),
            createMedicine(id: "normal", currentQuantity: 50, criticalThreshold: 10, warningThreshold: 20)
        ]
        
        XCTAssertEqual(medicines[0].stockStatus, .critical)
        XCTAssertEqual(medicines[1].stockStatus, .warning)
        XCTAssertEqual(medicines[2].stockStatus, .normal)
        
        // Test 4: Stock adjustment validation
        mockDataService.mockMedicines = [medicine]
        let updatedMedicine = try await medicineRepo.updateMedicineStock(id: "med-1", newStock: 80)
        XCTAssertEqual(updatedMedicine.currentQuantity, 80)
        
        // Verify history entry was created
        XCTAssertEqual(mockDataService.historyEntries.count, 1)
        XCTAssertTrue(mockDataService.historyEntries.first?.action.contains("Stock ajusté") ?? false)
    }
    
    // MARK: - Test: Aisle Medicine Count Limits
    
    func testAisleMedicineCountLimits() async throws {
        // Given: Aisle with limit of medicines
        let aisle = Aisle(
            id: "aisle-limit",
            name: "Limited Aisle",
            description: "Test aisle with medicine limit",
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        mockDataService.mockAisles = [aisle]
        mockDataService.maxMedicinesPerAisle = 5
        
        // Add medicines up to the limit
        for i in 0..<5 {
            let medicine = createMedicine(
                id: "med-\(i)",
                currentQuantity: 100,
                aisleId: "aisle-limit"
            )
            mockDataService.mockMedicines.append(medicine)
        }
        
        // Try to add one more medicine
        let extraMedicine = createMedicine(
            id: "med-extra",
            currentQuantity: 100,
            aisleId: "aisle-limit"
        )
        
        mockDataService.enforceAisleLimits = true
        do {
            _ = try await medicineRepo.saveMedicine(extraMedicine)
            XCTFail("Expected error for exceeding aisle medicine limit")
        } catch {
            XCTAssertNotNil(error)
        }
        
        // Test moving medicine between aisles
        let medicineToMove = mockDataService.mockMedicines[0]
        let movedMedicine = Medicine(
            id: medicineToMove.id,
            name: medicineToMove.name,
            description: medicineToMove.description,
            dosage: medicineToMove.dosage,
            form: medicineToMove.form,
            reference: medicineToMove.reference,
            unit: medicineToMove.unit,
            currentQuantity: medicineToMove.currentQuantity,
            maxQuantity: medicineToMove.maxQuantity,
            warningThreshold: medicineToMove.warningThreshold,
            criticalThreshold: medicineToMove.criticalThreshold,
            expiryDate: medicineToMove.expiryDate,
            aisleId: "aisle-new", // Changed aisle
            createdAt: medicineToMove.createdAt,
            updatedAt: Date()
        )
        _ = try await medicineRepo.saveMedicine(movedMedicine)
        
        // Now we should be able to add a new medicine to the original aisle
        let newMedicine = createMedicine(
            id: "med-new",
            currentQuantity: 100,
            aisleId: "aisle-limit"
        )
        _ = try await medicineRepo.saveMedicine(newMedicine)
        
        let medicinesInAisle = mockDataService.mockMedicines.filter { $0.aisleId == "aisle-limit" }
        XCTAssertEqual(medicinesInAisle.count, 5)
    }
    
    // MARK: - Test: Expiry Date Business Rules
    
    func testExpiryDateBusinessRules() async throws {
        let today = Date()
        let thirtyDaysFromNow = today.addingTimeInterval(30 * 24 * 60 * 60)
        let sixtyDaysFromNow = today.addingTimeInterval(60 * 24 * 60 * 60)
        let yesterday = today.addingTimeInterval(-24 * 60 * 60)
        
        // Test 1: Medicine expiring soon (within 30 days)
        let expiringSoon = createMedicine(
            id: "exp-soon",
            currentQuantity: 100,
            expiryDate: thirtyDaysFromNow
        )
        XCTAssertTrue(expiringSoon.isExpiringSoon)
        XCTAssertFalse(expiringSoon.isExpired)
        
        // Test 2: Medicine not expiring soon
        let notExpiringSoon = createMedicine(
            id: "exp-later",
            currentQuantity: 100,
            expiryDate: sixtyDaysFromNow
        )
        XCTAssertFalse(notExpiringSoon.isExpiringSoon)
        XCTAssertFalse(notExpiringSoon.isExpired)
        
        // Test 3: Expired medicine
        let expired = createMedicine(
            id: "exp-past",
            currentQuantity: 100,
            expiryDate: yesterday
        )
        XCTAssertTrue(expired.isExpired)
        XCTAssertTrue(expired.isExpiringSoon)
        
        // Test 4: Cannot save expired medicine
        mockDataService.preventExpiredMedicines = true
        do {
            _ = try await medicineRepo.saveMedicine(expired)
            XCTFail("Expected error for expired medicine")
        } catch ValidationError.expiredDate(let date) {
            XCTAssertEqual(date.timeIntervalSince1970, yesterday.timeIntervalSince1970, accuracy: 1.0)
        }
        
        // Test 5: Alert for expiring medicines
        let medicines = [
            expiringSoon,
            notExpiringSoon,
            createMedicine(id: "no-exp", currentQuantity: 100, expiryDate: nil)
        ]
        
        let expiringMedicines = medicines.filter { $0.isExpiringSoon }
        XCTAssertEqual(expiringMedicines.count, 1)
        XCTAssertEqual(expiringMedicines.first?.id, "exp-soon")
    }
    
    // MARK: - Test: Cascade Delete Validation
    
    func testCascadeDeleteValidation() async throws {
        // Setup: Aisle with medicines
        let aisle = Aisle(
            id: "aisle-cascade",
            name: "Test Aisle",
            description: "Aisle for cascade delete test",
            colorHex: "#0080FF",
            icon: "pills"
        )
        
        let medicines = (0..<3).map { index in
            createMedicine(
                id: "cascade-med-\(index)",
                currentQuantity: 100,
                aisleId: "aisle-cascade"
            )
        }
        
        mockDataService.mockAisles = [aisle]
        mockDataService.mockMedicines = medicines
        mockDataService.preventAisleDeletionWithMedicines = true
        
        // Test 1: Cannot delete aisle with medicines
        do {
            try await aisleRepo.deleteAisle(id: "aisle-cascade")
            XCTFail("Expected error when deleting aisle with medicines")
        } catch ValidationError.aisleContainsMedicines(let count) {
            XCTAssertEqual(count, 3)
        }
        
        // Test 2: Can delete aisle after removing all medicines
        for medicine in medicines {
            try await medicineRepo.deleteMedicine(id: medicine.id)
        }
        
        try await aisleRepo.deleteAisle(id: "aisle-cascade")
        XCTAssertTrue(mockDataService.mockAisles.isEmpty)
        
        // Test 3: Cascade delete history tracking
        let historyCount = mockDataService.historyEntries.filter { 
            $0.action.contains("supprimé") || $0.action.contains("Suppression")
        }.count
        XCTAssertEqual(historyCount, 4) // 3 medicines + 1 aisle
        
        // Test 4: Orphaned medicines validation
        let orphanedMedicine = createMedicine(
            id: "orphan-med",
            currentQuantity: 100,
            aisleId: "non-existent-aisle"
        )
        
        mockDataService.validateAisleReferences = true
        do {
            _ = try await medicineRepo.saveMedicine(orphanedMedicine)
            XCTFail("Expected error for orphaned medicine")
        } catch ValidationError.invalidAisleReference(let aisleId) {
            XCTAssertEqual(aisleId, "non-existent-aisle")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMedicine(
        id: String,
        currentQuantity: Int,
        criticalThreshold: Int = 10,
        warningThreshold: Int = 20,
        expiryDate: Date? = nil,
        aisleId: String = "aisle-1"
    ) -> Medicine {
        return Medicine(
            id: id,
            name: "Medicine \(id)",
            description: nil,
            dosage: "500mg",
            form: "comprimé",
            reference: "REF-\(id)",
            unit: "comprimés",
            currentQuantity: currentQuantity,
            maxQuantity: 200,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: expiryDate,
            aisleId: aisleId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Validation Data Service Adapter

class MockValidationDataServiceAdapter: DataServiceAdapter {
    var mockMedicines: [Medicine] = []
    var mockAisles: [Aisle] = []
    var historyEntries: [HistoryEntry] = []
    
    // Validation flags
    var enableStockValidation = false
    var validateThresholds = false
    var enforceAisleLimits = false
    var maxMedicinesPerAisle = 5
    var preventExpiredMedicines = false
    var preventAisleDeletionWithMedicines = false
    var validateAisleReferences = false
    
    override func getMedicines() async throws -> [Medicine] {
        return mockMedicines
    }
    
    override func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        // Validate thresholds
        if validateThresholds && medicine.warningThreshold <= medicine.criticalThreshold {
            throw ValidationError.invalidThresholds(
                critical: medicine.criticalThreshold,
                warning: medicine.warningThreshold
            )
        }
        
        // Validate expiry date
        if preventExpiredMedicines, let expiryDate = medicine.expiryDate {
            if expiryDate <= Date() {
                throw ValidationError.expiredDate(date: expiryDate)
            }
        }
        
        // Validate aisle reference
        if validateAisleReferences {
            let aisleExists = mockAisles.contains { $0.id == medicine.aisleId }
            if !aisleExists {
                throw ValidationError.invalidAisleReference(aisleId: medicine.aisleId)
            }
        }
        
        // Validate aisle medicine limit
        if enforceAisleLimits {
            let medicinesInAisle = mockMedicines.filter { 
                $0.aisleId == medicine.aisleId && $0.id != medicine.id 
            }
            if medicinesInAisle.count >= maxMedicinesPerAisle {
                throw ValidationError.tooManyAisles(max: maxMedicinesPerAisle)
            }
        }
        
        // Save or update
        if let index = mockMedicines.firstIndex(where: { $0.id == medicine.id }) {
            mockMedicines[index] = medicine
        } else {
            mockMedicines.append(medicine)
        }
        
        return medicine
    }
    
    override func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        guard var medicine = mockMedicines.first(where: { $0.id == id }) else {
            throw ValidationError.invalidId
        }
        
        // Validate stock limits
        if enableStockValidation {
            if newStock < 0 {
                throw ValidationError.negativeQuantity(field: "stock")
            }
            if newStock > medicine.maxQuantity {
                throw ValidationError.invalidMaxQuantity
            }
        }
        
        let oldStock = medicine.currentQuantity
        medicine = Medicine(
            id: medicine.id,
            name: medicine.name,
            description: medicine.description,
            dosage: medicine.dosage,
            form: medicine.form,
            reference: medicine.reference,
            unit: medicine.unit,
            currentQuantity: newStock, // Updated stock
            maxQuantity: medicine.maxQuantity,
            warningThreshold: medicine.warningThreshold,
            criticalThreshold: medicine.criticalThreshold,
            expiryDate: medicine.expiryDate,
            aisleId: medicine.aisleId,
            createdAt: medicine.createdAt,
            updatedAt: Date()
        )
        
        // Update in array
        if let index = mockMedicines.firstIndex(where: { $0.id == id }) {
            mockMedicines[index] = medicine
        }
        
        // Create history entry
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: id,
            userId: "test-user",
            action: "Stock ajusté de \(oldStock) à \(newStock)",
            details: "Ajustement de stock",
            timestamp: Date()
        )
        historyEntries.append(historyEntry)
        
        return medicine
    }
    
    override func deleteMedicine(id: String) async throws {
        mockMedicines.removeAll { $0.id == id }
        
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: id,
            userId: "test-user",
            action: "Médicament supprimé",
            details: "Suppression du médicament",
            timestamp: Date()
        )
        historyEntries.append(historyEntry)
    }
    
    override func deleteAisle(id: String) async throws {
        if preventAisleDeletionWithMedicines {
            let medicinesInAisle = mockMedicines.filter { $0.aisleId == id }
            if !medicinesInAisle.isEmpty {
                throw ValidationError.aisleContainsMedicines(count: medicinesInAisle.count)
            }
        }
        
        mockAisles.removeAll { $0.id == id }
        
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: "",
            userId: "test-user",
            action: "Rayon supprimé",
            details: "Suppression du rayon \(id)",
            timestamp: Date()
        )
        historyEntries.append(historyEntry)
    }
    
    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        historyEntries.append(entry)
    }
}