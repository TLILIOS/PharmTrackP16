import XCTest
import Foundation
@testable import MediStock

@MainActor
final class MedicineRepositoryUnitTests: XCTestCase, Sendable {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Medicine Model Tests
    
    func testMedicineInitialization() {
        // Given
        let id = "test-medicine-id"
        let name = "Test Medicine"
        let aisleId = "test-aisle-id"
        let expirationDate = Date().addingTimeInterval(86400 * 30) // 30 days
        let quantity = 10
        let minQuantity = 5
        let description = "Test Description"
        
        // When
        let medicine = Medicine(
            id: id,
            name: name,
            aisleId: aisleId,
            expirationDate: expirationDate,
            quantity: quantity,
            minQuantity: minQuantity,
            description: description
        )
        
        // Then
        XCTAssertEqual(medicine.id, id)
        XCTAssertEqual(medicine.name, name)
        XCTAssertEqual(medicine.aisleId, aisleId)
        XCTAssertEqual(medicine.expirationDate, expirationDate)
        XCTAssertEqual(medicine.quantity, quantity)
        XCTAssertEqual(medicine.minQuantity, minQuantity)
        XCTAssertEqual(medicine.description, description)
    }
    
    func testMedicineWithOptionalDescription() {
        // Given
        let medicine = Medicine(
            id: "test-id",
            name: "Test Medicine",
            aisleId: "aisle-id",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: nil
        )
        
        // Then
        XCTAssertNil(medicine.description)
        XCTAssertEqual(medicine.name, "Test Medicine")
    }
    
    func testMedicineEquality() {
        // Given
        let date = Date()
        let medicine1 = Medicine(id: "1", name: "Medicine 1", aisleId: "aisle1", expirationDate: date, quantity: 10, minQuantity: 5, description: "Test")
        let medicine2 = Medicine(id: "1", name: "Medicine 1", aisleId: "aisle1", expirationDate: date, quantity: 10, minQuantity: 5, description: "Test")
        let medicine3 = Medicine(id: "2", name: "Medicine 2", aisleId: "aisle2", expirationDate: date, quantity: 20, minQuantity: 10, description: "Test")
        
        // Then
        XCTAssertEqual(medicine1, medicine2)
        XCTAssertNotEqual(medicine1, medicine3)
    }
    
    // MARK: - MedicineDTO Model Tests
    
    func testMedicineDTOInitialization() {
        // Given
        let dto = MedicineDTO(
            id: "test-id",
            name: "Test Medicine",
            aisleId: "aisle-id",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
        
        // Then
        XCTAssertEqual(dto.id, "test-id")
        XCTAssertEqual(dto.name, "Test Medicine")
        XCTAssertEqual(dto.aisleId, "aisle-id")
        XCTAssertEqual(dto.quantity, 10)
        XCTAssertEqual(dto.minQuantity, 5)
        XCTAssertEqual(dto.description, "Test Description")
    }
    
    func testMedicineDTOToDomainConversion() {
        // Given
        let date = Date()
        let dto = MedicineDTO(
            id: "test-id",
            name: "Test Medicine",
            aisleId: "aisle-id",
            expirationDate: date,
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
        
        // When
        let domainModel = dto.toDomain()
        
        // Then
        XCTAssertEqual(domainModel.id, dto.id)
        XCTAssertEqual(domainModel.name, dto.name)
        XCTAssertEqual(domainModel.aisleId, dto.aisleId)
        XCTAssertEqual(domainModel.expirationDate, dto.expirationDate)
        XCTAssertEqual(domainModel.quantity, dto.quantity)
        XCTAssertEqual(domainModel.minQuantity, dto.minQuantity)
        XCTAssertEqual(domainModel.description, dto.description)
    }
    
    func testMedicineDTOFromDomainConversion() {
        // Given
        let date = Date()
        let domainModel = Medicine(
            id: "test-id",
            name: "Test Medicine",
            aisleId: "aisle-id",
            expirationDate: date,
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
        
        // When
        let dto = MedicineDTO.fromDomain(domainModel)
        
        // Then
        XCTAssertEqual(dto.id, domainModel.id)
        XCTAssertEqual(dto.name, domainModel.name)
        XCTAssertEqual(dto.aisleId, domainModel.aisleId)
        XCTAssertEqual(dto.expirationDate, domainModel.expirationDate)
        XCTAssertEqual(dto.quantity, domainModel.quantity)
        XCTAssertEqual(dto.minQuantity, domainModel.minQuantity)
        XCTAssertEqual(dto.description, domainModel.description)
    }
    
    func testMedicineDTORoundTripConversion() {
        // Given
        let originalMedicine = Medicine(
            id: "test-id",
            name: "Test Medicine",
            aisleId: "aisle-id",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
        
        // When
        let dto = MedicineDTO.fromDomain(originalMedicine)
        let convertedBack = dto.toDomain()
        
        // Then
        XCTAssertEqual(originalMedicine, convertedBack)
    }
    
    // MARK: - Medicine Business Logic Tests
    
    func testMedicineIsExpired() {
        // Given
        let expiredMedicine = Medicine(
            id: "expired",
            name: "Expired Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(-86400), // Yesterday
            quantity: 10,
            minQuantity: 5,
            description: "Expired"
        )
        
        let validMedicine = Medicine(
            id: "valid",
            name: "Valid Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400), // Tomorrow
            quantity: 10,
            minQuantity: 5,
            description: "Valid"
        )
        
        // Then
        XCTAssertTrue(isMedicineExpired(expiredMedicine))
        XCTAssertFalse(isMedicineExpired(validMedicine))
    }
    
    func testMedicineIsLowStock() {
        // Given
        let lowStockMedicine = Medicine(
            id: "low",
            name: "Low Stock Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400),
            quantity: 3,
            minQuantity: 5,
            description: "Low stock"
        )
        
        let normalStockMedicine = Medicine(
            id: "normal",
            name: "Normal Stock Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400),
            quantity: 10,
            minQuantity: 5,
            description: "Normal stock"
        )
        
        // Then
        XCTAssertTrue(isMedicineLowStock(lowStockMedicine))
        XCTAssertFalse(isMedicineLowStock(normalStockMedicine))
    }
    
    func testMedicineIsOutOfStock() {
        // Given
        let outOfStockMedicine = Medicine(
            id: "out",
            name: "Out of Stock Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400),
            quantity: 0,
            minQuantity: 5,
            description: "Out of stock"
        )
        
        let inStockMedicine = Medicine(
            id: "in",
            name: "In Stock Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400),
            quantity: 10,
            minQuantity: 5,
            description: "In stock"
        )
        
        // Then
        XCTAssertTrue(isMedicineOutOfStock(outOfStockMedicine))
        XCTAssertFalse(isMedicineOutOfStock(inStockMedicine))
    }
    
    func testMedicineExpiresWithinDays() {
        // Given
        let expiringMedicine = Medicine(
            id: "expiring",
            name: "Expiring Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400 * 3), // 3 days
            quantity: 10,
            minQuantity: 5,
            description: "Expiring soon"
        )
        
        let notExpiringMedicine = Medicine(
            id: "not-expiring",
            name: "Not Expiring Medicine",
            aisleId: "aisle1",
            expirationDate: Date().addingTimeInterval(86400 * 30), // 30 days
            quantity: 10,
            minQuantity: 5,
            description: "Not expiring soon"
        )
        
        // Then
        XCTAssertTrue(medicineExpiresWithinDays(expiringMedicine, days: 7))
        XCTAssertFalse(medicineExpiresWithinDays(notExpiringMedicine, days: 7))
    }
    
    // MARK: - Medicine Search Logic Tests
    
    func testMedicineSearchByName() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Aspirin", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Pain reliever"),
            Medicine(id: "2", name: "Ibuprofen", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Anti-inflammatory"),
            Medicine(id: "3", name: "Aspirin Plus", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Enhanced pain relief")
        ]
        
        // When
        let results = searchMedicines(medicines, query: "Aspirin")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Aspirin") })
    }
    
    func testMedicineSearchByDescription() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Medicine A", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Pain reliever"),
            Medicine(id: "2", name: "Medicine B", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Anti-inflammatory"),
            Medicine(id: "3", name: "Medicine C", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Pain management")
        ]
        
        // When
        let results = searchMedicines(medicines, query: "Pain")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.description?.contains("Pain") == true })
    }
    
    func testMedicineSearchCaseInsensitive() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "AsPiRiN", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let results = searchMedicines(medicines, query: "aspirin")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "AsPiRiN")
    }
    
    func testMedicineSearchWithEmptyQuery() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Medicine 1", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Medicine 2", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let results = searchMedicines(medicines, query: "")
        
        // Then
        XCTAssertEqual(results.count, medicines.count)
    }
    
    // MARK: - Medicine Filtering Logic Tests
    
    func testFilterExpiredMedicines() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Expired", aisleId: "aisle1", expirationDate: Date().addingTimeInterval(-86400), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Valid", aisleId: "aisle1", expirationDate: Date().addingTimeInterval(86400), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "3", name: "Also Expired", aisleId: "aisle1", expirationDate: Date().addingTimeInterval(-172800), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let expiredMedicines = filterExpiredMedicines(medicines)
        
        // Then
        XCTAssertEqual(expiredMedicines.count, 2)
        XCTAssertTrue(expiredMedicines.allSatisfy { isMedicineExpired($0) })
    }
    
    func testFilterLowStockMedicines() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Low Stock", aisleId: "aisle1", expirationDate: Date(), quantity: 3, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Normal Stock", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "3", name: "Also Low", aisleId: "aisle1", expirationDate: Date(), quantity: 1, minQuantity: 5, description: "Test")
        ]
        
        // When
        let lowStockMedicines = filterLowStockMedicines(medicines)
        
        // Then
        XCTAssertEqual(lowStockMedicines.count, 2)
        XCTAssertTrue(lowStockMedicines.allSatisfy { isMedicineLowStock($0) })
    }
    
    func testFilterMedicinesByAisle() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Medicine 1", aisleId: "aisle-A", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Medicine 2", aisleId: "aisle-B", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "3", name: "Medicine 3", aisleId: "aisle-A", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let aisleAMedicines = filterMedicinesByAisle(medicines, aisleId: "aisle-A")
        
        // Then
        XCTAssertEqual(aisleAMedicines.count, 2)
        XCTAssertTrue(aisleAMedicines.allSatisfy { $0.aisleId == "aisle-A" })
    }
    
    // MARK: - Medicine Sorting Logic Tests
    
    func testSortMedicinesByName() {
        // Given
        let medicines = [
            Medicine(id: "3", name: "Zebra Medicine", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "1", name: "Alpha Medicine", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Beta Medicine", aisleId: "aisle1", expirationDate: Date(), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let sorted = sortMedicinesByName(medicines)
        
        // Then
        XCTAssertEqual(sorted[0].name, "Alpha Medicine")
        XCTAssertEqual(sorted[1].name, "Beta Medicine")
        XCTAssertEqual(sorted[2].name, "Zebra Medicine")
    }
    
    func testSortMedicinesByExpirationDate() {
        // Given
        let baseDate = Date()
        let medicines = [
            Medicine(id: "1", name: "Medicine 1", aisleId: "aisle1", expirationDate: baseDate.addingTimeInterval(86400 * 30), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Medicine 2", aisleId: "aisle1", expirationDate: baseDate.addingTimeInterval(86400 * 10), quantity: 10, minQuantity: 5, description: "Test"),
            Medicine(id: "3", name: "Medicine 3", aisleId: "aisle1", expirationDate: baseDate.addingTimeInterval(86400 * 20), quantity: 10, minQuantity: 5, description: "Test")
        ]
        
        // When
        let sorted = sortMedicinesByExpirationDate(medicines)
        
        // Then
        XCTAssertEqual(sorted[0].id, "2") // Expires first (10 days)
        XCTAssertEqual(sorted[1].id, "3") // Expires second (20 days)
        XCTAssertEqual(sorted[2].id, "1") // Expires last (30 days)
    }
    
    func testSortMedicinesByQuantity() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Medicine 1", aisleId: "aisle1", expirationDate: Date(), quantity: 20, minQuantity: 5, description: "Test"),
            Medicine(id: "2", name: "Medicine 2", aisleId: "aisle1", expirationDate: Date(), quantity: 5, minQuantity: 5, description: "Test"),
            Medicine(id: "3", name: "Medicine 3", aisleId: "aisle1", expirationDate: Date(), quantity: 15, minQuantity: 5, description: "Test")
        ]
        
        // When
        let sorted = sortMedicinesByQuantity(medicines)
        
        // Then
        XCTAssertEqual(sorted[0].quantity, 5)  // Lowest quantity
        XCTAssertEqual(sorted[1].quantity, 15) // Middle quantity
        XCTAssertEqual(sorted[2].quantity, 20) // Highest quantity
    }
    
    // MARK: - Stock Operations Tests
    
    func testUpdateMedicineStock() {
        // Given
        let originalMedicine = Medicine(
            id: "test",
            name: "Test Medicine",
            aisleId: "aisle1",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test"
        )
        
        // When
        let updatedMedicine = updateMedicineStock(originalMedicine, newQuantity: 25)
        
        // Then
        XCTAssertEqual(updatedMedicine.quantity, 25)
        XCTAssertEqual(updatedMedicine.id, originalMedicine.id)
        XCTAssertEqual(updatedMedicine.name, originalMedicine.name)
        // Other properties should remain unchanged
    }
    
    func testAdjustMedicineStock() {
        // Given
        let medicine = Medicine(
            id: "test",
            name: "Test Medicine",
            aisleId: "aisle1",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test"
        )
        
        // When - Add stock
        let increasedStock = adjustMedicineStock(medicine, adjustment: 5)
        
        // Then
        XCTAssertEqual(increasedStock.quantity, 15)
        
        // When - Remove stock
        let decreasedStock = adjustMedicineStock(medicine, adjustment: -3)
        
        // Then
        XCTAssertEqual(decreasedStock.quantity, 7)
    }
    
    func testAdjustMedicineStockWithNegativeResult() {
        // Given
        let medicine = Medicine(
            id: "test",
            name: "Test Medicine",
            aisleId: "aisle1",
            expirationDate: Date(),
            quantity: 5,
            minQuantity: 5,
            description: "Test"
        )
        
        // When - Remove more than available
        let result = adjustMedicineStock(medicine, adjustment: -10)
        
        // Then - Should allow negative (business logic can handle this)
        XCTAssertEqual(result.quantity, -5)
    }
    
    // MARK: - Performance Tests
    
    func testMedicineSearchPerformance() {
        // Given
        let medicines = (0..<1000).map { i in
            Medicine(
                id: "\(i)",
                name: "Medicine \(i)",
                aisleId: "aisle1",
                expirationDate: Date(),
                quantity: 10,
                minQuantity: 5,
                description: "Description \(i)"
            )
        }
        
        measure {
            _ = searchMedicines(medicines, query: "500")
        }
    }
    
    func testMedicineSortingPerformance() {
        // Given
        let medicines = (0..<1000).map { i in
            Medicine(
                id: "\(i)",
                name: "Medicine \(999 - i)",
                aisleId: "aisle1",
                expirationDate: Date().addingTimeInterval(Double(i) * 86400),
                quantity: 1000 - i,
                minQuantity: 5,
                description: "Test"
            )
        }
        
        measure {
            _ = sortMedicinesByName(medicines)
            _ = sortMedicinesByExpirationDate(medicines)
            _ = sortMedicinesByQuantity(medicines)
        }
    }
    
    // MARK: - Data Validation Tests
    
    func testMedicineNameValidation() {
        let validNames = [
            "Aspirin",
            "Ibuprofen 200mg",
            "Medicine-123",
            "A" // single character
        ]
        
        for name in validNames {
            XCTAssertTrue(isValidMedicineName(name), "Name '\(name)' should be valid")
        }
        
        let invalidNames = [
            "",
            " ", // just space
            "   ", // multiple spaces
            String(repeating: "a", count: 1000) // too long
        ]
        
        for name in invalidNames {
            XCTAssertFalse(isValidMedicineName(name), "Name '\(name)' should be invalid")
        }
    }
    
    func testQuantityValidation() {
        XCTAssertTrue(isValidQuantity(0))
        XCTAssertTrue(isValidQuantity(1))
        XCTAssertTrue(isValidQuantity(1000))
        XCTAssertTrue(isValidQuantity(999999))
        
        XCTAssertFalse(isValidQuantity(-1))
        XCTAssertFalse(isValidQuantity(-100))
    }
    
    // MARK: - Edge Cases
    
    func testMedicineWithVeryLongName() {
        let longName = String(repeating: "A", count: 10000)
        let medicine = Medicine(
            id: "test",
            name: longName,
            aisleId: "aisle1",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test"
        )
        
        XCTAssertEqual(medicine.name, longName)
        XCTAssertNoThrow({
            _ = searchMedicines([medicine], query: "A")
        }())
    }
    
    func testMedicineWithUnicodeCharacters() {
        let unicodeName = "Médïçïné Tëst"
        let medicine = Medicine(
            id: "test",
            name: unicodeName,
            aisleId: "aisle1",
            expirationDate: Date(),
            quantity: 10,
            minQuantity: 5,
            description: "Test"
        )
        
        XCTAssertEqual(medicine.name, unicodeName)
        XCTAssertNoThrow({
            _ = searchMedicines([medicine], query: "Médïçïné")
        }())
    }
}

// MARK: - Helper Functions (Pure Logic)

private func isMedicineExpired(_ medicine: Medicine) -> Bool {
    return medicine.expirationDate < Date()
}

private func isMedicineLowStock(_ medicine: Medicine) -> Bool {
    return medicine.quantity < medicine.minQuantity
}

private func isMedicineOutOfStock(_ medicine: Medicine) -> Bool {
    return medicine.quantity <= 0
}

private func medicineExpiresWithinDays(_ medicine: Medicine, days: Int) -> Bool {
    let targetDate = Date().addingTimeInterval(TimeInterval(days * 86400))
    return medicine.expirationDate <= targetDate
}

private func searchMedicines(_ medicines: [Medicine], query: String) -> [Medicine] {
    if query.isEmpty {
        return medicines
    }
    
    let lowercaseQuery = query.lowercased()
    return medicines.filter { medicine in
        medicine.name.lowercased().contains(lowercaseQuery) ||
        (medicine.description?.lowercased().contains(lowercaseQuery) ?? false)
    }
}

private func filterExpiredMedicines(_ medicines: [Medicine]) -> [Medicine] {
    return medicines.filter { isMedicineExpired($0) }
}

private func filterLowStockMedicines(_ medicines: [Medicine]) -> [Medicine] {
    return medicines.filter { isMedicineLowStock($0) }
}

private func filterMedicinesByAisle(_ medicines: [Medicine], aisleId: String) -> [Medicine] {
    return medicines.filter { $0.aisleId == aisleId }
}

private func sortMedicinesByName(_ medicines: [Medicine]) -> [Medicine] {
    return medicines.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

private func sortMedicinesByExpirationDate(_ medicines: [Medicine]) -> [Medicine] {
    return medicines.sorted { $0.expirationDate < $1.expirationDate }
}

private func sortMedicinesByQuantity(_ medicines: [Medicine]) -> [Medicine] {
    return medicines.sorted { $0.quantity < $1.quantity }
}

private func updateMedicineStock(_ medicine: Medicine, newQuantity: Int) -> Medicine {
    return Medicine(
        id: medicine.id,
        name: medicine.name,
        aisleId: medicine.aisleId,
        expirationDate: medicine.expirationDate,
        quantity: newQuantity,
        minQuantity: medicine.minQuantity,
        description: medicine.description
    )
}

private func adjustMedicineStock(_ medicine: Medicine, adjustment: Int) -> Medicine {
    return updateMedicineStock(medicine, newQuantity: medicine.quantity + adjustment)
}

private func isValidMedicineName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && trimmed.count <= 255
}

private func isValidQuantity(_ quantity: Int) -> Bool {
    return quantity >= 0
}