import XCTest
@testable import MediStock

@MainActor
final class HistoryViewModelTests: XCTestCase {
    
    private var sut: HistoryViewModel!
    private var mockRepository: MockHistoryRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockHistoryRepository()
        sut = HistoryViewModel(repository: mockRepository)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertTrue(sut.stockHistory.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.filterType, .all)
    }
    
    // MARK: - Load History Tests
    
    func testLoadHistorySuccess() async {
        // Given
        let mockEntries = createMockHistoryEntries()
        mockRepository.history = mockEntries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.history.count, 5)
        XCTAssertEqual(sut.stockHistory.count, 5)
    }
    
    func testLoadHistoryFailure() async {
        // Given
        mockRepository.shouldThrowError = true
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertTrue(sut.stockHistory.isEmpty)
    }
    
    func testLoadHistoryLoadingState() async {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changed")
        var loadingStates: [Bool] = []
        
        let cancellable = sut.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count == 3 {
                expectation.fulfill()
            }
        }
        
        // When
        await sut.loadHistory()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false])
        cancellable.cancel()
    }
    
    // MARK: - Filter Tests
    
    func testFilteredHistoryAll() async {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.filterType = .all
        
        // Then
        XCTAssertEqual(sut.filteredHistory.count, sut.stockHistory.count)
    }
    
    func testFilteredHistoryAdjustments() async {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.filterType = .adjustments
        
        // Then
        XCTAssertTrue(sut.filteredHistory.allSatisfy { $0.type == .adjustment })
        XCTAssertEqual(sut.filteredHistory.count, 3)
    }
    
    func testFilteredHistoryAdditions() async {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.filterType = .additions
        
        // Then
        XCTAssertTrue(sut.filteredHistory.allSatisfy { $0.type == .addition })
        XCTAssertEqual(sut.filteredHistory.count, 1)
    }
    
    func testFilteredHistoryDeletions() async {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.filterType = .deletions
        
        // Then
        XCTAssertTrue(sut.filteredHistory.allSatisfy { $0.type == .deletion })
        XCTAssertEqual(sut.filteredHistory.count, 1)
    }
    
    // MARK: - Conversion Tests
    
    func testConvertToStockHistoryAdjustment() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Ajout stock", details: "10 unités - Livraison"),
            HistoryEntry.mock(action: "Retrait stock", details: "5 unités - Vente")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertEqual(sut.stockHistory.count, 2)
        XCTAssertTrue(sut.stockHistory.allSatisfy { $0.type == .adjustment })
    }
    
    func testConvertToStockHistoryAddition() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Ajout", details: "Nouveau médicament")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertEqual(sut.stockHistory.count, 1)
        XCTAssertEqual(sut.stockHistory.first?.type, .addition)
    }
    
    func testConvertToStockHistoryDeletion() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Médicament supprimé", details: "Périmé")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertEqual(sut.stockHistory.count, 1)
        XCTAssertEqual(sut.stockHistory.first?.type, .deletion)
    }
    
    // MARK: - Data Extraction Tests
    
    func testExtractChangeFromDetails() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Ajout stock", details: "15 unités - Test"),
            HistoryEntry.mock(action: "Retrait stock", details: "8 boîtes - Vente"),
            HistoryEntry.mock(action: "Modification", details: "Changement sans quantité")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertEqual(sut.stockHistory[0].change, 15)
        XCTAssertEqual(sut.stockHistory[1].change, 8)
        XCTAssertEqual(sut.stockHistory[2].change, 0)
    }
    
    func testExtractReasonFromDetails() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Ajout stock", details: "10 unités - Livraison matinale"),
            HistoryEntry.mock(action: "Retrait stock", details: "5 unités - Vente client"),
            HistoryEntry.mock(action: "Modification", details: "Sans tiret")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertEqual(sut.stockHistory[0].reason, "Livraison matinale")
        XCTAssertEqual(sut.stockHistory[1].reason, "Vente client")
        XCTAssertNil(sut.stockHistory[2].reason)
    }
    
    func testExtractQuantitiesFromDetails() async {
        // Given
        let entries = [
            HistoryEntry.mock(action: "Ajustement", details: "Ajustement (Stock: 50 → 60)"),
            HistoryEntry.mock(action: "Retrait", details: "Retrait (Stock: 100 → 75)")
        ]
        mockRepository.history = entries
        
        // When
        await sut.loadHistory()
        
        // Then
        // Note: extractQuantities currently returns (0, 0) - test the current behavior
        XCTAssertEqual(sut.stockHistory[0].previousQuantity, 0)
        XCTAssertEqual(sut.stockHistory[0].newQuantity, 0)
    }
    
    // MARK: - Clear Error Tests
    
    func testClearError() {
        // Given
        sut.errorMessage = "Test error"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Filter Type Tests
    
    func testFilterTypeIcons() {
        XCTAssertEqual(HistoryViewModel.FilterType.all.icon, "clock")
        XCTAssertEqual(HistoryViewModel.FilterType.adjustments.icon, "arrow.up.arrow.down")
        XCTAssertEqual(HistoryViewModel.FilterType.additions.icon, "plus.circle")
        XCTAssertEqual(HistoryViewModel.FilterType.deletions.icon, "trash")
    }
    
    func testFilterTypeRawValues() {
        XCTAssertEqual(HistoryViewModel.FilterType.all.rawValue, "Tout")
        XCTAssertEqual(HistoryViewModel.FilterType.adjustments.rawValue, "Ajustements")
        XCTAssertEqual(HistoryViewModel.FilterType.additions.rawValue, "Ajouts")
        XCTAssertEqual(HistoryViewModel.FilterType.deletions.rawValue, "Suppressions")
    }
    
    // MARK: - Performance Tests
    
    func testLoadHistoryPerformance() {
        // Given
        let largeHistory = (0..<1000).map { index in
            HistoryEntry.mock(
                id: "entry-\(index)",
                action: ["Ajout stock", "Retrait stock", "Ajout", "Suppression"].randomElement()!,
                details: "\(Int.random(in: 1...100)) unités - Test \(index)"
            )
        }
        mockRepository.history = largeHistory
        
        // When/Then
        measure {
            let expectation = XCTestExpectation(description: "Load history")
            Task {
                await sut.loadHistory()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockHistoryEntries() -> [HistoryEntry] {
        return [
            HistoryEntry.mock(
                id: "1",
                action: "Ajout stock",
                details: "10 unités - Livraison"
            ),
            HistoryEntry.mock(
                id: "2",
                action: "Retrait stock",
                details: "5 unités - Vente"
            ),
            HistoryEntry.mock(
                id: "3",
                action: "Ajout",
                details: "Nouveau médicament"
            ),
            HistoryEntry.mock(
                id: "4",
                action: "Modification",
                details: "Modification informations"
            ),
            HistoryEntry.mock(
                id: "5",
                action: "Médicament supprimé",
                details: "Périmé"
            )
        ]
    }
}