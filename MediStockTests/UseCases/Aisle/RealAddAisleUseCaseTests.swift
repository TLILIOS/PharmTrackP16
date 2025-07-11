import XCTest
@testable import MediStock
@MainActor
final class RealAddAisleUseCaseTests: XCTestCase {
    
    var mockAisleRepository: MockAisleRepository!
    var addAisleUseCase: RealAddAisleUseCase!
    
    override func setUp() {
        super.setUp()
        mockAisleRepository = MockAisleRepository()
        addAisleUseCase = RealAddAisleUseCase(aisleRepository: mockAisleRepository)
    }
    
    override func tearDown() {
        mockAisleRepository = nil
        addAisleUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        let aisle = Aisle(id: "aisle1", name: "Test Aisle", description: "Test Description", colorHex: "#FF0000", icon: "folder")
        mockAisleRepository.shouldThrowError = false
        
        try await addAisleUseCase.execute(aisle: aisle)
        
        XCTAssertEqual(mockAisleRepository.aisles.count, 1)
        XCTAssertEqual(mockAisleRepository.aisles.first?.id, "aisle1")
    }
    
    func testExecuteThrowsError() async {
        let aisle = Aisle(id: "aisle1", name: "Test Aisle", description: "Test Description", colorHex: "#FF0000", icon: "folder")
        mockAisleRepository.shouldThrowError = true
        
        do {
            try await addAisleUseCase.execute(aisle: aisle)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertTrue(mockAisleRepository.aisles.isEmpty)
        }
    }
    
    func testExecuteWithDifferentAisles() async throws {
        let aisles = [
            Aisle(id: "aisle1", name: "Aisle 1", description: "First aisle", colorHex: "#FF0000", icon: "folder"),
            Aisle(id: "aisle2", name: "Aisle 2", description: nil, colorHex: "#00FF00", icon: "star"),
            Aisle(id: "aisle3", name: "Aisle 3", description: "Third aisle", colorHex: "#0000FF", icon: "heart")
        ]
        
        for aisle in aisles {
            try await addAisleUseCase.execute(aisle: aisle)
        }
        
        XCTAssertEqual(mockAisleRepository.aisles.count, 3)
        XCTAssertEqual(mockAisleRepository.aisles[0].id, "aisle1")
        XCTAssertEqual(mockAisleRepository.aisles[1].id, "aisle2")
        XCTAssertEqual(mockAisleRepository.aisles[2].id, "aisle3")
    }
    
    func testInitialization() {
        XCTAssertNotNil(addAisleUseCase)
        XCTAssertTrue(addAisleUseCase is AddAisleUseCaseProtocol)
    }
    
    func testExecuteWithEmptyValues() async throws {
        let aisle = Aisle(id: "", name: "", description: "", colorHex: "", icon: "")
        mockAisleRepository.shouldThrowError = false
        
        try await addAisleUseCase.execute(aisle: aisle)
        
        XCTAssertEqual(mockAisleRepository.aisles.count, 1)
        XCTAssertEqual(mockAisleRepository.aisles.first?.name, "")
    }
    
    func testExecuteMultipleTimes() async throws {
        let aisle = Aisle(id: "aisle1", name: "Test Aisle", description: "Test Description", colorHex: "#FF0000", icon: "folder")
        
        for i in 0..<5 {
            var modifiedAisle = aisle
            modifiedAisle = Aisle(id: "aisle\(i)", name: aisle.name, description: aisle.description, colorHex: aisle.colorHex, icon: aisle.icon)
            try await addAisleUseCase.execute(aisle: modifiedAisle)
        }
        
        XCTAssertEqual(mockAisleRepository.aisles.count, 5)
    }
}
