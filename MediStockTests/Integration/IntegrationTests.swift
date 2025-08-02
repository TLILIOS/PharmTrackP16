import XCTest
@testable import MediStock

@MainActor
final class IntegrationTests: XCTestCase {
    
    private var dataService: MockIntegrationDataService!
    private var medicineRepo: MedicineRepository!
    private var aisleRepo: AisleRepository!
    private var historyRepo: HistoryRepository!
    
    override func setUp() {
        super.setUp()
        dataService = MockIntegrationDataService()
        medicineRepo = MedicineRepository(dataService: dataService)
        aisleRepo = AisleRepository(dataService: dataService)
        historyRepo = HistoryRepository(dataService: dataService)
        
        // Reset data
        dataService.reset()
    }
    
    override func tearDown() {
        medicineRepo = nil
        aisleRepo = nil
        historyRepo = nil
        dataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: Complete Inventory Workflow
    
    func testCompleteInventoryWorkflow() async throws {
        // Step 1: Create aisles
        let pharmacyAisle = Aisle(
            id: "aisle-pharmacy",
            name: "Pharmacie Générale",
            description: "Médicaments courants",
            colorHex: "#4CAF50",
            icon: "pills"
        )
        
        let specialtyAisle = Aisle(
            id: "aisle-specialty",
            name: "Spécialités",
            description: "Médicaments spécialisés",
            colorHex: "#2196F3",
            icon: "cross.case"
        )
        
        let savedPharmacy = try await aisleRepo.saveAisle(pharmacyAisle)
        let savedSpecialty = try await aisleRepo.saveAisle(specialtyAisle)
        
        XCTAssertEqual(dataService.aisles.count, 2)
        XCTAssertNotNil(savedPharmacy)
        XCTAssertNotNil(savedSpecialty)
        
        // Step 2: Add medicines to aisles
        let doliprane = Medicine(
            id: "med-doliprane",
            name: "Doliprane 500mg",
            description: "Paracétamol",
            dosage: "500mg",
            form: "comprimé",
            reference: "DOL500",
            unit: "comprimés",
            currentQuantity: 200,
            maxQuantity: 500,
            warningThreshold: 100,
            criticalThreshold: 50,
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            aisleId: pharmacyAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let insulin = Medicine(
            id: "med-insulin",
            name: "Insuline Rapide",
            description: "Insuline à action rapide",
            dosage: "100UI/ml",
            form: "injection",
            reference: "INS100",
            unit: "flacons",
            currentQuantity: 30,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(180 * 24 * 60 * 60),
            aisleId: specialtyAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let savedDoliprane = try await medicineRepo.saveMedicine(doliprane)
        let savedInsulin = try await medicineRepo.saveMedicine(insulin)
        
        XCTAssertEqual(dataService.medicines.count, 2)
        
        // Step 3: Perform stock adjustments
        let updatedDoliprane = try await medicineRepo.updateMedicineStock(
            id: savedDoliprane.id,
            newStock: 150
        )
        XCTAssertEqual(updatedDoliprane.currentQuantity, 150)
        
        // Step 4: Verify history tracking
        let history = try await historyRepo.fetchHistory()
        XCTAssertGreaterThanOrEqual(history.count, 3) // At least 3 entries (2 creates + 1 stock update)
        
        let stockAdjustments = history.filter { $0.action.contains("Stock ajusté") }
        XCTAssertEqual(stockAdjustments.count, 1)
        
        // Step 5: Search and filter medicines
        let allMedicines = try await medicineRepo.fetchMedicines()
        XCTAssertEqual(allMedicines.count, 2)
        
        // Current stock is 150, warning threshold is 100, so it should be normal status
        let warningMedicines = allMedicines.filter { $0.stockStatus == .warning }
        XCTAssertEqual(warningMedicines.count, 0) // No medicines in warning status
        
        // Check normal status medicines
        let normalMedicines = allMedicines.filter { $0.stockStatus == .normal }
        XCTAssertEqual(normalMedicines.count, 2) // Both medicines should be normal
        
        // Step 6: Delete medicine and verify cascade
        try await medicineRepo.deleteMedicine(id: savedInsulin.id)
        
        let remainingMedicines = try await medicineRepo.fetchMedicines()
        XCTAssertEqual(remainingMedicines.count, 1)
        
        let deletionHistory = try await historyRepo.fetchHistory()
        let deletions = deletionHistory.filter { $0.action.contains("supprimé") }
        XCTAssertGreaterThanOrEqual(deletions.count, 1)
    }
    
    // MARK: - Test: Stock Adjustment with History
    
    func testStockAdjustmentWithHistory() async throws {
        // Setup: Create aisle and medicine
        let aisle = Aisle(
            id: "test-aisle",
            name: "Test Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        _ = try await aisleRepo.saveAisle(aisle)
        
        let medicine = Medicine(
            id: "test-med",
            name: "Test Medicine",
            description: nil,
            dosage: "100mg",
            form: "tablet",
            reference: "TEST100",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: nil,
            aisleId: aisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        let savedMedicine = try await medicineRepo.saveMedicine(medicine)
        
        // Perform multiple stock adjustments
        let adjustments = [80, 60, 40, 25, 15, 5]
        var previousQuantity = savedMedicine.currentQuantity
        
        for newStock in adjustments {
            let updated = try await medicineRepo.updateMedicineStock(
                id: savedMedicine.id,
                newStock: newStock
            )
            
            // Verify stock was updated
            XCTAssertEqual(updated.currentQuantity, newStock)
            
            // Verify history entry was created
            let history = try await historyRepo.fetchHistoryForMedicine(savedMedicine.id)
            let latestEntry = history.first { entry in
                entry.action.contains("Stock ajusté de \(previousQuantity) à \(newStock)")
            }
            XCTAssertNotNil(latestEntry)
            
            previousQuantity = newStock
        }
        
        // Verify stock status changes
        let finalMedicine = dataService.medicines.first { $0.id == savedMedicine.id }
        XCTAssertEqual(finalMedicine?.stockStatus, .critical)
        
        // Verify complete history
        let completeHistory = try await historyRepo.fetchHistoryForMedicine(savedMedicine.id)
        let stockAdjustments = completeHistory.filter { $0.action.contains("Stock ajusté") }
        XCTAssertEqual(stockAdjustments.count, adjustments.count)
    }
    
    // MARK: - Test: Multi-User Data Isolation
    
    func testMultiUserDataIsolation() async throws {
        // Simulate different users
        let user1 = "user-1"
        let user2 = "user-2"
        
        // User 1 creates an aisle
        dataService.currentUserId = user1
        let aisle1 = Aisle(
            id: "aisle-user1",
            name: "User 1 Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        _ = try await aisleRepo.saveAisle(aisle1)
        
        // User 2 creates an aisle
        dataService.currentUserId = user2
        let aisle2 = Aisle(
            id: "aisle-user2",
            name: "User 2 Aisle",
            description: nil,
            colorHex: "#00FF00",
            icon: "cross.case"
        )
        _ = try await aisleRepo.saveAisle(aisle2)
        
        // User 1 adds medicines
        dataService.currentUserId = user1
        let medicine1 = createTestMedicine(id: "med-user1", aisleId: aisle1.id)
        _ = try await medicineRepo.saveMedicine(medicine1)
        
        // User 2 adds medicines
        dataService.currentUserId = user2
        let medicine2 = createTestMedicine(id: "med-user2", aisleId: aisle2.id)
        _ = try await medicineRepo.saveMedicine(medicine2)
        
        // Verify history isolation
        let allHistory = try await historyRepo.fetchHistory()
        let user1History = allHistory.filter { $0.userId == user1 }
        let user2History = allHistory.filter { $0.userId == user2 }
        
        XCTAssertGreaterThan(user1History.count, 0)
        XCTAssertGreaterThan(user2History.count, 0)
        
        // Verify each user's actions are properly attributed
        XCTAssertTrue(user1History.allSatisfy { $0.userId == user1 })
        XCTAssertTrue(user2History.allSatisfy { $0.userId == user2 })
        
        // Test cross-user medicine access (should be allowed in read)
        dataService.currentUserId = user1
        let allMedicines = try await medicineRepo.fetchMedicines()
        XCTAssertEqual(allMedicines.count, 2)
        
        // Test medicine update by different user
        dataService.currentUserId = user2
        _ = try await medicineRepo.updateMedicineStock(id: medicine1.id, newStock: 50)
        
        // Verify history shows correct user for update
        let updateHistory = try await historyRepo.fetchHistoryForMedicine(medicine1.id)
        let updateEntry = updateHistory.first { $0.action.contains("Stock ajusté") }
        XCTAssertEqual(updateEntry?.userId, user2)
    }
    
    // MARK: - Test: Offline Data Synchronization
    
    func testOfflineDataSynchronization() async throws {
        // Step 1: Create data while "online"
        dataService.isOnline = true
        
        let aisle = Aisle(
            id: "sync-aisle",
            name: "Sync Test Aisle",
            description: nil,
            colorHex: "#0000FF",
            icon: "pills"
        )
        _ = try await aisleRepo.saveAisle(aisle)
        
        let medicine = createTestMedicine(id: "sync-med", aisleId: aisle.id)
        _ = try await medicineRepo.saveMedicine(medicine)
        
        // Step 2: Go offline and queue operations
        dataService.isOnline = false
        
        // Queue stock update
        _ = try await medicineRepo.updateMedicineStock(id: medicine.id, newStock: 75)
        
        // Queue new medicine
        let offlineMedicine = createTestMedicine(id: "offline-med", aisleId: aisle.id)
        _ = try await medicineRepo.saveMedicine(offlineMedicine)
        
        // Verify operations are queued
        XCTAssertEqual(dataService.pendingOperations.count, 2)
        
        // Step 3: Go back online and sync
        dataService.isOnline = true
        try await dataService.synchronizePendingOperations()
        
        // Verify all operations were applied
        XCTAssertEqual(dataService.pendingOperations.count, 0)
        
        let medicines = try await medicineRepo.fetchMedicines()
        XCTAssertEqual(medicines.count, 2)
        
        let updatedMedicine = medicines.first { $0.id == medicine.id }
        XCTAssertEqual(updatedMedicine?.currentQuantity, 75)
        
        // Verify history includes all operations
        let history = try await historyRepo.fetchHistory()
        XCTAssertGreaterThanOrEqual(history.count, 4) // Initial creates + offline operations
        
        // Step 4: Test conflict resolution
        dataService.isOnline = false
        
        // Simulate conflicting update
        _ = try await medicineRepo.updateMedicineStock(id: medicine.id, newStock: 60)
        
        // Another conflicting update
        _ = try await medicineRepo.updateMedicineStock(id: medicine.id, newStock: 65)
        
        dataService.isOnline = true
        try await dataService.synchronizePendingOperations()
        
        // Verify last update wins
        let finalMedicine = try await medicineRepo.fetchMedicines().first { $0.id == medicine.id }
        XCTAssertEqual(finalMedicine?.currentQuantity, 65)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMedicine(
        id: String,
        aisleId: String,
        currentQuantity: Int = 100
    ) -> Medicine {
        return Medicine(
            id: id,
            name: "Test Medicine \(id)",
            description: nil,
            dosage: "100mg",
            form: "tablet",
            reference: "REF-\(id)",
            unit: "tablets",
            currentQuantity: currentQuantity,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: nil,
            aisleId: aisleId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Integration Data Service

class MockIntegrationDataService: DataServiceAdapter {
    var medicines: [Medicine] = []
    var aisles: [Aisle] = []
    var history: [HistoryEntry] = []
    
    var currentUserId = "default-user"
    var isOnline = true
    var pendingOperations: [(operation: String, data: Any)] = []
    
    func reset() {
        medicines = []
        aisles = []
        history = []
        pendingOperations = []
        currentUserId = "default-user"
        isOnline = true
    }
    
    // MARK: - Medicine Operations
    
    override func getMedicines() async throws -> [Medicine] {
        return medicines
    }
    
    override func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        if !isOnline {
            pendingOperations.append((operation: "saveMedicine", data: medicine))
            
            // Update local cache
            if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
                medicines[index] = medicine
            } else {
                medicines.append(medicine)
            }
            
            return medicine
        }
        
        // Online operation
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            addHistoryEntry(action: "Médicament modifié", medicineId: medicine.id)
        } else {
            medicines.append(medicine)
            addHistoryEntry(action: "Médicament créé", medicineId: medicine.id)
        }
        
        return medicine
    }
    
    override func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        guard var medicine = medicines.first(where: { $0.id == id }) else {
            throw ValidationError.invalidId
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
            currentQuantity: newStock,
            maxQuantity: medicine.maxQuantity,
            warningThreshold: medicine.warningThreshold,
            criticalThreshold: medicine.criticalThreshold,
            expiryDate: medicine.expiryDate,
            aisleId: medicine.aisleId,
            createdAt: medicine.createdAt,
            updatedAt: Date()
        )
        
        if !isOnline {
            pendingOperations.append((operation: "updateStock", data: ["id": id, "newStock": newStock]))
        }
        
        if let index = medicines.firstIndex(where: { $0.id == id }) {
            medicines[index] = medicine
        }
        
        addHistoryEntry(
            action: "Stock ajusté de \(oldStock) à \(newStock)",
            medicineId: id
        )
        
        return medicine
    }
    
    override func deleteMedicine(id: String) async throws {
        medicines.removeAll { $0.id == id }
        addHistoryEntry(action: "Médicament supprimé", medicineId: id)
    }
    
    // MARK: - Aisle Operations
    
    override func getAisles() async throws -> [Aisle] {
        return aisles
    }
    
    override func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
            aisles[index] = aisle
            addHistoryEntry(action: "Rayon modifié", medicineId: "")
        } else {
            aisles.append(aisle)
            addHistoryEntry(action: "Rayon créé", medicineId: "")
        }
        
        return aisle
    }
    
    // MARK: - History Operations
    
    override func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        if let medicineId = medicineId {
            return history.filter { $0.medicineId == medicineId }
        }
        return history
    }
    
    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        history.append(entry)
    }
    
    // MARK: - Helper Methods
    
    private func addHistoryEntry(action: String, medicineId: String) {
        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: currentUserId,
            action: action,
            details: "Action: \(action)",
            timestamp: Date()
        )
        history.append(entry)
    }
    
    func synchronizePendingOperations() async throws {
        guard isOnline else { return }
        
        for (operation, data) in pendingOperations {
            switch operation {
            case "saveMedicine":
                if let medicine = data as? Medicine {
                    _ = try await saveMedicine(medicine)
                }
            case "updateStock":
                if let params = data as? [String: Any],
                   let id = params["id"] as? String,
                   let newStock = params["newStock"] as? Int {
                    _ = try await updateMedicineStock(id: id, newStock: newStock)
                }
            default:
                break
            }
        }
        
        pendingOperations.removeAll()
    }
}