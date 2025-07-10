import XCTest
@testable import MediStock

final class AisleTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testAisleInitialization_AllFields() {
        // Given
        let id = "aisle-123"
        let name = "Test Aisle"
        let description = "Test Description"
        let location = "Floor 1, Section A"
        let capacity = 500
        let createdAt = Date()
        let updatedAt = Date()
        
        // When
        let aisle = Aisle(
            id: id,
            name: name,
            description: description,
            location: location,
            capacity: capacity,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Then
        XCTAssertEqual(aisle.id, id)
        XCTAssertEqual(aisle.name, name)
        XCTAssertEqual(aisle.description, description)
        XCTAssertEqual(aisle.location, location)
        XCTAssertEqual(aisle.capacity, capacity)
        XCTAssertEqual(aisle.createdAt, createdAt)
        XCTAssertEqual(aisle.updatedAt, updatedAt)
    }
    
    func testAisleInitialization_MinimalFields() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            id: "min-aisle",
            name: "Minimal Aisle"
        )
        
        // Then
        XCTAssertEqual(aisle.id, "min-aisle")
        XCTAssertEqual(aisle.name, "Minimal Aisle")
        XCTAssertNotNil(aisle.description)
        XCTAssertNotNil(aisle.location)
        XCTAssertGreaterThan(aisle.capacity, 0)
    }
    
    // MARK: - Equatable Tests
    
    func testAisleEquality_SameValues() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A")
        
        // Then
        XCTAssertEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentIds() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-2", name: "Aisle A")
        
        // Then
        XCTAssertNotEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentNames() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle B")
        
        // Then
        XCTAssertNotEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentCapacities() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", capacity: 100)
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", capacity: 200)
        
        // Then
        XCTAssertNotEqual(aisle1, aisle2)
    }
    
    // MARK: - Identifiable Tests
    
    func testAisleIdentifiable() {
        // Given
        let aisle = TestDataFactory.createTestAisle(id: "test-id")
        
        // Then
        XCTAssertEqual(aisle.id, "test-id")
    }
    
    // MARK: - Codable Tests
    
    func testAisleEncoding() throws {
        // Given
        let aisle = TestDataFactory.createTestAisle(
            id: "aisle-123",
            name: "Test Aisle",
            description: "Test Description",
            location: "Floor 1",
            capacity: 300
        )
        
        // When
        let encoded = try JSONEncoder().encode(aisle)
        
        // Then
        XCTAssertNotNil(encoded)
        XCTAssertGreaterThan(encoded.count, 0)
    }
    
    func testAisleDecoding() throws {
        // Given
        let originalAisle = TestDataFactory.createTestAisle(
            id: "aisle-123",
            name: "Test Aisle",
            description: "Test Description"
        )
        let encoded = try JSONEncoder().encode(originalAisle)
        
        // When
        let decoded = try JSONDecoder().decode(Aisle.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalAisle.id)
        XCTAssertEqual(decoded.name, originalAisle.name)
        XCTAssertEqual(decoded.description, originalAisle.description)
        XCTAssertEqual(decoded.location, originalAisle.location)
        XCTAssertEqual(decoded.capacity, originalAisle.capacity)
    }
    
    func testAisleRoundTripCoding() throws {
        // Given
        let originalAisle = TestDataFactory.createTestAisle(
            name: "Original Aisle",
            capacity: 750
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalAisle)
        let decoded = try JSONDecoder().decode(Aisle.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded, originalAisle)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAisleWithEmptyStrings() {
        // When
        let aisle = Aisle(
            id: "",
            name: "",
            description: "",
            location: "",
            capacity: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(aisle.id, "")
        XCTAssertEqual(aisle.name, "")
        XCTAssertEqual(aisle.description, "")
        XCTAssertEqual(aisle.location, "")
        XCTAssertEqual(aisle.capacity, 0)
    }
    
    func testAisleWithNegativeCapacity() {
        // When
        let aisle = TestDataFactory.createTestAisle(capacity: -100)
        
        // Then
        XCTAssertEqual(aisle.capacity, -100)
    }
    
    func testAisleWithVeryLargeCapacity() {
        // When
        let aisle = TestDataFactory.createTestAisle(capacity: Int.max)
        
        // Then
        XCTAssertEqual(aisle.capacity, Int.max)
    }
    
    func testAisleWithLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 5000)
        
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: longString,
            description: longString,
            location: longString
        )
        
        // Then
        XCTAssertEqual(aisle.name.count, 5000)
        XCTAssertEqual(aisle.description.count, 5000)
        XCTAssertEqual(aisle.location.count, 5000)
    }
    
    // MARK: - Date Handling Tests
    
    func testAisleTimestamps() {
        // Given
        let createdAt = Date()
        let updatedAt = Date(timeInterval: 3600, since: createdAt) // 1 hour later
        
        // When
        let aisle = TestDataFactory.createTestAisle(
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        // Then
        XCTAssertEqual(aisle.createdAt, createdAt)
        XCTAssertEqual(aisle.updatedAt, updatedAt)
    }
    
    func testAisleTimestampOrder() {
        // Given
        let now = Date()
        let past = Date(timeInterval: -3600, since: now) // 1 hour ago
        let future = Date(timeInterval: 3600, since: now) // 1 hour from now
        
        // When
        let aisle = TestDataFactory.createTestAisle(
            createdAt: past,
            updatedAt: future
        )
        
        // Then
        XCTAssertLessThan(aisle.createdAt, aisle.updatedAt)
    }
    
    // MARK: - Special Characters Tests
    
    func testAisleWithSpecialCharacters() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: "Aisle-A+B (500 capacity)",
            description: "Special chars: @#$%^&*()",
            location: "Floor-1/Section-A"
        )
        
        // Then
        XCTAssertEqual(aisle.name, "Aisle-A+B (500 capacity)")
        XCTAssertEqual(aisle.description, "Special chars: @#$%^&*()")
        XCTAssertEqual(aisle.location, "Floor-1/Section-A")
    }
    
    func testAisleWithUnicodeCharacters() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: "Couloir français 🇫🇷",
            description: "Descripción en español 🇪🇸",
            location: "位置 日本語"
        )
        
        // Then
        XCTAssertEqual(aisle.name, "Couloir français 🇫🇷")
        XCTAssertEqual(aisle.description, "Descripción en español 🇪🇸")
        XCTAssertEqual(aisle.location, "位置 日本語")
    }
    
    // MARK: - Memory Management Tests
    
    func testAisleMemoryManagement() {
        // Given
        var aisle: Aisle? = TestDataFactory.createTestAisle()
        weak var weakAisle = aisle
        
        // When
        aisle = nil
        
        // Then
        XCTAssertNil(weakAisle)
    }
    
    // MARK: - Array and Collection Tests
    
    func testAisleInArray() {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B"),
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C")
        ]
        
        // When
        let aisleA = aisles.first { $0.name == "Aisle A" }
        let aisleB = aisles.first { $0.id == "2" }
        
        // Then
        XCTAssertNotNil(aisleA)
        XCTAssertEqual(aisleA?.name, "Aisle A")
        XCTAssertNotNil(aisleB)
        XCTAssertEqual(aisleB?.name, "Aisle B")
    }
    
    func testAisleInSet() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A")
        let aisle2 = TestDataFactory.createTestAisle(id: "2", name: "Aisle B")
        let aisle3 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A") // Same as aisle1
        
        // When
        let aisleSet: Set<Aisle> = [aisle1, aisle2, aisle3]
        
        // Then
        XCTAssertEqual(aisleSet.count, 2) // aisle3 should be the same as aisle1
        XCTAssertTrue(aisleSet.contains(aisle1))
        XCTAssertTrue(aisleSet.contains(aisle2))
    }
    
    // MARK: - Hashable Tests
    
    func testAisleHashable() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A")
        let aisle2 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A")
        let aisle3 = TestDataFactory.createTestAisle(id: "2", name: "Aisle B")
        
        // Then
        XCTAssertEqual(aisle1.hashValue, aisle2.hashValue)
        XCTAssertNotEqual(aisle1.hashValue, aisle3.hashValue)
    }
    
    // MARK: - Property Validation Tests
    
    func testAisleFieldTypes() {
        // Given
        let aisle = TestDataFactory.createTestAisle()
        
        // Then - Verify field types
        XCTAssertTrue(aisle.id is String)
        XCTAssertTrue(aisle.name is String)
        XCTAssertTrue(aisle.description is String)
        XCTAssertTrue(aisle.location is String)
        XCTAssertTrue(aisle.capacity is Int)
        XCTAssertTrue(aisle.createdAt is Date)
        XCTAssertTrue(aisle.updatedAt is Date)
    }
    
    func testAisleCapacityRange() {
        // Given
        let smallAisle = TestDataFactory.createTestAisle(capacity: 1)
        let mediumAisle = TestDataFactory.createTestAisle(capacity: 500)
        let largeAisle = TestDataFactory.createTestAisle(capacity: 10000)
        
        // Then
        XCTAssertEqual(smallAisle.capacity, 1)
        XCTAssertEqual(mediumAisle.capacity, 500)
        XCTAssertEqual(largeAisle.capacity, 10000)
        XCTAssertLessThan(smallAisle.capacity, mediumAisle.capacity)
        XCTAssertLessThan(mediumAisle.capacity, largeAisle.capacity)
    }
    
    // MARK: - Comparison Tests
    
    func testAisleSorting() {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C"),
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B")
        ]
        
        // When
        let sortedByName = aisles.sorted { $0.name < $1.name }
        let sortedById = aisles.sorted { $0.id < $1.id }
        
        // Then
        XCTAssertEqual(sortedByName.map { $0.name }, ["Aisle A", "Aisle B", "Aisle C"])
        XCTAssertEqual(sortedById.map { $0.id }, ["1", "2", "3"])
    }
    
    // MARK: - JSON Structure Tests
    
    func testAisleJSONStructure() throws {
        // Given
        let aisle = TestDataFactory.createTestAisle(
            id: "aisle-123",
            name: "Test Aisle",
            description: "Test Description",
            location: "Floor 1",
            capacity: 300
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(aisle)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"id\""))
        XCTAssertTrue(jsonString.contains("\"name\""))
        XCTAssertTrue(jsonString.contains("\"description\""))
        XCTAssertTrue(jsonString.contains("\"location\""))
        XCTAssertTrue(jsonString.contains("\"capacity\""))
        XCTAssertTrue(jsonString.contains("\"createdAt\""))
        XCTAssertTrue(jsonString.contains("\"updatedAt\""))
        XCTAssertTrue(jsonString.contains("aisle-123"))
        XCTAssertTrue(jsonString.contains("Test Aisle"))
        XCTAssertTrue(jsonString.contains("300"))
    }
    
    // MARK: - Mutation Tests
    
    func testAisleImmutability() {
        // Given
        let aisle = TestDataFactory.createTestAisle(name: "Original Name")
        
        // When - Aisle is a struct, so it should be value type
        var mutableAisle = aisle
        // Note: Cannot directly test mutation since Aisle properties are let constants
        // This test verifies the struct nature
        
        // Then
        XCTAssertEqual(aisle.name, "Original Name")
        XCTAssertEqual(mutableAisle.name, "Original Name")
        // Both should have the same values since structs are copied
    }
}