import XCTest
@testable import MediStock
@MainActor
final class UserTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testUserInitialization_AllFields() {
        // Given
        let id = "user-123"
        let email = "test@example.com"
        let displayName = "Test User"
        
        // When
        let user = User(
            id: id,
            email: email,
            displayName: displayName
        )
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
    }
    
    func testUserInitialization_MinimalFields() {
        // When
        let user = User(
            id: "min-user",
            email: "min@example.com",
            displayName: ""
        )
        
        // Then
        XCTAssertEqual(user.id, "min-user")
        XCTAssertEqual(user.email, "min@example.com")
        XCTAssertEqual(user.displayName, "")
    }
    
    // MARK: - Equatable Tests
    
    func testUserEquality_SameValues() {
        // Given
        let user1 = User(id: "user-1", email: "test@example.com", displayName: "Test User")
        let user2 = User(id: "user-1", email: "test@example.com", displayName: "Test User")
        
        // Then
        XCTAssertEqual(user1, user2)
    }
    
    func testUserEquality_DifferentIds() {
        // Given
        let user1 = User(id: "user-1", email: "test@example.com", displayName: "Test User")
        let user2 = User(id: "user-2", email: "test@example.com", displayName: "Test User")
        
        // Then
        XCTAssertNotEqual(user1, user2)
    }
    
    func testUserEquality_DifferentEmails() {
        // Given
        let user1 = User(id: "user-1", email: "test1@example.com", displayName: "Test User")
        let user2 = User(id: "user-1", email: "test2@example.com", displayName: "Test User")
        
        // Then
        XCTAssertNotEqual(user1, user2)
    }
    
    func testUserEquality_DifferentDisplayNames() {
        // Given
        let user1 = User(id: "user-1", email: "test@example.com", displayName: "User One")
        let user2 = User(id: "user-1", email: "test@example.com", displayName: "User Two")
        
        // Then
        XCTAssertNotEqual(user1, user2)
    }
    
    // MARK: - Identifiable Tests
    
    func testUserIdentifiable() {
        // Given
        let user = User(id: "test-id", email: "test@example.com", displayName: "Test User")
        
        // Then
        XCTAssertEqual(user.id, "test-id")
    }
    
    // MARK: - Codable Tests
    
    func testUserEncoding() throws {
        // Given
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // When
        let encoded = try JSONEncoder().encode(user)
        
        // Then
        XCTAssertNotNil(encoded)
        XCTAssertGreaterThan(encoded.count, 0)
    }
    
    func testUserDecoding() throws {
        // Given
        let originalUser = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        let encoded = try JSONEncoder().encode(originalUser)
        
        // When
        let decoded = try JSONDecoder().decode(User.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalUser.id)
        XCTAssertEqual(decoded.email, originalUser.email)
        XCTAssertEqual(decoded.displayName, originalUser.displayName)
    }
    
    func testUserRoundTripCoding() throws {
        // Given
        let originalUser = User(
            id: "user-456",
            email: "roundtrip@example.com",
            displayName: "Round Trip User"
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalUser)
        let decoded = try JSONDecoder().decode(User.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded, originalUser)
    }
    
    // MARK: - Edge Cases Tests
    
    func testUserWithEmptyStrings() {
        // When
        let user = User(
            id: "",
            email: "",
            displayName: ""
        )
        
        // Then
        XCTAssertEqual(user.id, "")
        XCTAssertEqual(user.email, "")
        XCTAssertEqual(user.displayName, "")
    }
    
    func testUserWithLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 1000)
        
        // When
        let user = User(
            id: longString,
            email: longString + "@example.com",
            displayName: longString
        )
        
        // Then
        XCTAssertEqual(user.id.count, 1000)
        XCTAssertEqual(user.email?.count, 1012) // 1000 + "@example.com".count
        XCTAssertEqual(user.displayName?.count, 1000)
    }
    
    // MARK: - Email Validation Tests
    
    func testUserWithValidEmails() {
        // Given
        let validEmails = [
            "user@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user123@example.co.uk",
            "test.email@sub.domain.com"
        ]
        
        // When & Then
        for email in validEmails {
            let user = User(id: "test", email: email, displayName: "Test")
            XCTAssertEqual(user.email, email)
            XCTAssertFalse(user.email?.isEmpty ?? true)
        }
    }
    
    func testUserWithSpecialEmailFormats() {
        // Given
        let specialEmails = [
            "user@localhost",
            "user@192.168.1.1",
            "very.long.email.address@very.long.domain.name.com"
        ]
        
        // When & Then
        for email in specialEmails {
            let user = User(id: "test", email: email, displayName: "Test")
            XCTAssertEqual(user.email, email)
        }
    }
    
    // MARK: - Special Characters Tests
    
    func testUserWithSpecialCharacters() {
        // When
        let user = User(
            id: "user-123-special",
            email: "user+special@example.com",
            displayName: "User (Special) Name!"
        )
        
        // Then
        XCTAssertEqual(user.id, "user-123-special")
        XCTAssertEqual(user.email, "user+special@example.com")
        XCTAssertEqual(user.displayName, "User (Special) Name!")
    }
    
    func testUserWithUnicodeCharacters() {
        // When
        let user = User(
            id: "用户-123",
            email: "test@测试.com",
            displayName: "Utilisateur français 🇫🇷"
        )
        
        // Then
        XCTAssertEqual(user.id, "用户-123")
        XCTAssertEqual(user.email, "test@测试.com")
        XCTAssertEqual(user.displayName, "Utilisateur français 🇫🇷")
    }
    
    // MARK: - Value Type Tests
    
    func testUserValueTypeSemantics() {
        // Given
        var user1 = User(id: "test", email: "test@example.com", displayName: "Original Name")
        var user2 = user1
        
        // When
        user2 = User(id: user2.id, email: user2.email, displayName: "Modified Name")
        
        // Then - Value types should not affect each other
        XCTAssertEqual(user1.displayName, "Original Name")
        XCTAssertEqual(user2.displayName, "Modified Name")
    }
    
    // MARK: - Array and Collection Tests
    
    func testUserInArray() {
        // Given
        let users = [
            User(id: "1", email: "user1@example.com", displayName: "User One"),
            User(id: "2", email: "user2@example.com", displayName: "User Two"),
            User(id: "3", email: "user3@example.com", displayName: "User Three")
        ]
        
        // When
        let userOne = users.first { $0.displayName == "User One" }
        let userById = users.first { $0.id == "2" }
        let userByEmail = users.first { $0.email == "user3@example.com" }
        
        // Then
        XCTAssertNotNil(userOne)
        XCTAssertEqual(userOne?.id, "1")
        XCTAssertNotNil(userById)
        XCTAssertEqual(userById?.displayName, "User Two")
        XCTAssertNotNil(userByEmail)
        XCTAssertEqual(userByEmail?.displayName, "User Three")
    }
    
    func testUserInSet() {
        // Given
        let user1 = User(id: "1", email: "user1@example.com", displayName: "User One")
        let user2 = User(id: "2", email: "user2@example.com", displayName: "User Two")
        let user3 = User(id: "1", email: "user1@example.com", displayName: "User One") // Same as user1
        
        // When
        let userSet: Set<User> = [user1, user2, user3]
        
        // Then
        XCTAssertEqual(userSet.count, 2) // user3 should be the same as user1
        XCTAssertTrue(userSet.contains(user1))
        XCTAssertTrue(userSet.contains(user2))
    }
    
    // MARK: - Hashable Tests
    
    func testUserHashable() {
        // Given
        let user1 = User(id: "1", email: "test@example.com", displayName: "Test User")
        let user2 = User(id: "1", email: "test@example.com", displayName: "Test User")
        let user3 = User(id: "2", email: "other@example.com", displayName: "Other User")
        
        // Then
        var hasher1 = Hasher()
        user1.hash(into: &hasher1)
        let hash1 = hasher1.finalize()
        
        var hasher2 = Hasher()
        user2.hash(into: &hasher2)
        let hash2 = hasher2.finalize()
        
        var hasher3 = Hasher()
        user3.hash(into: &hasher3)
        let hash3 = hasher3.finalize()
        
        XCTAssertEqual(hash1, hash2)
        XCTAssertNotEqual(hash1, hash3)
    }
    
    // MARK: - Property Validation Tests
    
    func testUserFieldTypes() {
        // Given
        let user = User(id: "test", email: "test@example.com", displayName: "Test User")
        
        // Then - Verify field types
        XCTAssertTrue(user.id is String)
        XCTAssertTrue(user.email is String)
        XCTAssertTrue(user.displayName is String)
    }
    
    // MARK: - Comparison Tests
    
    func testUserSorting() {
        // Given
        let users = [
            User(id: "3", email: "c@example.com", displayName: "Charlie"),
            User(id: "1", email: "a@example.com", displayName: "Alice"),
            User(id: "2", email: "b@example.com", displayName: "Bob")
        ]
        
        // When
        let sortedByName = users.sorted { ($0.displayName ?? "") < ($1.displayName ?? "") }
        let sortedById = users.sorted { $0.id < $1.id }
        let sortedByEmail = users.sorted { ($0.email ?? "") < ($1.email ?? "") }
        
        // Then
        XCTAssertEqual(sortedByName.map { $0.displayName }, ["Alice", "Bob", "Charlie"])
        XCTAssertEqual(sortedById.map { $0.id }, ["1", "2", "3"])
        XCTAssertEqual(sortedByEmail.map { $0.email }, ["a@example.com", "b@example.com", "c@example.com"])
    }
    
    // MARK: - JSON Structure Tests
    
    func testUserJSONStructure() throws {
        // Given
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(user)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"id\""))
        XCTAssertTrue(jsonString.contains("\"email\""))
        XCTAssertTrue(jsonString.contains("\"displayName\""))
        XCTAssertTrue(jsonString.contains("user-123"))
        XCTAssertTrue(jsonString.contains("test@example.com"))
        XCTAssertTrue(jsonString.contains("Test User"))
    }
    
    // MARK: - Case Sensitivity Tests
    
    func testUserCaseSensitivity() {
        // Given
        let user1 = User(id: "user", email: "test@example.com", displayName: "Test User")
        let user2 = User(id: "USER", email: "TEST@EXAMPLE.COM", displayName: "TEST USER")
        
        // Then
        XCTAssertNotEqual(user1, user2)
        XCTAssertNotEqual(user1.id, user2.id)
        XCTAssertNotEqual(user1.email, user2.email)
        XCTAssertNotEqual(user1.displayName, user2.displayName)
    }
    
    // MARK: - Display Name Variations Tests
    
    func testUserDisplayNameVariations() {
        // Given
        let variations = [
            "John Doe",
            "John",
            "Doe",
            "J. Doe",
            "John D.",
            "Dr. John Doe",
            "John Doe Jr.",
            "John-Paul Doe",
            "John O'Connor"
        ]
        
        // When & Then
        for displayName in variations {
            let user = User(id: "test", email: "test@example.com", displayName: displayName)
            XCTAssertEqual(user.displayName, displayName)
            XCTAssertFalse(user.displayName?.isEmpty ?? true)
        }
    }
    
    // MARK: - Filtering Tests
    
    func testUserFiltering() {
        // Given
        let users = [
            User(id: "1", email: "admin@company.com", displayName: "Admin User"),
            User(id: "2", email: "user@company.com", displayName: "Regular User"),
            User(id: "3", email: "guest@company.com", displayName: "Guest User"),
            User(id: "4", email: "admin@other.com", displayName: "Other Admin")
        ]
        
        // When
        let companyUsers = users.filter { $0.email?.contains("@company.com") ?? false }
        let adminUsers = users.filter { $0.displayName?.contains("Admin") ?? false }
        
        // Then
        XCTAssertEqual(companyUsers.count, 3)
        XCTAssertEqual(adminUsers.count, 2)
        XCTAssertTrue(companyUsers.allSatisfy { $0.email?.contains("@company.com") ?? false })
        XCTAssertTrue(adminUsers.allSatisfy { $0.displayName?.contains("Admin") ?? false })
    }
    
    // MARK: - Mutation Tests (Struct Nature)
    
    func testUserImmutability() {
        // Given
        let user = User(id: "test", email: "test@example.com", displayName: "Original Name")
        
        // When - User is a struct, so it should be value type
        var mutableUser = user
        // Note: Cannot directly test mutation since User properties are let constants
        // This test verifies the struct nature
        
        // Then
        XCTAssertEqual(user.displayName, "Original Name")
        XCTAssertEqual(mutableUser.displayName, "Original Name")
        // Both should have the same values since structs are copied
    }
}
