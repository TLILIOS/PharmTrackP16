import XCTest
@testable import MediStock
@MainActor
final class RealAddMedicineUseCaseExtraTests: XCTestCase {
    
    var mockMedicineRepository: MockMedicineRepository!
    var mockHistoryRepository: MockHistoryRepository!
    var addMedicineUseCase: RealAddMedicineUseCase!
    
    override func setUp() {
        super.setUp()
        mockMedicineRepository = MockMedicineRepository()
        mockHistoryRepository = MockHistoryRepository()
        addMedicineUseCase = RealAddMedicineUseCase(medicineRepository: mockMedicineRepository, historyRepository: mockHistoryRepository)
    }
    
    override func tearDown() {
        mockMedicineRepository = nil
        mockHistoryRepository = nil
        addMedicineUseCase = nil
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
        
        try await addMedicineUseCase.execute(medicine: medicine)
        
        XCTAssertEqual(mockMedicineRepository.medicines.count, 1)
        XCTAssertEqual(mockMedicineRepository.medicines.first?.id, "med1")
    }
    
    func testExecuteThrowsError() async {
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
        
        mockMedicineRepository.shouldThrowError = true
        
        do {
            try await addMedicineUseCase.execute(medicine: medicine)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertTrue(mockMedicineRepository.medicines.isEmpty)
        }
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
        
        try await addMedicineUseCase.execute(medicine: medicine)
        
        XCTAssertEqual(mockMedicineRepository.medicines.count, 1)
        XCTAssertEqual(mockMedicineRepository.medicines.first?.name, "")
    }
    
    func testExecuteWithMultipleMedicines() async throws {
        let medicines = [
            Medicine(id: "med1", name: "Medicine 1", description: nil, dosage: nil, form: nil, reference: nil, unit: "units", currentQuantity: 10, maxQuantity: 100, warningThreshold: 5, criticalThreshold: 2, expiryDate: nil, aisleId: "aisle1", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "med2", name: "Medicine 2", description: nil, dosage: nil, form: nil, reference: nil, unit: "units", currentQuantity: 20, maxQuantity: 200, warningThreshold: 10, criticalThreshold: 5, expiryDate: nil, aisleId: "aisle2", createdAt: Date(), updatedAt: Date()),
            Medicine(id: "med3", name: "Medicine 3", description: nil, dosage: nil, form: nil, reference: nil, unit: "units", currentQuantity: 30, maxQuantity: 300, warningThreshold: 15, criticalThreshold: 8, expiryDate: nil, aisleId: "aisle3", createdAt: Date(), updatedAt: Date())
        ]
        
        for medicine in medicines {
            try await addMedicineUseCase.execute(medicine: medicine)
        }
        
        XCTAssertEqual(mockMedicineRepository.medicines.count, 3)
        XCTAssertEqual(mockMedicineRepository.medicines[0].id, "med1")
        XCTAssertEqual(mockMedicineRepository.medicines[1].id, "med2")
        XCTAssertEqual(mockMedicineRepository.medicines[2].id, "med3")
    }
    
    func testInitialization() {
        XCTAssertNotNil(addMedicineUseCase)
        XCTAssertTrue(addMedicineUseCase != nil)
    }
}
