import XCTest
@testable import MediStock
@MainActor
final class MedicineTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testMedicineInitialization_AllFields() {
        // Given
        let id = "med-123"
        let name = "Test Medicine"
        let description = "Test Description"
        let dosage = "500mg"
        let form = "Tablet"
        let reference = "REF-001"
        let unit = "tablet"
        let currentQuantity = 50
        let maxQuantity = 100
        let warningThreshold = 20
        let criticalThreshold = 10
        let expiryDate = Date()
        let aisleId = "aisle-1"
        let createdAt = Date()
        let updatedAt = Date()
        
        // When
        let medicine = Medicine(
            id: id,
            name: name,
            description: description,
            dosage: dosage,
            form: form,
            reference: reference,
            unit: unit,
            currentQuantity: currentQuantity,
            maxQuantity: maxQuantity,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: expiryDate,
            aisleId: aisleId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Then
        XCTAssertEqual(medicine.id, id)
        XCTAssertEqual(medicine.name, name)
        XCTAssertEqual(medicine.description, description)
        XCTAssertEqual(medicine.dosage, dosage)
        XCTAssertEqual(medicine.form, form)
        XCTAssertEqual(medicine.reference, reference)
        XCTAssertEqual(medicine.unit, unit)
        XCTAssertEqual(medicine.currentQuantity, currentQuantity)
        XCTAssertEqual(medicine.maxQuantity, maxQuantity)
        XCTAssertEqual(medicine.warningThreshold, warningThreshold)
        XCTAssertEqual(medicine.criticalThreshold, criticalThreshold)
        XCTAssertEqual(medicine.expiryDate, expiryDate)
        XCTAssertEqual(medicine.aisleId, aisleId)
        XCTAssertEqual(medicine.createdAt, createdAt)
        XCTAssertEqual(medicine.updatedAt, updatedAt)
    }
    
    func testMedicineInitialization_NilExpiryDate() {
        // When - Create medicine directly with nil expiry date
        let medicine = Medicine(
            id: "test-medicine",
            name: "Test Medicine",
            description: "Test Description",
            dosage: "500mg",
            form: "Tablet",
            reference: "TEST-001",
            unit: "tablet",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: "test-aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNil(medicine.expiryDate)
    }
    
    // MARK: - Equatable Tests
    
    func testMedicineEquality_SameValues() {
        // Given
        let medicine1 = TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine A")
        let medicine2 = TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine A")
        
        // Then
        XCTAssertEqual(medicine1, medicine2)
    }
    
    func testMedicineEquality_DifferentIds() {
        // Given
        let medicine1 = TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine A")
        let medicine2 = TestDataFactory.createTestMedicine(id: "med-2", name: "Medicine A")
        
        // Then
        XCTAssertNotEqual(medicine1, medicine2)
    }
    
    func testMedicineEquality_DifferentNames() {
        // Given - Same ID, different names
        let medicine1 = TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine A")
        let medicine2 = TestDataFactory.createTestMedicine(id: "med-1", name: "Medicine B")
        
        // Then - Medicines with same ID are equal (based on Medicine's == implementation)
        XCTAssertEqual(medicine1, medicine2)
    }
    
    // MARK: - Identifiable Tests
    
    func testMedicineIdentifiable() {
        // Given
        let medicine = TestDataFactory.createTestMedicine(id: "test-id")
        
        // Then
        XCTAssertEqual(medicine.id, "test-id")
    }
    
    // MARK: - Codable Tests
    
    func testMedicineEncoding() throws {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            id: "med-123",
            name: "Test Medicine",
            description: "Test Description",
            dosage: "500mg",
            form: "Tablet"
        )
        
        // When
        let encoded = try JSONEncoder().encode(medicine)
        
        // Then
        XCTAssertNotNil(encoded)
        XCTAssertGreaterThan(encoded.count, 0)
    }
    
    func testMedicineDecoding() throws {
        // Given
        let originalMedicine = TestDataFactory.createTestMedicine(
            id: "med-123",
            name: "Test Medicine",
            description: "Test Description"
        )
        let encoded = try JSONEncoder().encode(originalMedicine)
        
        // When
        let decoded = try JSONDecoder().decode(Medicine.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalMedicine.id)
        XCTAssertEqual(decoded.name, originalMedicine.name)
        XCTAssertEqual(decoded.description, originalMedicine.description)
        XCTAssertEqual(decoded.dosage, originalMedicine.dosage)
        XCTAssertEqual(decoded.form, originalMedicine.form)
    }
    
    func testMedicineRoundTripCoding() throws {
        // Given
        let originalMedicine = TestDataFactory.createTestMedicine(
            name: "Original Medicine",
            currentQuantity: 75,
            maxQuantity: 150
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalMedicine)
        let decoded = try JSONDecoder().decode(Medicine.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded, originalMedicine)
    }
    
    // MARK: - Edge Cases Tests
    
    func testMedicineWithEmptyStrings() {
        // When
        let medicine = Medicine(
            id: "",
            name: "",
            description: "",
            dosage: "",
            form: "",
            reference: "",
            unit: "",
            currentQuantity: 0,
            maxQuantity: 0,
            warningThreshold: 0,
            criticalThreshold: 0,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(medicine.id, "")
        XCTAssertEqual(medicine.name, "")
        XCTAssertEqual(medicine.description, "")
        XCTAssertEqual(medicine.dosage, "")
        XCTAssertEqual(medicine.form, "")
        XCTAssertEqual(medicine.reference, "")
        XCTAssertEqual(medicine.unit, "")
        XCTAssertEqual(medicine.aisleId, "")
    }
    
    func testMedicineWithNegativeQuantities() {
        // When
        let medicine = TestDataFactory.createTestMedicine(
            currentQuantity: -10,
            maxQuantity: -5,
            warningThreshold: -20,
            criticalThreshold: -30
        )
        
        // Then
        XCTAssertEqual(medicine.currentQuantity, -10)
        XCTAssertEqual(medicine.maxQuantity, -5)
        XCTAssertEqual(medicine.warningThreshold, -20)
        XCTAssertEqual(medicine.criticalThreshold, -30)
    }
    
    func testMedicineWithVeryLargeQuantities() {
        // When
        let medicine = TestDataFactory.createTestMedicine(
            currentQuantity: Int.max,
            maxQuantity: Int.max,
            warningThreshold: Int.max,
            criticalThreshold: Int.max
        )
        
        // Then
        XCTAssertEqual(medicine.currentQuantity, Int.max)
        XCTAssertEqual(medicine.maxQuantity, Int.max)
        XCTAssertEqual(medicine.warningThreshold, Int.max)
        XCTAssertEqual(medicine.criticalThreshold, Int.max)
    }
    
    func testMedicineWithLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 10000)
        
        // When
        let medicine = TestDataFactory.createTestMedicine(
            name: longString,
            description: longString,
            dosage: longString
        )
        
        // Then
        XCTAssertEqual(medicine.name.count, 10000)
        XCTAssertEqual(medicine.description?.count, 10000)
        XCTAssertEqual(medicine.dosage?.count, 10000)
    }
    
    // MARK: - Date Handling Tests
    
    func testMedicineWithFutureExpiryDate() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        
        // When
        let medicine = TestDataFactory.createTestMedicine(expiryDate: futureDate)
        
        // Then
        XCTAssertEqual(medicine.expiryDate, futureDate)
    }
    
    func testMedicineWithPastExpiryDate() {
        // Given
        let pastDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        
        // When
        let medicine = TestDataFactory.createTestMedicine(expiryDate: pastDate)
        
        // Then
        XCTAssertEqual(medicine.expiryDate, pastDate)
    }
    
    func testMedicineTimestamps() {
        // Given & When
        let medicine = TestDataFactory.createTestMedicine()
        
        // Then
        XCTAssertNotNil(medicine.createdAt)
        XCTAssertNotNil(medicine.updatedAt)
        XCTAssertLessThanOrEqual(medicine.createdAt, medicine.updatedAt)
    }
    
    // MARK: - Special Characters Tests
    
    func testMedicineWithSpecialCharacters() {
        // When
        let medicine = TestDataFactory.createTestMedicine(
            name: "Medicine-A+B (500mg)",
            description: "Special chars: @#$%^&*()",
            dosage: "500mg/2ml",
            reference: "REF-001/A"
        )
        
        // Then
        XCTAssertEqual(medicine.name, "Medicine-A+B (500mg)")
        XCTAssertEqual(medicine.description, "Special chars: @#$%^&*()")
        XCTAssertEqual(medicine.dosage, "500mg/2ml")
        XCTAssertEqual(medicine.reference, "REF-001/A")
    }
    
    func testMedicineWithUnicodeCharacters() {
        // When
        let medicine = TestDataFactory.createTestMedicine(
            name: "Médecine française 🇫🇷",
            description: "Descripción en español 🇪🇸",
            dosage: "500mg 日本語"
        )
        
        // Then
        XCTAssertEqual(medicine.name, "Médecine française 🇫🇷")
        XCTAssertEqual(medicine.description, "Descripción en español 🇪🇸")
        XCTAssertEqual(medicine.dosage, "500mg 日本語")
    }
    
    // MARK: - Value Type Tests
    
    func testMedicineValueTypeSemantics() {
        // Given
        var medicine1 = TestDataFactory.createTestMedicine(currentQuantity: 50)
        var medicine2 = medicine1
        
        // When
        medicine2 = Medicine(
            id: medicine2.id,
            name: medicine2.name,
            description: medicine2.description,
            dosage: medicine2.dosage,
            form: medicine2.form,
            reference: medicine2.reference,
            unit: medicine2.unit,
            currentQuantity: 100,
            maxQuantity: medicine2.maxQuantity,
            warningThreshold: medicine2.warningThreshold,
            criticalThreshold: medicine2.criticalThreshold,
            expiryDate: medicine2.expiryDate,
            aisleId: medicine2.aisleId,
            createdAt: medicine2.createdAt,
            updatedAt: medicine2.updatedAt
        )
        
        // Then - Value types should not affect each other
        XCTAssertEqual(medicine1.currentQuantity, 50)
        XCTAssertEqual(medicine2.currentQuantity, 100)
    }
    
    // MARK: - Array and Collection Tests
    
    func testMedicineInArray() {
        // Given
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", name: "Medicine A"),
            TestDataFactory.createTestMedicine(id: "2", name: "Medicine B"),
            TestDataFactory.createTestMedicine(id: "3", name: "Medicine C")
        ]
        
        // When
        let medicineA = medicines.first { $0.name == "Medicine A" }
        let medicineB = medicines.first { $0.id == "2" }
        
        // Then
        XCTAssertNotNil(medicineA)
        XCTAssertEqual(medicineA?.name, "Medicine A")
        XCTAssertNotNil(medicineB)
        XCTAssertEqual(medicineB?.name, "Medicine B")
    }
    
    func testMedicineInSet() {
        // Given
        let medicine1 = TestDataFactory.createTestMedicine(id: "1", name: "Medicine A")
        let medicine2 = TestDataFactory.createTestMedicine(id: "2", name: "Medicine B")
        let medicine3 = TestDataFactory.createTestMedicine(id: "1", name: "Medicine A") // Same as medicine1
        
        // When
        let medicineSet: Set<Medicine> = [medicine1, medicine2, medicine3]
        
        // Then
        XCTAssertEqual(medicineSet.count, 2) // medicine3 should be the same as medicine1
        XCTAssertTrue(medicineSet.contains(medicine1))
        XCTAssertTrue(medicineSet.contains(medicine2))
    }
    
    // MARK: - Hashable Tests
    
    func testMedicineHashable() {
        // Given
        let medicine1 = TestDataFactory.createTestMedicine(id: "1", name: "Medicine A")
        let medicine2 = TestDataFactory.createTestMedicine(id: "1", name: "Medicine A")
        let medicine3 = TestDataFactory.createTestMedicine(id: "2", name: "Medicine B")
        
        // Then
        XCTAssertEqual(medicine1.hashValue, medicine2.hashValue)
        XCTAssertNotEqual(medicine1.hashValue, medicine3.hashValue)
    }
    
    // MARK: - Property Validation Tests
    
    func testMedicineQuantityRelationships() {
        // Given
        let medicine = TestDataFactory.createTestMedicine(
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 30,
            criticalThreshold: 10
        )
        
        // Then - Test typical expected relationships
        XCTAssertLessThanOrEqual(medicine.currentQuantity, medicine.maxQuantity)
        XCTAssertLessThan(medicine.criticalThreshold, medicine.warningThreshold)
        XCTAssertLessThan(medicine.warningThreshold, medicine.maxQuantity)
    }
    
    func testMedicineFieldTypes() {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        
        // Then - Verify field types
        XCTAssertTrue(medicine.id is String)
        XCTAssertTrue(medicine.name is String)
        XCTAssertTrue(medicine.description is String)
        XCTAssertTrue(medicine.dosage is String)
        XCTAssertTrue(medicine.form is String)
        XCTAssertTrue(medicine.reference is String)
        XCTAssertTrue(medicine.unit is String)
        XCTAssertTrue(medicine.currentQuantity is Int)
        XCTAssertTrue(medicine.maxQuantity is Int)
        XCTAssertTrue(medicine.warningThreshold is Int)
        XCTAssertTrue(medicine.criticalThreshold is Int)
        XCTAssertTrue(medicine.aisleId is String)
        XCTAssertTrue(medicine.createdAt is Date)
        XCTAssertTrue(medicine.updatedAt is Date)
    }
}
