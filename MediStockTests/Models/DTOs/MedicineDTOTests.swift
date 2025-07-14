import XCTest
@testable import MediStock

final class MedicineDTOTests: XCTestCase {
    
    let testCreatedDate = Date()
    let testUpdatedDate = Date()
    let testExpiryDate = Date().addingTimeInterval(86400 * 30) // 30 days from now
    
    func testMedicineDTOInitialization() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        XCTAssertEqual(medicineDTO.id, "medicine-123")
        XCTAssertEqual(medicineDTO.name, "Aspirin")
        XCTAssertEqual(medicineDTO.description, "Pain reliever")
        XCTAssertEqual(medicineDTO.dosage, "500mg")
        XCTAssertEqual(medicineDTO.form, "tablet")
        XCTAssertEqual(medicineDTO.reference, "ASP001")
        XCTAssertEqual(medicineDTO.unit, "tablets")
        XCTAssertEqual(medicineDTO.currentQuantity, 100)
        XCTAssertEqual(medicineDTO.maxQuantity, 500)
        XCTAssertEqual(medicineDTO.warningThreshold, 50)
        XCTAssertEqual(medicineDTO.criticalThreshold, 20)
        XCTAssertEqual(medicineDTO.expiryDate, testExpiryDate)
        XCTAssertEqual(medicineDTO.aisleId, "aisle-456")
        XCTAssertEqual(medicineDTO.createdAt, testCreatedDate)
        XCTAssertEqual(medicineDTO.updatedAt, testUpdatedDate)
    }
    
    func testMedicineDTOInitializationWithNilOptionalValues() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: nil,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        XCTAssertEqual(medicineDTO.id, "medicine-123")
        XCTAssertEqual(medicineDTO.name, "Aspirin")
        XCTAssertNil(medicineDTO.description)
        XCTAssertNil(medicineDTO.dosage)
        XCTAssertNil(medicineDTO.form)
        XCTAssertNil(medicineDTO.reference)
        XCTAssertNil(medicineDTO.expiryDate)
    }
    
    func testMedicineDTOLegacyCompatibility() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        XCTAssertEqual(medicineDTO.stock, 100)
        XCTAssertEqual(medicineDTO.aisle, "aisle-456")
        XCTAssertEqual(medicineDTO.stock, medicineDTO.currentQuantity)
        XCTAssertEqual(medicineDTO.aisle, medicineDTO.aisleId)
    }
    
    func testMedicineDTOToDomain() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        let medicine = medicineDTO.toDomain()
        
        XCTAssertEqual(medicine.id, "medicine-123")
        XCTAssertEqual(medicine.name, "Aspirin")
        XCTAssertEqual(medicine.description, "Pain reliever")
        XCTAssertEqual(medicine.dosage, "500mg")
        XCTAssertEqual(medicine.form, "tablet")
        XCTAssertEqual(medicine.reference, "ASP001")
        XCTAssertEqual(medicine.unit, "tablets")
        XCTAssertEqual(medicine.currentQuantity, 100)
        XCTAssertEqual(medicine.maxQuantity, 500)
        XCTAssertEqual(medicine.warningThreshold, 50)
        XCTAssertEqual(medicine.criticalThreshold, 20)
        XCTAssertEqual(medicine.expiryDate, testExpiryDate)
        XCTAssertEqual(medicine.aisleId, "aisle-456")
        XCTAssertEqual(medicine.createdAt, testCreatedDate)
        XCTAssertEqual(medicine.updatedAt, testUpdatedDate)
    }
    
    func testMedicineDTOToDomainWithNilId() {
        let medicineDTO = MedicineDTO(
            id: nil,
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        let medicine = medicineDTO.toDomain()
        
        XCTAssertNotNil(medicine.id)
        XCTAssertFalse(medicine.id.isEmpty)
        XCTAssertEqual(medicine.name, "Aspirin")
    }
    
    func testMedicineDTOFromDomain() {
        let medicine = Medicine(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        let medicineDTO = MedicineDTO.fromDomain(medicine)
        
        XCTAssertEqual(medicineDTO.id, "medicine-123")
        XCTAssertEqual(medicineDTO.name, "Aspirin")
        XCTAssertEqual(medicineDTO.description, "Pain reliever")
        XCTAssertEqual(medicineDTO.dosage, "500mg")
        XCTAssertEqual(medicineDTO.form, "tablet")
        XCTAssertEqual(medicineDTO.reference, "ASP001")
        XCTAssertEqual(medicineDTO.unit, "tablets")
        XCTAssertEqual(medicineDTO.currentQuantity, 100)
        XCTAssertEqual(medicineDTO.maxQuantity, 500)
        XCTAssertEqual(medicineDTO.warningThreshold, 50)
        XCTAssertEqual(medicineDTO.criticalThreshold, 20)
        XCTAssertEqual(medicineDTO.expiryDate, testExpiryDate)
        XCTAssertEqual(medicineDTO.aisleId, "aisle-456")
        XCTAssertEqual(medicineDTO.createdAt, testCreatedDate)
        XCTAssertEqual(medicineDTO.updatedAt, testUpdatedDate)
    }
    
    func testMedicineDTORoundTripConversion() {
        let originalMedicine = Medicine(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        let medicineDTO = MedicineDTO.fromDomain(originalMedicine)
        let convertedMedicine = medicineDTO.toDomain()
        
        XCTAssertEqual(originalMedicine.id, convertedMedicine.id)
        XCTAssertEqual(originalMedicine.name, convertedMedicine.name)
        XCTAssertEqual(originalMedicine.description, convertedMedicine.description)
        XCTAssertEqual(originalMedicine.dosage, convertedMedicine.dosage)
        XCTAssertEqual(originalMedicine.form, convertedMedicine.form)
        XCTAssertEqual(originalMedicine.reference, convertedMedicine.reference)
        XCTAssertEqual(originalMedicine.unit, convertedMedicine.unit)
        XCTAssertEqual(originalMedicine.currentQuantity, convertedMedicine.currentQuantity)
        XCTAssertEqual(originalMedicine.maxQuantity, convertedMedicine.maxQuantity)
        XCTAssertEqual(originalMedicine.warningThreshold, convertedMedicine.warningThreshold)
        XCTAssertEqual(originalMedicine.criticalThreshold, convertedMedicine.criticalThreshold)
        XCTAssertEqual(originalMedicine.expiryDate, convertedMedicine.expiryDate)
        XCTAssertEqual(originalMedicine.aisleId, convertedMedicine.aisleId)
        XCTAssertEqual(originalMedicine.createdAt, convertedMedicine.createdAt)
        XCTAssertEqual(originalMedicine.updatedAt, convertedMedicine.updatedAt)
    }
    
    func testMedicineDTOProperties() {
        // Test MedicineDTO properties directly since Firestore DocumentID cannot be JSON encoded
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        // Verify all properties are correctly set
        XCTAssertEqual(medicineDTO.id, "medicine-123")
        XCTAssertEqual(medicineDTO.name, "Aspirin")
        XCTAssertEqual(medicineDTO.description, "Pain reliever")
        XCTAssertEqual(medicineDTO.dosage, "500mg")
        XCTAssertEqual(medicineDTO.form, "tablet")
        XCTAssertEqual(medicineDTO.reference, "ASP001")
        XCTAssertEqual(medicineDTO.unit, "tablets")
        XCTAssertEqual(medicineDTO.currentQuantity, 100)
        XCTAssertEqual(medicineDTO.maxQuantity, 500)
        XCTAssertEqual(medicineDTO.warningThreshold, 50)
        XCTAssertEqual(medicineDTO.criticalThreshold, 20)
        XCTAssertEqual(medicineDTO.expiryDate, testExpiryDate)
        XCTAssertEqual(medicineDTO.aisleId, "aisle-456")
        XCTAssertEqual(medicineDTO.createdAt, testCreatedDate)
        XCTAssertEqual(medicineDTO.updatedAt, testUpdatedDate)
    }
    
    func testMedicineDTOZeroQuantities() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: 0,
            maxQuantity: 0,
            warningThreshold: 0,
            criticalThreshold: 0,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        XCTAssertEqual(medicineDTO.currentQuantity, 0)
        XCTAssertEqual(medicineDTO.maxQuantity, 0)
        XCTAssertEqual(medicineDTO.warningThreshold, 0)
        XCTAssertEqual(medicineDTO.criticalThreshold, 0)
        XCTAssertEqual(medicineDTO.stock, 0)
    }
    
    func testMedicineDTONegativeQuantities() {
        let medicineDTO = MedicineDTO(
            id: "medicine-123",
            name: "Aspirin",
            description: "Pain reliever",
            dosage: "500mg",
            form: "tablet",
            reference: "ASP001",
            unit: "tablets",
            currentQuantity: -10,
            maxQuantity: -5,
            warningThreshold: -3,
            criticalThreshold: -1,
            expiryDate: testExpiryDate,
            aisleId: "aisle-456",
            createdAt: testCreatedDate,
            updatedAt: testUpdatedDate
        )
        
        XCTAssertEqual(medicineDTO.currentQuantity, -10)
        XCTAssertEqual(medicineDTO.maxQuantity, -5)
        XCTAssertEqual(medicineDTO.warningThreshold, -3)
        XCTAssertEqual(medicineDTO.criticalThreshold, -1)
        XCTAssertEqual(medicineDTO.stock, -10)
    }
}
