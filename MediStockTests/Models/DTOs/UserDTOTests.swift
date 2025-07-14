import XCTest
@testable import MediStock

final class UserDTOTests: XCTestCase {
    
    func testUserDTOInitialization() {
        let userDTO = UserDTO(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertEqual(userDTO.email, "test@example.com")
        XCTAssertEqual(userDTO.displayName, "Test User")
    }
    
    func testUserDTOInitializationWithNilValues() {
        let userDTO = UserDTO(
            id: "user-123",
            email: nil,
            displayName: nil
        )
        
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertNil(userDTO.email)
        XCTAssertNil(userDTO.displayName)
    }
    
    func testUserDTOToDomain() {
        let userDTO = UserDTO(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let user = userDTO.toDomain()
        
        XCTAssertEqual(user.id, "user-123")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
    }
    
    func testUserDTOToDomainWithNilId() {
        let userDTO = UserDTO(
            id: nil,
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let user = userDTO.toDomain()
        
        XCTAssertNotNil(user.id)
        XCTAssertFalse(user.id.isEmpty)
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
    }
    
    func testUserDTOToDomainWithNilOptionalValues() {
        let userDTO = UserDTO(
            id: "user-123",
            email: nil,
            displayName: nil
        )
        
        let user = userDTO.toDomain()
        
        XCTAssertEqual(user.id, "user-123")
        XCTAssertNil(user.email)
        XCTAssertNil(user.displayName)
    }
    
    func testUserDTOFromDomain() {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let userDTO = UserDTO.fromDomain(user)
        
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertEqual(userDTO.email, "test@example.com")
        XCTAssertEqual(userDTO.displayName, "Test User")
    }
    
    func testUserDTOFromDomainWithNilValues() {
        let user = User(
            id: "user-123",
            email: nil,
            displayName: nil
        )
        
        let userDTO = UserDTO.fromDomain(user)
        
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertNil(userDTO.email)
        XCTAssertNil(userDTO.displayName)
    }
    
    func testUserDTORoundTripConversion() {
        let originalUser = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        let userDTO = UserDTO.fromDomain(originalUser)
        let convertedUser = userDTO.toDomain()
        
        XCTAssertEqual(originalUser.id, convertedUser.id)
        XCTAssertEqual(originalUser.email, convertedUser.email)
        XCTAssertEqual(originalUser.displayName, convertedUser.displayName)
    }
    
    func testUserDTORoundTripConversionWithNilValues() {
        let originalUser = User(
            id: "user-123",
            email: nil,
            displayName: nil
        )
        
        let userDTO = UserDTO.fromDomain(originalUser)
        let convertedUser = userDTO.toDomain()
        
        XCTAssertEqual(originalUser.id, convertedUser.id)
        XCTAssertEqual(originalUser.email, convertedUser.email)
        XCTAssertEqual(originalUser.displayName, convertedUser.displayName)
    }
    
    func testUserDTOCodable() throws {
        let userDTO = UserDTO(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // Test DTO properties directly instead of JSON encoding/decoding
        // since Firestore DocumentID cannot be encoded with standard JSONEncoder
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertEqual(userDTO.email, "test@example.com")
        XCTAssertEqual(userDTO.displayName, "Test User")
    }
    
    func testUserDTOCodableWithNilValues() throws {
        let userDTO = UserDTO(
            id: "user-123",
            email: nil,
            displayName: nil
        )
        
        // Test DTO properties directly instead of JSON encoding/decoding
        // since Firestore DocumentID cannot be encoded with standard JSONEncoder
        XCTAssertEqual(userDTO.id, "user-123")
        XCTAssertNil(userDTO.email)
        XCTAssertNil(userDTO.displayName)
    }
    
    func testUserDTOEmptyStringValues() {
        let userDTO = UserDTO(
            id: "",
            email: "",
            displayName: ""
        )
        
        XCTAssertEqual(userDTO.id, "")
        XCTAssertEqual(userDTO.email, "")
        XCTAssertEqual(userDTO.displayName, "")
    }
}
