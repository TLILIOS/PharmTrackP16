import XCTest
@testable import MediStock

@MainActor
class MedicineListViewModelTests: XCTestCase {
    
    var viewModel: MedicineListViewModel!
    var mockRepository: MockMedicineRepository!
    var mockHistoryRepository: MockHistoryRepository!
    var mockNotificationService: MockNotificationService!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMedicineRepository()
        mockHistoryRepository = MockHistoryRepository()
        mockNotificationService = MockNotificationService()
        
        viewModel = MedicineListViewModel(
            repository: mockRepository,
            historyRepository: mockHistoryRepository,
            notificationService: mockNotificationService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockHistoryRepository = nil
        mockNotificationService = nil
        super.tearDown()
    }
    
    // MARK: - Load Medicines Tests
    
    func testLoadMedicinesSuccess() async {
        // Given
        let expectedMedicines = [
            Medicine.mock(id: "1", name: "Medicine 1"),
            Medicine.mock(id: "2", name: "Medicine 2")
        ]
        mockRepository.medicines = expectedMedicines
        
        // When
        await viewModel.loadMedicines()
        
        // Then
        XCTAssertEqual(viewModel.medicines.count, 2)
        XCTAssertEqual(viewModel.medicines[0].name, "Medicine 1")
        XCTAssertEqual(viewModel.medicines[1].name, "Medicine 2")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(mockNotificationService.checkExpirationsCallCount, 1)
    }
    
    func testLoadMedicinesError() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await viewModel.loadMedicines()
        
        // Then
        XCTAssertTrue(viewModel.medicines.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Filtered Medicines Tests
    
    func testFilteredMedicinesBySearch() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Doliprane"),
            Medicine.mock(id: "2", name: "Aspirine"),
            Medicine.mock(id: "3", name: "Ibuprofène")
        ]
        await viewModel.loadMedicines()
        
        // When
        viewModel.searchText = "Doli"
        
        // Then
        XCTAssertEqual(viewModel.filteredMedicines.count, 1)
        XCTAssertEqual(viewModel.filteredMedicines[0].name, "Doliprane")
    }
    
    func testFilteredMedicinesByAisle() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Medicine 1", aisleId: "aisle-1"),
            Medicine.mock(id: "2", name: "Medicine 2", aisleId: "aisle-2"),
            Medicine.mock(id: "3", name: "Medicine 3", aisleId: "aisle-1")
        ]
        await viewModel.loadMedicines()
        
        // When
        viewModel.selectedAisleId = "aisle-1"
        
        // Then
        XCTAssertEqual(viewModel.filteredMedicines.count, 2)
        XCTAssertTrue(viewModel.filteredMedicines.allSatisfy { $0.aisleId == "aisle-1" })
    }
    
    // MARK: - Critical and Expiring Medicines Tests
    
    func testCriticalMedicines() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", currentQuantity: 50),
            Medicine.mockCritical,
            Medicine.mock(id: "3", currentQuantity: 15, warningThreshold: 20)
        ]
        await viewModel.loadMedicines()
        
        // Then
        XCTAssertEqual(viewModel.criticalMedicines.count, 1)
        XCTAssertEqual(viewModel.criticalMedicines[0].name, "Aspirine")
    }
    
    func testExpiringMedicines() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1"), // Normal expiry
            Medicine.mockExpiring,
            Medicine.mockExpired
        ]
        await viewModel.loadMedicines()
        
        // Then
        XCTAssertEqual(viewModel.expiringMedicines.count, 1)
        XCTAssertEqual(viewModel.expiringMedicines[0].name, "Ibuprofène")
    }
    
    // MARK: - Save Medicine Tests
    
    func testSaveMedicineSuccess() async {
        // Given
        let newMedicine = Medicine.mock(id: "", name: "New Medicine")
        
        // When
        await viewModel.saveMedicine(newMedicine)
        
        // Then
        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(viewModel.medicines[0].name, "New Medicine")
        XCTAssertEqual(mockRepository.saveMedicineCallCount, 1)
        XCTAssertEqual(mockHistoryRepository.addHistoryEntryCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUpdateMedicineSuccess() async {
        // Given
        let existingMedicine = Medicine.mock(id: "1", name: "Original")
        mockRepository.medicines = [existingMedicine]
        await viewModel.loadMedicines()
        
        let updatedMedicine = Medicine.mock(id: "1", name: "Updated")
        
        // When
        await viewModel.saveMedicine(updatedMedicine)
        
        // Then
        XCTAssertEqual(viewModel.medicines.count, 1)
        XCTAssertEqual(viewModel.medicines[0].name, "Updated")
        XCTAssertEqual(mockHistoryRepository.addHistoryEntryCallCount, 1)
    }
    
    // MARK: - Delete Medicine Tests
    
    func testDeleteMedicineSuccess() async {
        // Given
        let medicine = Medicine.mock(id: "1", name: "To Delete")
        mockRepository.medicines = [medicine]
        await viewModel.loadMedicines()
        
        // When
        await viewModel.deleteMedicine(medicine)
        
        // Then
        XCTAssertTrue(viewModel.medicines.isEmpty)
        XCTAssertEqual(mockRepository.deleteMedicineCallCount, 1)
        XCTAssertEqual(mockHistoryRepository.addHistoryEntryCallCount, 1)
    }
    
    // MARK: - Stock Adjustment Tests
    
    func testAdjustStockSuccess() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 50)
        mockRepository.medicines = [medicine]
        await viewModel.loadMedicines()
        
        // When
        await viewModel.adjustStock(medicine: medicine, adjustment: 10, reason: "Livraison")
        
        // Then
        XCTAssertEqual(viewModel.medicines[0].currentQuantity, 60)
        XCTAssertEqual(mockHistoryRepository.addHistoryEntryCallCount, 1)
    }
    
    func testAdjustStockNegativeSuccess() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 50)
        mockRepository.medicines = [medicine]
        await viewModel.loadMedicines()
        
        // When
        await viewModel.adjustStock(medicine: medicine, adjustment: -20, reason: "Utilisation")
        
        // Then
        XCTAssertEqual(viewModel.medicines[0].currentQuantity, 30)
    }
    
    func testAdjustStockBelowZero() async {
        // Given
        let medicine = Medicine.mock(id: "1", currentQuantity: 10)
        mockRepository.medicines = [medicine]
        await viewModel.loadMedicines()
        
        // When
        await viewModel.adjustStock(medicine: medicine, adjustment: -20, reason: "Utilisation")
        
        // Then
        XCTAssertEqual(viewModel.medicines[0].currentQuantity, 0) // Should not go below 0
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMoreMedicinesSuccess() async {
        // Given
        let firstBatch = Array(1...20).map { Medicine.mock(id: "\($0)", name: "Medicine \($0)") }
        mockRepository.medicines = firstBatch
        await viewModel.loadMedicines()
        
        let secondBatch = Array(21...30).map { Medicine.mock(id: "\($0)", name: "Medicine \($0)") }
        mockRepository.medicines = secondBatch
        
        // When
        await viewModel.loadMoreMedicines()
        
        // Then
        XCTAssertEqual(viewModel.medicines.count, 30)
        XCTAssertFalse(viewModel.isLoadingMore)
    }
    
    func testClearError() {
        // Given
        viewModel.errorMessage = "Some error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
}