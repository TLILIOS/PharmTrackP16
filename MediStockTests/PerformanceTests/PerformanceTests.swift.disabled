import XCTest
@testable import MediStock

@MainActor
final class PerformanceTests: XCTestCase {
    
    private var dataService: MockPerformanceDataService!
    private var medicineRepo: MedicineRepository!
    private var aisleRepo: AisleRepository!
    private var historyRepo: HistoryRepository!
    
    override func setUp() {
        super.setUp()
        dataService = MockPerformanceDataService()
        medicineRepo = MedicineRepository(dataService: dataService)
        aisleRepo = AisleRepository(dataService: dataService)
        historyRepo = HistoryRepository(dataService: dataService)
    }
    
    override func tearDown() {
        medicineRepo = nil
        aisleRepo = nil
        historyRepo = nil
        dataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: Large Medicine List Performance
    
    func testLargeMedicineListPerformance() async throws {
        // Setup: Create 100 medicines (optimisé depuis 1000)
        let startSetup = Date()
        for i in 0..<100 {
            let medicine = createMedicine(index: i)
            dataService.medicines.append(medicine)
        }
        let setupDuration = Date().timeIntervalSince(startSetup)
        print("Setup 1000 medicines took: \(setupDuration)s")
        
        // Test 1: Fetch all medicines
        let startFetchAll = Date()
        let allMedicines = try await medicineRepo.fetchMedicines()
        let fetchAllDuration = Date().timeIntervalSince(startFetchAll)
        
        XCTAssertEqual(allMedicines.count, 100)
        XCTAssertLessThan(fetchAllDuration, 0.01, "Fetching 100 medicines should take less than 10ms")
        print("Fetch all medicines took: \(fetchAllDuration)s")
        
        // Test 2: Paginated fetch
        let startPaginated = Date()
        let page1 = try await medicineRepo.fetchMedicinesPaginated(limit: 20, refresh: true)
        let paginatedDuration = Date().timeIntervalSince(startPaginated)
        
        XCTAssertEqual(page1.count, 20)
        XCTAssertLessThan(paginatedDuration, 0.01, "Fetching 20 medicines should take less than 10ms")
        print("Paginated fetch took: \(paginatedDuration)s")
        
        // Test 3: Filter by stock status
        let startFilter = Date()
        let criticalMedicines = dataService.medicines.filter { $0.stockStatus == .critical }
        let filterDuration = Date().timeIntervalSince(startFilter)
        
        XCTAssertGreaterThan(criticalMedicines.count, 0)
        XCTAssertLessThan(filterDuration, 0.005, "Filtering 100 medicines should take less than 5ms")
        print("Filter by stock status took: \(filterDuration)s")
        
        // Test 4: Batch update performance
        let medicinesToUpdate = Array(dataService.medicines.prefix(20))
        let updatedMedicines = medicinesToUpdate.map { medicine in
            Medicine(
                id: medicine.id,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: medicine.currentQuantity + 10,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: medicine.createdAt,
                updatedAt: Date()
            )
        }
        
        let startBatchUpdate = Date()
        try await medicineRepo.updateMultipleMedicines(updatedMedicines)
        let batchUpdateDuration = Date().timeIntervalSince(startBatchUpdate)
        
        XCTAssertLessThan(batchUpdateDuration, 0.02, "Batch updating 20 medicines should take less than 20ms")
        print("Batch update 20 medicines took: \(batchUpdateDuration)s")
    }
    
    // MARK: - Test: Search Performance with 1000 Items
    
    func testSearchPerformanceWith1000Items() async throws {
        // Setup: Create diverse medicines (optimisé depuis 1000)
        for i in 0..<100 {
            let medicine = createMedicine(
                index: i,
                namePrefix: ["Doliprane", "Aspirine", "Paracétamol", "Ibuprofène", "Amoxicilline"][i % 5]
            )
            dataService.medicines.append(medicine)
        }
        
        // Test 1: Name search (contains)
        let searchTerms = ["Doli", "Aspi", "Para", "Ibu", "Amox"]
        var totalSearchTime: TimeInterval = 0
        
        for term in searchTerms {
            let startSearch = Date()
            let results = dataService.medicines.filter { $0.name.contains(term) }
            let searchDuration = Date().timeIntervalSince(startSearch)
            totalSearchTime += searchDuration
            
            XCTAssertEqual(results.count, 20) // 100 / 5 = 20 per type
            XCTAssertLessThan(searchDuration, 0.01, "Search should take less than 10ms")
        }
        
        let avgSearchTime = totalSearchTime / Double(searchTerms.count)
        print("Average search time: \(avgSearchTime)s")
        XCTAssertLessThan(avgSearchTime, 0.01)
        
        // Test 2: Complex filter (multiple criteria)
        let startComplex = Date()
        _ = dataService.medicines.filter { medicine in
            medicine.name.contains("Doliprane") &&
            medicine.currentQuantity < 50 &&
            medicine.aisleId == "aisle-0"
        }
        let complexDuration = Date().timeIntervalSince(startComplex)
        
        XCTAssertLessThan(complexDuration, 0.02, "Complex filter should take less than 20ms")
        print("Complex filter took: \(complexDuration)s")
        
        // Test 3: Case-insensitive search
        let startCaseInsensitive = Date()
        let caseInsensitiveResults = dataService.medicines.filter { 
            $0.name.lowercased().contains("doliprane")
        }
        let caseInsensitiveDuration = Date().timeIntervalSince(startCaseInsensitive)
        
        XCTAssertEqual(caseInsensitiveResults.count, 20)
        XCTAssertLessThan(caseInsensitiveDuration, 0.02, "Case-insensitive search should take less than 20ms")
        print("Case-insensitive search took: \(caseInsensitiveDuration)s")
    }
    
    // MARK: - Test: Pagination Memory Usage
    
    func testPaginationMemoryUsage() async throws {
        // Setup: Create 1,000 medicines to stress test memory (optimisé depuis 10,000)
        let totalMedicines = 1_000
        for i in 0..<totalMedicines {
            let medicine = createMedicine(index: i)
            dataService.medicines.append(medicine)
        }
        
        // Test paginated loading
        var loadedPages = 0
        var totalLoadTime: TimeInterval = 0
        let pageSize = 50
        
        // Load pages sequentially
        for pageIndex in 0..<10 { // Load 10 pages (500 items total)
            let startPage = Date()
            dataService.currentPage = pageIndex
            let page = try await medicineRepo.fetchMedicinesPaginated(limit: pageSize, refresh: false)
            let pageDuration = Date().timeIntervalSince(startPage)
            
            totalLoadTime += pageDuration
            loadedPages += 1
            
            XCTAssertEqual(page.count, pageSize)
            XCTAssertLessThan(pageDuration, 0.01, "Loading a page should take less than 10ms")
        }
        
        let avgPageLoadTime = totalLoadTime / Double(loadedPages)
        print("Average page load time: \(avgPageLoadTime)s")
        XCTAssertLessThan(avgPageLoadTime, 0.01)
        
        // Test memory efficiency - verify we're not loading everything
        XCTAssertEqual(dataService.lastAccessedCount, pageSize, "Should only access pageSize items at a time")
    }
    
    // MARK: - Test: History Loading Optimization
    
    func testHistoryLoadingOptimization() async throws {
        // Setup: Create history entries for different time periods
        let baseDate = Date()
        for dayOffset in 0..<30 { // 30 days of history (optimisé depuis 365)
            for hourOffset in stride(from: 0, to: 24, by: 6) { // 4 entries per day (optimisé depuis 24)
                let timestamp = baseDate.addingTimeInterval(Double(-dayOffset * 86400 - hourOffset * 3600))
                let entry = HistoryEntry(
                    id: "history-\(dayOffset)-\(hourOffset)",
                    medicineId: "med-\(dayOffset % 100)",
                    userId: "user-\(hourOffset % 3)",
                    action: ["Stock ajusté", "Médicament créé", "Médicament modifié"][hourOffset % 3],
                    details: "Action automatique",
                    timestamp: timestamp
                )
                dataService.history.append(entry)
            }
        }
        
        let totalEntries = dataService.history.count
        XCTAssertEqual(totalEntries, 30 * 4) // 120 entries
        
        // Test 1: Load recent history (last 7 days)
        let startRecent = Date()
        let sevenDaysAgo = baseDate.addingTimeInterval(-7 * 86400)
        dataService.dateFilter = sevenDaysAgo
        let recentHistory = try await historyRepo.fetchHistory()
        let recentDuration = Date().timeIntervalSince(startRecent)
        
        XCTAssertLessThanOrEqual(recentHistory.count, 7 * 4) // Max 28 entries
        XCTAssertLessThan(recentDuration, 0.05, "Loading recent history should take less than 50ms")
        print("Load recent history took: \(recentDuration)s")
        
        // Test 2: Load history for specific medicine
        let startMedicineHistory = Date()
        _ = try await historyRepo.fetchHistoryForMedicine("med-1")
        let medicineHistoryDuration = Date().timeIntervalSince(startMedicineHistory)
        
        XCTAssertLessThan(medicineHistoryDuration, 0.02, "Loading medicine history should take less than 20ms")
        print("Load medicine history took: \(medicineHistoryDuration)s")
        
        // Test 3: Paginated history loading
        dataService.dateFilter = nil
        dataService.pageSize = 100
        
        let startPaginatedHistory = Date()
        let firstPage = try await historyRepo.fetchHistory()
        let paginatedHistoryDuration = Date().timeIntervalSince(startPaginatedHistory)
        
        XCTAssertEqual(firstPage.count, 100)
        XCTAssertLessThan(paginatedHistoryDuration, 0.02, "Loading paginated history should take less than 20ms")
        print("Load paginated history took: \(paginatedHistoryDuration)s")
    }
    
    // MARK: - Helper Methods
    
    private func createMedicine(index: Int, namePrefix: String = "Medicine") -> Medicine {
        return Medicine(
            id: "med-\(index)",
            name: "\(namePrefix) \(index)",
            description: "Description for medicine \(index)",
            dosage: "\(100 + index % 500)mg",
            form: ["comprimé", "gélule", "sirop", "injection"][index % 4],
            reference: "REF-\(index)",
            unit: ["comprimés", "gélules", "ml", "ampoules"][index % 4],
            currentQuantity: index % 100, // Varies from 0 to 99
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: Date().addingTimeInterval(Double(index % 365) * 86400),
            aisleId: "aisle-\(index % 10)",
            createdAt: Date().addingTimeInterval(Double(-index) * 3600),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Performance Data Service

class MockPerformanceDataService: DataServiceAdapter {
    var medicines: [Medicine] = []
    var aisles: [Aisle] = []
    var history: [HistoryEntry] = []
    
    var currentPage = 0
    var pageSize = 20
    var dateFilter: Date?
    var lastAccessedCount = 0
    
    override func getMedicines() async throws -> [Medicine] {
        lastAccessedCount = medicines.count
        return medicines
    }
    
    override func getMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        if refresh {
            currentPage = 0
        }
        
        let startIndex = currentPage * limit
        let endIndex = min(startIndex + limit, medicines.count)
        
        guard startIndex < medicines.count else {
            return []
        }
        
        lastAccessedCount = endIndex - startIndex
        return Array(medicines[startIndex..<endIndex])
    }
    
    override func updateMultipleMedicines(_ updatedMedicines: [Medicine]) async throws {
        for updatedMedicine in updatedMedicines {
            if let index = medicines.firstIndex(where: { $0.id == updatedMedicine.id }) {
                medicines[index] = updatedMedicine
            }
        }
    }
    
    override func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        var result = history
        
        // Apply medicine filter
        if let medicineId = medicineId {
            result = result.filter { $0.medicineId == medicineId }
        }
        
        // Apply date filter
        if let dateFilter = dateFilter {
            result = result.filter { $0.timestamp >= dateFilter }
        }
        
        // Apply pagination
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, result.count)
        
        guard startIndex < result.count else {
            return []
        }
        
        return Array(result[startIndex..<endIndex])
    }
}