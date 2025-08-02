import XCTest
@testable import MediStock

@MainActor
final class HistoryDetailViewModelTests: XCTestCase {
    
    private var sut: HistoryDetailViewModel!
    private var mockHistoryRepository: MockHistoryRepository!
    private var mockMedicineRepository: MockMedicineRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mockHistoryRepository = MockHistoryRepository()
        mockMedicineRepository = MockMedicineRepository()
        sut = HistoryDetailViewModel(
            historyRepository: mockHistoryRepository,
            medicineRepository: mockMedicineRepository
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockHistoryRepository = nil
        mockMedicineRepository = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.historyEntries.isEmpty)
        XCTAssertTrue(sut.filteredEntries.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.selectedDateRange, .all)
        XCTAssertNil(sut.selectedActionType)
        XCTAssertTrue(sut.searchText.isEmpty)
        XCTAssertNil(sut.statistics)
    }
    
    // MARK: - Load History Tests
    
    func testLoadHistorySuccess() async {
        // Given
        let mockEntries = createMockHistoryEntries()
        mockHistoryRepository.history = mockEntries
        mockMedicineRepository.medicines = createMockMedicines()
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.historyEntries.count, 5)
        XCTAssertEqual(sut.filteredEntries.count, 5)
        XCTAssertNotNil(sut.statistics)
    }
    
    func testLoadHistoryFailure() async {
        // Given
        mockHistoryRepository.shouldThrowError = true
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.historyEntries.isEmpty)
    }
    
    func testLoadHistoryForMedicineSuccess() async {
        // Given
        let medicineId = "med-1"
        let mockEntries = createMockHistoryEntries().filter { $0.medicineId == medicineId }
        mockHistoryRepository.history = mockEntries
        
        // When
        await sut.loadHistoryForMedicine(medicineId)
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.historyEntries.count, 2)
        XCTAssertEqual(sut.filteredEntries.count, 2)
    }
    
    // MARK: - Filtering Tests
    
    func testFilterByDateRange() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When - Today filter
        sut.selectedDateRange = .today
        sut.applyFilters()
        
        // Then
        XCTAssertTrue(sut.filteredEntries.count <= sut.historyEntries.count)
        
        // When - Week filter
        sut.selectedDateRange = .week
        sut.applyFilters()
        
        // Then
        XCTAssertTrue(sut.filteredEntries.count >= 1)
    }
    
    func testFilterByActionType() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.selectedActionType = .addition
        sut.applyFilters()
        
        // Then
        XCTAssertTrue(sut.filteredEntries.allSatisfy { 
            $0.action.lowercased().contains("ajout")
        })
    }
    
    func testFilterBySearchText() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.searchText = "Doliprane"
        sut.applyFilters()
        
        // Then
        XCTAssertTrue(sut.filteredEntries.allSatisfy {
            $0.details.localizedCaseInsensitiveContains("Doliprane") ||
            $0.action.localizedCaseInsensitiveContains("Doliprane")
        })
    }
    
    func testCombinedFilters() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        sut.selectedDateRange = .month
        sut.selectedActionType = .addition
        sut.searchText = "stock"
        sut.applyFilters()
        
        // Then
        XCTAssertTrue(sut.filteredEntries.count <= sut.historyEntries.count)
    }
    
    // MARK: - Statistics Tests
    
    func testStatisticsCalculation() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        mockMedicineRepository.medicines = createMockMedicines()
        
        // When
        await sut.loadHistory()
        
        // Then
        XCTAssertNotNil(sut.statistics)
        if let stats = sut.statistics {
            XCTAssertGreaterThanOrEqual(stats.totalActions, 0)
            XCTAssertGreaterThanOrEqual(stats.addActions, 0)
            XCTAssertGreaterThanOrEqual(stats.removeActions, 0)
            XCTAssertGreaterThanOrEqual(stats.modifications, 0)
            XCTAssertFalse(stats.topMedicines.isEmpty)
        }
    }
    
    // MARK: - Export Tests
    
    func testExportToCSVSuccess() async throws {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When
        let url = try await sut.exportHistory(format: .csv)
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    func testExportToPDFNotSupported() async {
        // Given
        mockHistoryRepository.history = createMockHistoryEntries()
        await sut.loadHistory()
        
        // When/Then
        do {
            _ = try await sut.exportHistory(format: .pdf)
            XCTFail("Expected export to fail")
        } catch {
            XCTAssertTrue(error is ExportError)
        }
    }
    
    func testCSVContentFormat() async throws {
        // Given
        let testEntry = HistoryEntry(
            id: "test-1",
            medicineId: "med-1",
            userId: "user-1",
            action: "Ajout stock",
            details: "10 unités - Test export",
            timestamp: Date()
        )
        mockHistoryRepository.history = [testEntry]
        await sut.loadHistory()
        
        // When
        let url = try await sut.exportHistory(format: .csv)
        let content = try String(contentsOf: url, encoding: .utf8)
        
        // Then
        XCTAssertTrue(content.contains("Date,Heure,Action,Détails,Utilisateur"))
        XCTAssertTrue(content.contains("Ajout stock"))
        XCTAssertTrue(content.contains("10 unités - Test export"))
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Date Range Tests
    
    func testDateRangeIntervals() {
        // Test all date ranges
        for dateRange in DateRange.allCases {
            switch dateRange {
            case .all:
                XCTAssertNil(dateRange.dateInterval)
            default:
                XCTAssertNotNil(dateRange.dateInterval)
            }
        }
    }
    
    // MARK: - Action Type Tests
    
    func testActionTypeProperties() {
        // Test all action types have proper icon and color
        for actionType in ActionType.allCases {
            XCTAssertFalse(actionType.icon.isEmpty)
            XCTAssertNotNil(actionType.color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockHistoryEntries() -> [HistoryEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            HistoryEntry(
                id: "1",
                medicineId: "med-1",
                userId: "user-1",
                action: "Ajout stock",
                details: "10 unités - Doliprane livraison",
                timestamp: now
            ),
            HistoryEntry(
                id: "2",
                medicineId: "med-1",
                userId: "user-1",
                action: "Retrait stock",
                details: "5 unités - Doliprane vente",
                timestamp: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            HistoryEntry(
                id: "3",
                medicineId: "med-2",
                userId: "user-2",
                action: "Modification",
                details: "Modification informations Aspirine",
                timestamp: calendar.date(byAdding: .day, value: -7, to: now)!
            ),
            HistoryEntry(
                id: "4",
                medicineId: "med-3",
                userId: "user-1",
                action: "Ajout",
                details: "Nouveau médicament Ibuprofène",
                timestamp: calendar.date(byAdding: .month, value: -1, to: now)!
            ),
            HistoryEntry(
                id: "5",
                medicineId: "med-2",
                userId: "user-2",
                action: "Suppression",
                details: "Suppression Aspirine périmée",
                timestamp: calendar.date(byAdding: .month, value: -2, to: now)!
            )
        ]
    }
    
    private func createMockMedicines() -> [Medicine] {
        return [
            Medicine.mock(id: "med-1", name: "Doliprane"),
            Medicine.mock(id: "med-2", name: "Aspirine"),
            Medicine.mock(id: "med-3", name: "Ibuprofène")
        ]
    }
}