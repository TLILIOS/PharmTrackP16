import XCTest
import Combine
@testable import MediStock

@MainActor
final class MedicineRepositoryTests: BaseTestCase {
    
    private var repository: MedicineRepository!
    private var mockDataService: MockMedicineDataServiceAdapter!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockMedicineDataServiceAdapter()
        repository = MedicineRepository(dataService: mockDataService)
    }
    
    override func tearDown() {
        repository = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: Batch Update Medicines
    
    func testBatchUpdateMedicines() async throws {
        // Given
        let medicines = (0..<10).map { index in
            Medicine(
                id: "med-\(index)",
                name: "Medicine \(index)",
                description: "Test medicine \(index)",
                dosage: "500mg",
                form: "comprimé",
                reference: "REF-\(index)",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 500,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        mockDataService.configure(medicines: medicines)
        
        // When: Update stock for all medicines
        let updatedMedicines = medicines.map { medicine in
            var updated = medicine
            updated.currentQuantity = medicine.currentQuantity + 50
            return updated
        }
        
        try await repository.updateMultipleMedicines(updatedMedicines)
        
        // Then: Verify all medicines were updated
        XCTAssertEqual(mockDataService.batchUpdateCallCount, 1)
        XCTAssertEqual(mockDataService.lastBatchUpdated.count, 10)
        
        for (index, medicine) in mockDataService.lastBatchUpdated.enumerated() {
            XCTAssertEqual(medicine.currentQuantity, 150)
            XCTAssertEqual(medicine.id, "med-\(index)")
        }
    }
    
    // MARK: - Test: Medicine Search Filtering
    
    func testMedicineSearchFiltering() async throws {
        // Given: Setup medicines with various attributes
        mockDataService.mockMedicines = [
            Medicine(id: "1", name: "Doliprane 500mg", description: nil, dosage: "500mg", form: "comprimé", reference: "REF1", unit: "comprimés", currentQuantity: 100, maxQuantity: 500, warningThreshold: 50, criticalThreshold: 20, expiryDate: nil, aisleId: "aisle1", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "2", name: "Aspirine", description: nil, dosage: "100mg", form: "comprimé", reference: "REF2", unit: "comprimés", currentQuantity: 50, maxQuantity: 200, warningThreshold: 30, criticalThreshold: 10, expiryDate: nil, aisleId: "aisle2", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "3", name: "Doliprane 1000mg", description: nil, dosage: "1000mg", form: "comprimé", reference: "REF3", unit: "comprimés", currentQuantity: 75, maxQuantity: 300, warningThreshold: 40, criticalThreshold: 15, expiryDate: nil, aisleId: "aisle1", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "4", name: "Paracétamol", description: nil, dosage: "500mg", form: "boîte", reference: "REF4", unit: "boîtes", currentQuantity: 30, maxQuantity: 100, warningThreshold: 25, criticalThreshold: 10, expiryDate: nil, aisleId: "aisle3", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "5", name: "Ibuprofène", description: nil, dosage: "200mg", form: "comprimé", reference: "REF5", unit: "comprimés", currentQuantity: 0, maxQuantity: 150, warningThreshold: 30, criticalThreshold: 10, expiryDate: nil, aisleId: "aisle2", createdAt: Date(), updatedAt: Date())
        ]
        
        // Test 1: Filter by name containing "Doliprane"
        mockDataService.filterPredicate = { (medicine: Medicine) in medicine.name.contains("Doliprane") }
        let dolipraneResults = try await repository.fetchMedicines()
        XCTAssertEqual(dolipraneResults.count, 2)
        XCTAssertTrue(dolipraneResults.allSatisfy { $0.name.contains("Doliprane") })
        
        // Test 2: Filter by aisle
        mockDataService.filterPredicate = { (medicine: Medicine) in medicine.aisleId == "aisle2" }
        let aisle2Results = try await repository.fetchMedicines()
        XCTAssertEqual(aisle2Results.count, 2)
        XCTAssertTrue(aisle2Results.allSatisfy { $0.aisleId == "aisle2" })
        
        // Test 3: Filter by stock status (critical)
        mockDataService.filterPredicate = { (medicine: Medicine) in medicine.stockStatus == .critical }
        let criticalResults = try await repository.fetchMedicines()
        XCTAssertEqual(criticalResults.count, 1) // Only Ibuprofène (quantity 0)
        
        // Test 4: Filter by unit type
        mockDataService.filterPredicate = { (medicine: Medicine) in medicine.unit == "boîtes" }
        let boxResults = try await repository.fetchMedicines()
        XCTAssertEqual(boxResults.count, 1)
        XCTAssertEqual(boxResults.first?.name, "Paracétamol")
    }
    
    // MARK: - Test: Stock Adjustment Boundaries
    
    func testStockAdjustmentBoundaries() async throws {
        // Given
        let medicine = Medicine(
            id: "boundary-test",
            name: "Test Medicine",
            description: nil,
            dosage: "500mg",
            form: "comprimé",
            reference: "REF-BOUND",
            unit: "comprimés",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 30,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: "aisle1",
            createdAt: Date(),
            updatedAt: Date()
        )
        mockDataService.mockMedicines = [medicine]
        
        // Test 1: Adjustment within boundaries
        let updated1 = try await repository.updateMedicineStock(id: "boundary-test", newStock: 75)
        XCTAssertEqual(updated1.currentQuantity, 75)
        
        // Test 2: Adjustment to maximum
        let updated2 = try await repository.updateMedicineStock(id: "boundary-test", newStock: 100)
        XCTAssertEqual(updated2.currentQuantity, 100)
        
        // Test 3: Adjustment to minimum
        let updated3 = try await repository.updateMedicineStock(id: "boundary-test", newStock: 10)
        XCTAssertEqual(updated3.currentQuantity, 10)
        
        // Test 4: Adjustment to zero (allowed)
        let updated4 = try await repository.updateMedicineStock(id: "boundary-test", newStock: 0)
        XCTAssertEqual(updated4.currentQuantity, 0)
        
        // Test 5: Negative stock (should throw error)
        mockDataService.shouldValidateStock = true
        do {
            _ = try await repository.updateMedicineStock(id: "boundary-test", newStock: -10)
            XCTFail("Expected error for negative stock")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test 6: Exceeding maximum (should throw error)
        do {
            _ = try await repository.updateMedicineStock(id: "boundary-test", newStock: 150)
            XCTFail("Expected error for exceeding maximum")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    // MARK: - Test: Medicine Sorting and Pagination
    
    func testMedicineSortingAndPagination() async throws {
        // Given: 50 medicines with various attributes
        let medicines = (0..<50).map { index in
            Medicine(
                id: "med-\(index)",
                name: "Medicine \(String(format: "%03d", index))",
                description: nil,
                dosage: "500mg",
                form: "comprimé",
                reference: "REF-\(index)",
                unit: "comprimés",
                currentQuantity: Int.random(in: 0...200),
                maxQuantity: 200,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Date().addingTimeInterval(Double(index) * 24 * 60 * 60),
                aisleId: "aisle\(index % 3)",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        mockDataService.configure(medicines: medicines)
        
        // Test 1: Pagination - First page
        let page1 = try await repository.fetchMedicinesPaginated(limit: 20, refresh: true)
        XCTAssertEqual(page1.count, 20)
        
        // Test 2: Pagination - Second page
        mockDataService.currentPage = 1
        let page2 = try await repository.fetchMedicinesPaginated(limit: 20, refresh: false)
        XCTAssertEqual(page2.count, 20)
        XCTAssertNotEqual(page1.first?.id, page2.first?.id)
        
        // Test 3: Pagination - Last page (partial)
        mockDataService.currentPage = 2
        let page3 = try await repository.fetchMedicinesPaginated(limit: 20, refresh: false)
        XCTAssertEqual(page3.count, 10)
        
        // Test 4: Sorting by name
        mockDataService.sortDescriptor = { (medicines: [Medicine]) in medicines.sorted(by: { $0.name < $1.name }) }
        let sortedByName = try await repository.fetchMedicines()
        XCTAssertEqual(sortedByName.first?.name, "Medicine 000")
        XCTAssertEqual(sortedByName.last?.name, "Medicine 049")
        
        // Test 5: Sorting by stock (ascending)
        mockDataService.sortDescriptor = { (medicines: [Medicine]) in medicines.sorted(by: { $0.currentQuantity < $1.currentQuantity }) }
        let sortedByStock = try await repository.fetchMedicines()
        let stocks = sortedByStock.map { $0.currentQuantity }
        XCTAssertEqual(stocks, stocks.sorted())
        
        // Test 6: Sorting by expiry date
        mockDataService.sortDescriptor = { (medicines: [Medicine]) in medicines.sorted(by: { ($0.expiryDate ?? Date.distantFuture) < ($1.expiryDate ?? Date.distantFuture) }) }
        let sortedByExpiry = try await repository.fetchMedicines()
        XCTAssertEqual(sortedByExpiry.first?.id, "med-0")
    }
    
    // MARK: - Test: Delete Multiple Medicines
    
    func testDeleteMultipleMedicines() async throws {
        // Given
        let medicines = (0..<10).map { index in
            Medicine(
                id: "del-\(index)",
                name: "Medicine \(index)",
                description: nil,
                dosage: "500mg",
                form: "comprimé",
                reference: "REF-DEL-\(index)",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 500,
                warningThreshold: 50,
                criticalThreshold: 10,
                expiryDate: nil,
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        mockDataService.configure(medicines: medicines)
        
        // When: Delete multiple medicines
        let idsToDelete = ["del-2", "del-5", "del-8"]
        try await repository.deleteMultipleMedicines(ids: idsToDelete)
        
        // Then: Verify deletions
        XCTAssertEqual(mockDataService.deleteCallCount, 3)
        XCTAssertEqual(mockDataService.deletedIds, idsToDelete)
        
        let remainingMedicines = mockDataService.mockMedicines
        XCTAssertEqual(remainingMedicines.count, 7)
        XCTAssertFalse(remainingMedicines.contains { idsToDelete.contains($0.id) })
    }
}

// MARK: - Mock Medicine Data Service Adapter

class MockMedicineDataServiceAdapter: DataServiceAdapter {
    var mockMedicines: [Medicine] = []
    var shouldThrowError = false
    var errorToThrow: Error?
    var shouldValidateStock = false
    
    // Tracking
    var batchUpdateCallCount = 0
    var lastBatchUpdated: [Medicine] = []
    var deleteCallCount = 0
    var deletedIds: [String] = []
    
    // Filtering and sorting
    var filterPredicate: ((Medicine) -> Bool)?
    var sortDescriptor: (([Medicine]) -> [Medicine])?
    var currentPage = 0
    
    func configure(medicines: [Medicine]) {
        self.mockMedicines = medicines
    }
    
    override func getMedicines() async throws -> [Medicine] {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        var result = mockMedicines
        
        // Apply filter if set
        if let filter = filterPredicate {
            result = result.filter(filter)
        }
        
        // Apply sort if set
        if let sort = sortDescriptor {
            result = sort(result)
        }
        
        return result
    }
    
    override func getMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        if refresh {
            currentPage = 0
        }
        
        let startIndex = currentPage * limit
        let endIndex = min(startIndex + limit, mockMedicines.count)
        
        guard startIndex < mockMedicines.count else {
            return []
        }
        
        return Array(mockMedicines[startIndex..<endIndex])
    }
    
    override func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        if let index = mockMedicines.firstIndex(where: { $0.id == medicine.id }) {
            mockMedicines[index] = medicine
        } else {
            mockMedicines.append(medicine)
        }
        
        return medicine
    }
    
    override func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        guard let index = mockMedicines.firstIndex(where: { $0.id == id }) else {
            throw ValidationError.invalidId
        }
        
        if shouldValidateStock {
            if newStock < 0 {
                throw ValidationError.negativeQuantity(field: "stock")
            }
            if newStock > mockMedicines[index].maxQuantity {
                throw ValidationError.invalidMaxQuantity
            }
        }
        
        var medicine = mockMedicines[index]
        medicine.currentQuantity = newStock
        mockMedicines[index] = medicine
        
        return medicine
    }
    
    override func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        batchUpdateCallCount += 1
        lastBatchUpdated = medicines
        
        for medicine in medicines {
            if let index = mockMedicines.firstIndex(where: { $0.id == medicine.id }) {
                mockMedicines[index] = medicine
            }
        }
    }
    
    override func deleteMedicine(id: String) async throws {
        deleteCallCount += 1
        deletedIds.append(id)
        mockMedicines.removeAll { $0.id == id }
    }
    
    override func deleteMultipleMedicines(ids: [String]) async throws {
        for id in ids {
            try await deleteMedicine(id: id)
        }
    }

    // MARK: - Override ALL DataServiceAdapter methods to prevent Firebase calls

    override func deleteMedicine(_ medicine: Medicine) async throws {
        try await deleteMedicine(id: medicine.id)
    }

    override func adjustStock(medicineId: String, adjustment: Int) async throws -> Medicine {
        guard let index = mockMedicines.firstIndex(where: { $0.id == medicineId }) else {
            throw ValidationError.invalidId
        }

        var medicine = mockMedicines[index]
        medicine.currentQuantity = max(0, medicine.currentQuantity + adjustment)
        mockMedicines[index] = medicine

        return medicine
    }

    override func getAisles() async throws -> [Aisle] {
        return []
    }

    override func getAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        return []
    }

    override func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        return aisle
    }

    override func deleteAisle(_ aisle: Aisle) async throws {
        // No-op
    }

    override func deleteAisle(id: String) async throws {
        // No-op
    }

    override func checkAisleExists(_ aisleId: String) async throws -> Bool {
        return true
    }

    override func countMedicinesInAisle(_ aisleId: String) async throws -> Int {
        return mockMedicines.filter { $0.aisleId == aisleId }.count
    }

    override func getHistory(for medicineId: String?) async throws -> [HistoryEntry] {
        return []
    }

    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        // No-op
    }

    override func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        // No-op: pas de listener Firebase
    }

    override func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        // No-op: pas de listener Firebase
    }

    override func stopListening() {
        // No-op: pas de listener à arrêter
    }
}