import XCTest
import Combine
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
        let now = Date()
        let entries = [
            HistoryEntry.mock(action: "Ajout stock", details: "15 unités - Test", timestamp: now.addingTimeInterval(-120)),      // Oldest
            HistoryEntry.mock(action: "Retrait stock", details: "8 boîtes - Vente", timestamp: now.addingTimeInterval(-60)),     // Middle
            HistoryEntry.mock(action: "Modification", details: "Changement sans quantité", timestamp: now)                        // Most recent
        ]
        mockRepository.history = entries

        // When
        await sut.loadHistory()

        // Then - Results are sorted by timestamp descending (most recent first)
        XCTAssertEqual(sut.stockHistory.count, 3)
        XCTAssertEqual(sut.stockHistory[0].change, 0)  // Most recent: "Modification"
        XCTAssertEqual(sut.stockHistory[1].change, 8)  // Middle: "Retrait stock"
        XCTAssertEqual(sut.stockHistory[2].change, 15) // Oldest: "Ajout stock"
    }
    
    func testExtractReasonFromDetails() async {
        // Given
        let now = Date()
        let entries = [
            HistoryEntry.mock(action: "Ajout stock", details: "10 unités - Livraison matinale", timestamp: now.addingTimeInterval(-120)),  // Oldest
            HistoryEntry.mock(action: "Retrait stock", details: "5 unités - Vente client", timestamp: now.addingTimeInterval(-60)),        // Middle
            HistoryEntry.mock(action: "Modification", details: "Sans tiret", timestamp: now)                                                // Most recent
        ]
        mockRepository.history = entries

        // When
        await sut.loadHistory()

        // Then - Results are sorted by timestamp descending (most recent first)
        XCTAssertEqual(sut.stockHistory.count, 3)
        XCTAssertNil(sut.stockHistory[0].reason)                        // Most recent: "Sans tiret"
        XCTAssertEqual(sut.stockHistory[1].reason, "Vente client")     // Middle: "Retrait stock"
        XCTAssertEqual(sut.stockHistory[2].reason, "Livraison matinale") // Oldest: "Ajout stock"
    }
    
    func testExtractQuantitiesFromDetails() async {
        // Given
        let now = Date()
        let entries = [
            HistoryEntry.mock(action: "Ajustement", details: "Ajustement (Stock: 50 → 60)", timestamp: now.addingTimeInterval(-60)),  // Older
            HistoryEntry.mock(action: "Retrait", details: "Retrait (Stock: 100 → 75)", timestamp: now)                                // Most recent
        ]
        mockRepository.history = entries

        // When
        await sut.loadHistory()

        // Then - Results are sorted by timestamp descending (most recent first)
        XCTAssertEqual(sut.stockHistory.count, 2)
        XCTAssertEqual(sut.stockHistory[0].previousQuantity, 100)  // Most recent: "Retrait"
        XCTAssertEqual(sut.stockHistory[0].newQuantity, 75)
        XCTAssertEqual(sut.stockHistory[1].previousQuantity, 50)   // Older: "Ajustement"
        XCTAssertEqual(sut.stockHistory[1].newQuantity, 60)
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
    
    // MARK: - Export Tests

    func testExportToCSVSuccess() async throws {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()

        let medicines = [
            "1": "Doliprane",
            "2": "Aspirine"
        ]

        // When
        let url = try await sut.exportHistory(format: .csv, medicines: medicines)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    func testExportToPDFSuccess() async throws {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()

        let medicines = [
            "1": "Doliprane",
            "2": "Aspirine"
        ]

        // When
        let url = try await sut.exportHistory(format: .pdf, medicines: medicines)

        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    func testCSVContentFormat() async throws {
        // Given
        let mockEntry = HistoryEntry.mock(
            id: "1",
            action: "Ajout stock",
            details: "10 unités - Livraison test"
        )
        mockRepository.history = [mockEntry]
        await sut.loadHistory()

        let medicines = ["1": "Doliprane"]

        // When
        let url = try await sut.exportHistory(format: .csv, medicines: medicines)
        let content = try String(contentsOf: url, encoding: .utf8)

        // Then
        XCTAssertTrue(content.contains("Date,Heure,Type,Médicament"))
        XCTAssertTrue(content.contains("Ajustement") || content.contains("Ajout"))

        // Clean up
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Notification Observer Tests

    func testHistoryDidChangeNotification() async {
        // Given
        let expectation = XCTestExpectation(description: "History reloaded on notification")
        mockRepository.history = createMockHistoryEntries()

        sut.$stockHistory
            .dropFirst()
            .sink { history in
                if !history.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - deinit Test

    func testDeinitRemovesObserver() {
        // Given
        var viewModel: HistoryViewModel? = HistoryViewModel(repository: mockRepository)

        // When
        viewModel = nil

        // Then - Should not crash (observer removed in deinit)
        NotificationCenter.default.post(name: NSNotification.Name("HistoryDidChange"), object: nil)
        XCTAssertNil(viewModel)
    }

    // MARK: - Filter Type Enum Tests

    func testFilterTypeColors() {
        XCTAssertNotNil(HistoryViewModel.FilterType.all.color)
        XCTAssertNotNil(HistoryViewModel.FilterType.adjustments.color)
        XCTAssertNotNil(HistoryViewModel.FilterType.additions.color)
        XCTAssertNotNil(HistoryViewModel.FilterType.deletions.color)
    }

    func testFilterTypeIdentifiable() {
        XCTAssertEqual(HistoryViewModel.FilterType.all.id, "Tout")
        XCTAssertEqual(HistoryViewModel.FilterType.adjustments.id, "Ajustements")
        XCTAssertEqual(HistoryViewModel.FilterType.additions.id, "Ajouts")
        XCTAssertEqual(HistoryViewModel.FilterType.deletions.id, "Suppressions")
    }

    func testFilterTypeCaseIterable() {
        let allCases = HistoryViewModel.FilterType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.all))
        XCTAssertTrue(allCases.contains(.adjustments))
        XCTAssertTrue(allCases.contains(.additions))
        XCTAssertTrue(allCases.contains(.deletions))
    }

    // MARK: - Edge Cases Tests

    func testExtractChangeFromDetailsEmptyString() async {
        // Given
        let entry = HistoryEntry.mock(action: "Test", details: "")
        mockRepository.history = [entry]

        // When
        await sut.loadHistory()

        // Then
        XCTAssertEqual(sut.stockHistory.first?.change, 0)
    }

    func testExtractQuantitiesFromDetailsNoMatch() async {
        // Given
        let entry = HistoryEntry.mock(action: "Test", details: "No quantities here")
        mockRepository.history = [entry]

        // When
        await sut.loadHistory()

        // Then
        XCTAssertEqual(sut.stockHistory.first?.previousQuantity, 0)
        XCTAssertEqual(sut.stockHistory.first?.newQuantity, 0)
    }

    func testConvertToStockHistoryDefaultType() async {
        // Given - Unknown action type
        let entry = HistoryEntry.mock(action: "Unknown action", details: "Test")
        mockRepository.history = [entry]

        // When
        await sut.loadHistory()

        // Then - Should default to adjustment
        XCTAssertEqual(sut.stockHistory.first?.type, .adjustment)
    }

    func testFilterUpdateTriggersFilteredHistoryUpdate() async {
        // Given
        mockRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        let initialCount = sut.filteredHistory.count

        // When
        sut.filterType = .adjustments

        // Then
        XCTAssertNotEqual(sut.filteredHistory.count, initialCount)
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