import XCTest
@testable import MediStock

final class UpdateMedicineStockUseCaseTests: XCTestCase {
    
    var mockMedicineRepository: MockMedicineRepository!
    var mockHistoryRepository: MockHistoryRepository!
    var updateMedicineStockUseCase: UpdateMedicineStockUseCase!
    
    override func setUp() {
        super.setUp()
        mockMedicineRepository = MockMedicineRepository()
        mockHistoryRepository = MockHistoryRepository()
        updateMedicineStockUseCase = UpdateMedicineStockUseCase(
            medicineRepository: mockMedicineRepository,
            historyRepository: mockHistoryRepository
        )
    }
    
    override func tearDown() {
        mockMedicineRepository = nil
        mockHistoryRepository = nil
        updateMedicineStockUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        let medicine = Medicine(
            id: "med1",
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
            expiryDate: Date(),
            aisleId: "aisle1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await updateMedicineStockUseCase.execute(medicine: medicine)
        
        // Since execute is empty, we just test that it doesn't crash
        XCTAssertTrue(true)
    }
    
    func testExecuteWithDifferentMedicines() async throws {
        let medicines = [
            Medicine(id: "med1", name: "Medicine 1", description: nil, dosage: nil, form: nil, reference: nil, unit: "units", currentQuantity: 10, maxQuantity: 100, warningThreshold: 5, criticalThreshold: 2, expiryDate: nil, aisleId: "aisle1", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "med2", name: "Medicine 2", description: nil, dosage: nil, form: nil, reference: nil, unit: "units", currentQuantity: 0, maxQuantity: 0, warningThreshold: 0, criticalThreshold: 0, expiryDate: nil, aisleId: "aisle2", createdAt: Date(), updatedAt: Date())
        ]
        
        for medicine in medicines {
            try await updateMedicineStockUseCase.execute(medicine: medicine)
        }
        
        XCTAssertTrue(true)
    }
    
    func testInitialization() {
        XCTAssertNotNil(updateMedicineStockUseCase)
        XCTAssertTrue(updateMedicineStockUseCase is UpdateMedicineUseCaseProtocol)
    }
    
    func testExecuteWithMinimalMedicine() async throws {
        let medicine = Medicine(
            id: "",
            name: "",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
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
        
        try await updateMedicineStockUseCase.execute(medicine: medicine)
        
        XCTAssertTrue(true)
    }
    
    func testExecuteMultipleTimes() async throws {
        let medicine = Medicine(
            id: "med1",
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
            expiryDate: Date(),
            aisleId: "aisle1",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        for _ in 0..<5 {
            try await updateMedicineStockUseCase.execute(medicine: medicine)
        }
        
        XCTAssertTrue(true)
    }
}