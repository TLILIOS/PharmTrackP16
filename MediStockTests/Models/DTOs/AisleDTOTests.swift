import XCTest
@testable import MediStock

final class AisleDTOTests: XCTestCase {
    
    func testAisleDTOInitialization() {
        let aisleDTO = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        XCTAssertEqual(aisleDTO.id, "test-id")
        XCTAssertEqual(aisleDTO.name, "Test Aisle")
        XCTAssertEqual(aisleDTO.description, "Test Description")
        XCTAssertEqual(aisleDTO.colorHex, "#FF0000")
        XCTAssertEqual(aisleDTO.icon, "folder")
    }
    
    func testAisleDTOInitializationWithNilDescription() {
        let aisleDTO = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        XCTAssertEqual(aisleDTO.id, "test-id")
        XCTAssertEqual(aisleDTO.name, "Test Aisle")
        XCTAssertNil(aisleDTO.description)
        XCTAssertEqual(aisleDTO.colorHex, "#FF0000")
        XCTAssertEqual(aisleDTO.icon, "folder")
    }
    
    func testAisleDTOToDomain() {
        let aisleDTO = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        let aisle = aisleDTO.toDomain()
        
        XCTAssertEqual(aisle.id, "test-id")
        XCTAssertEqual(aisle.name, "Test Aisle")
        XCTAssertEqual(aisle.description, "Test Description")
        XCTAssertEqual(aisle.colorHex, "#FF0000")
        XCTAssertEqual(aisle.icon, "folder")
    }
    
    func testAisleDTOToDomainWithNilId() {
        let aisleDTO = AisleDTO(
            id: nil,
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        let aisle = aisleDTO.toDomain()
        
        XCTAssertNotNil(aisle.id)
        XCTAssertFalse(aisle.id.isEmpty)
        XCTAssertEqual(aisle.name, "Test Aisle")
        XCTAssertEqual(aisle.description, "Test Description")
        XCTAssertEqual(aisle.colorHex, "#FF0000")
        XCTAssertEqual(aisle.icon, "folder")
    }
    
    func testAisleDTOFromDomain() {
        let aisle = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        let aisleDTO = AisleDTO.fromDomain(aisle)
        
        XCTAssertEqual(aisleDTO.id, "test-id")
        XCTAssertEqual(aisleDTO.name, "Test Aisle")
        XCTAssertEqual(aisleDTO.description, "Test Description")
        XCTAssertEqual(aisleDTO.colorHex, "#FF0000")
        XCTAssertEqual(aisleDTO.icon, "folder")
    }
    
    func testAisleDTOFromDomainWithNilDescription() {
        let aisle = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        let aisleDTO = AisleDTO.fromDomain(aisle)
        
        XCTAssertEqual(aisleDTO.id, "test-id")
        XCTAssertEqual(aisleDTO.name, "Test Aisle")
        XCTAssertNil(aisleDTO.description)
        XCTAssertEqual(aisleDTO.colorHex, "#FF0000")
        XCTAssertEqual(aisleDTO.icon, "folder")
    }
    
    func testAisleDTORoundTripConversion() {
        let originalAisle = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        let aisleDTO = AisleDTO.fromDomain(originalAisle)
        let convertedAisle = aisleDTO.toDomain()
        
        XCTAssertEqual(originalAisle.id, convertedAisle.id)
        XCTAssertEqual(originalAisle.name, convertedAisle.name)
        XCTAssertEqual(originalAisle.description, convertedAisle.description)
        XCTAssertEqual(originalAisle.colorHex, convertedAisle.colorHex)
        XCTAssertEqual(originalAisle.icon, convertedAisle.icon)
    }
    
    func testAisleDTOProperties() {
        let aisleDTO = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "folder"
        )
        
        // Test DTO properties directly instead of JSON encoding/decoding
        // (Firestore DocumentID doesn't support standard JSON encoding)
        XCTAssertEqual(aisleDTO.id, "test-id")
        XCTAssertEqual(aisleDTO.name, "Test Aisle")
        XCTAssertEqual(aisleDTO.description, "Test Description")
        XCTAssertEqual(aisleDTO.colorHex, "#FF0000")
        XCTAssertEqual(aisleDTO.icon, "folder")
    }
    
    func testAisleDTOEmptyValues() {
        let aisleDTO = AisleDTO(
            id: "",
            name: "",
            description: "",
            colorHex: "",
            icon: ""
        )
        
        XCTAssertEqual(aisleDTO.id, "")
        XCTAssertEqual(aisleDTO.name, "")
        XCTAssertEqual(aisleDTO.description, "")
        XCTAssertEqual(aisleDTO.colorHex, "")
        XCTAssertEqual(aisleDTO.icon, "")
    }
}
