import XCTest
@testable import MediStock

final class RealGetAislesUseCaseTests: XCTestCase {
    
    var mockAisleRepository: MockAisleRepository!
    var getAislesUseCase: RealGetAislesUseCase!
    
    override func setUp() {
        super.setUp()
        mockAisleRepository = MockAisleRepository()
        getAislesUseCase = RealGetAislesUseCase(aisleRepository: mockAisleRepository)
    }
    
    override func tearDown() {
        mockAisleRepository = nil
        getAislesUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        let expectedAisles = [
            Aisle(id: "1", name: "Aisle 1", description: "First aisle", colorHex: "#FF0000", icon: "folder"),
            Aisle(id: "2", name: "Aisle 2", description: "Second aisle", colorHex: "#00FF00", icon: "star")
        ]
        mockAisleRepository.aisles = expectedAisles
        
        let result = try await getAislesUseCase.execute()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[1].id, "2")
    }
    
    func testExecuteEmptyResult() async throws {
        mockAisleRepository.aisles = []
        
        let result = try await getAislesUseCase.execute()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecuteThrowsError() async {
        mockAisleRepository.shouldThrowError = true
        
        do {
            _ = try await getAislesUseCase.execute()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testInitialization() {
        XCTAssertNotNil(getAislesUseCase)
        XCTAssertTrue(getAislesUseCase is GetAislesUseCaseProtocol)
    }
    
    func testExecuteMultipleTimes() async throws {
        let aisles = [
            Aisle(id: "1", name: "Aisle 1", description: "First aisle", colorHex: "#FF0000", icon: "folder")
        ]
        mockAisleRepository.aisles = aisles
        
        for _ in 0..<3 {
            let result = try await getAislesUseCase.execute()
            XCTAssertEqual(result.count, 1)
        }
    }
    
    func testExecuteWithLargeDataset() async throws {
        let largeAisles = (1...100).map { index in
            Aisle(
                id: "\(index)",
                name: "Aisle \(index)",
                description: "Description for aisle \(index)",
                colorHex: "#FF0000",
                icon: "folder"
            )
        }
        mockAisleRepository.aisles = largeAisles
        
        let result = try await getAislesUseCase.execute()
        
        XCTAssertEqual(result.count, 100)
        XCTAssertEqual(result.first?.id, "1")
        XCTAssertEqual(result.last?.id, "100")
    }
    
    func testExecuteWithDifferentAisleProperties() async throws {
        let aisles = [
            Aisle(id: "1", name: "Regular Aisle", description: "Normal aisle", colorHex: "#FF0000", icon: "folder"),
            Aisle(id: "2", name: "", description: nil, colorHex: "#00FF00", icon: ""),
            Aisle(id: "3", name: "Special Characters!@#", description: "Has special chars", colorHex: "#0000FF", icon: "star"),
            Aisle(id: "4", name: "Very Long Name That Goes On And On", description: "Very long description that contains a lot of text to test how the system handles lengthy content", colorHex: "#FFFF00", icon: "heart")
        ]
        mockAisleRepository.aisles = aisles
        
        let result = try await getAislesUseCase.execute()
        
        XCTAssertEqual(result.count, 4)
        XCTAssertEqual(result[0].name, "Regular Aisle")
        XCTAssertEqual(result[1].name, "")
        XCTAssertEqual(result[2].name, "Special Characters!@#")
        XCTAssertEqual(result[3].name, "Very Long Name That Goes On And On")
    }
}