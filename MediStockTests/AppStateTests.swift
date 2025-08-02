import XCTest
@testable import MediStock

@MainActor
final class AppStateTests: XCTestCase {
    var sut: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        sut = AppState(data: MockDataServiceAdapterForIntegration())
    }
    
    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.medicines.isEmpty)
        XCTAssertTrue(sut.aisles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.selectedTab, 0)
        XCTAssertTrue(sut.searchText.isEmpty)
        XCTAssertNil(sut.selectedAisleId)
    }
    
    func testFilteredMedicines() {
        // Setup test data
        sut.medicines = [
            Medicine.mock(id: "1", name: "Doliprane", aisleId: "aisle-1"),
            Medicine.mock(id: "2", name: "Aspirine", aisleId: "aisle-2"),
            Medicine.mock(id: "3", name: "Ibuprofène", aisleId: "aisle-1"),
            Medicine.mock(id: "4", name: "Paracétamol", reference: "PARA500", aisleId: "aisle-2")
        ]
        
        // Test without filters
        XCTAssertEqual(sut.filteredMedicines.count, 4)
        
        // Test with search text
        sut.searchText = "Doli"
        XCTAssertEqual(sut.filteredMedicines.count, 1)
        XCTAssertEqual(sut.filteredMedicines.first?.name, "Doliprane")
        
        // Test with reference search
        sut.searchText = "PARA"
        XCTAssertEqual(sut.filteredMedicines.count, 1)
        XCTAssertEqual(sut.filteredMedicines.first?.name, "Paracétamol")
        
        // Test with aisle filter
        sut.searchText = ""
        sut.selectedAisleId = "aisle-1"
        XCTAssertEqual(sut.filteredMedicines.count, 2)
        XCTAssertTrue(sut.filteredMedicines.allSatisfy { $0.aisleId == "aisle-1" })
        
        // Test with both filters
        sut.searchText = "Ibu"
        sut.selectedAisleId = "aisle-1"
        XCTAssertEqual(sut.filteredMedicines.count, 1)
        XCTAssertEqual(sut.filteredMedicines.first?.name, "Ibuprofène")
    }
    
    func testCriticalMedicines() {
        // Setup test data
        sut.medicines = [
            Medicine.mock(id: "1", currentQuantity: 50, criticalThreshold: 10), // Normal
            Medicine.mock(id: "2", currentQuantity: 5, criticalThreshold: 10),  // Critical
            Medicine.mock(id: "3", currentQuantity: 15, warningThreshold: 20, criticalThreshold: 10), // Warning
            Medicine.mock(id: "4", currentQuantity: 3, criticalThreshold: 5)   // Critical
        ]
        
        let critical = sut.criticalMedicines
        XCTAssertEqual(critical.count, 2)
        XCTAssertTrue(critical.allSatisfy { $0.stockStatus == .critical })
    }
    
    func testExpiringMedicines() {
        // Setup test data
        let futureDate = Date().addingTimeInterval(60 * 24 * 60 * 60) // 60 days
        let soonDate = Date().addingTimeInterval(15 * 24 * 60 * 60)   // 15 days
        let expiredDate = Date().addingTimeInterval(-1 * 24 * 60 * 60) // Yesterday
        
        sut.medicines = [
            Medicine.mock(id: "1", expiryDate: futureDate),   // Not expiring
            Medicine.mock(id: "2", expiryDate: soonDate),     // Expiring soon
            Medicine.mock(id: "3", expiryDate: expiredDate),  // Already expired
            Medicine.mock(id: "4", expiryDate: nil)           // No expiry date
        ]
        
        let expiring = sut.expiringMedicines
        XCTAssertEqual(expiring.count, 2)
        XCTAssertTrue(expiring.contains { $0.id == "2" })
        XCTAssertTrue(expiring.contains { $0.id == "3" })
    }
    
    func testClearError() {
        // Given
        sut.errorMessage = "Test error"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func testExtractChange() async {
        // Test with AppState's private methods through public interface
        let mockDataService = sut.data as! MockDataServiceAdapterForIntegration
        mockDataService.history = [
            HistoryEntry.mock(action: "Ajout stock", details: "10 unités - Ajout de stock"),
            HistoryEntry.mock(action: "Ajout stock", details: "25 boîtes - Livraison"),
            HistoryEntry.mock(action: "Modification", details: "Modification sans quantité")
        ]
        
        // Load history should process these entries
        await sut.loadHistory()
        
        // The stockHistory should be populated with correct changes
        XCTAssertTrue(sut.stockHistory.count >= 2, "Expected at least 2 stock history entries")
        
        // Check first entry extracted change correctly
        if sut.stockHistory.count > 0 {
            XCTAssertEqual(sut.stockHistory[0].change, 10)
        }
        
        // Check second entry
        if sut.stockHistory.count > 1 {
            XCTAssertEqual(sut.stockHistory[1].change, 25)
        }
    }
    
    func testExtractQuantities() async {
        // Test quantity extraction through history loading
        let mockDataService = sut.data as! MockDataServiceAdapterForIntegration
        mockDataService.history = [
            HistoryEntry.mock(action: "Ajustement", details: "Ajustement (Stock: 50 → 60)"),
            HistoryEntry.mock(action: "Retrait stock", details: "Retrait (Stock: 100 → 75)"),
            HistoryEntry.mock(action: "Modification", details: "Modification sans stock info")
        ]
        
        await sut.loadHistory()
        
        // Verify stock history has correct quantities
        XCTAssertTrue(sut.stockHistory.count >= 2, "Expected at least 2 stock history entries")
        
        if sut.stockHistory.count >= 2 {
            XCTAssertEqual(sut.stockHistory[0].previousQuantity, 50)
            XCTAssertEqual(sut.stockHistory[0].newQuantity, 60)
            XCTAssertEqual(sut.stockHistory[1].previousQuantity, 100)
            XCTAssertEqual(sut.stockHistory[1].newQuantity, 75)
        }
    }
}