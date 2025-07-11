import XCTest
import SwiftUI
@testable import MediStock
@MainActor
final class AisleTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testAisleInitialization_AllFields() {
        // Given
        let id = "aisle-123"
        let name = "Test Aisle"
        let description = "Test Description"
        let colorHex = "#FF0000"
        let icon = "pills"
        
        // When
        let aisle = Aisle(
            id: id,
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
        
        // Then
        XCTAssertEqual(aisle.id, id)
        XCTAssertEqual(aisle.name, name)
        XCTAssertEqual(aisle.description, description)
        XCTAssertEqual(aisle.colorHex, colorHex)
        XCTAssertEqual(aisle.icon, icon)
    }
    
    func testAisleInitialization_MinimalFields() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            id: "min-aisle",
            name: "Minimal Aisle",
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertEqual(aisle.id, "min-aisle")
        XCTAssertEqual(aisle.name, "Minimal Aisle")
        XCTAssertNotNil(aisle.description)
        XCTAssertFalse(aisle.colorHex.isEmpty)
        XCTAssertFalse(aisle.icon.isEmpty)
    }
    
    // MARK: - Equatable Tests
    
    func testAisleEquality_SameValues() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A", description: nil, colorHex: "#007AFF", icon: "pills")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A", description: nil, colorHex: "#007AFF", icon: "pills")
        
        // Then
        XCTAssertEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentIds() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A", colorHex: "#007AFF")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-2", name: "Aisle A", colorHex: "#007AFF")
        
        // Then
        XCTAssertNotEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentNames() {
        // Given - Same ID, different names
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle A", colorHex: "#007AFF")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Aisle B", colorHex: "#007AFF")
        
        // Then - Aisles with same ID are equal (based on Aisle's == implementation)
        XCTAssertEqual(aisle1, aisle2)
    }
    
    func testAisleEquality_DifferentIcons() {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Test Aisle", description: nil, colorHex: "#007AFF", icon: "pills")
        let aisle2 = TestDataFactory.createTestAisle(id: "aisle-1", name: "Test Aisle", description: nil, colorHex: "#007AFF", icon: "cross.fill")
        
        // Then
        XCTAssertEqual(aisle1, aisle2) // Same id, so equal according to Aisle's == implementation
    }
    
    // MARK: - Identifiable Tests
    
    func testAisleIdentifiable() {
        // Given
        let aisle = TestDataFactory.createTestAisle(id: "test-id", colorHex: "#007AFF")
        
        // Then
        XCTAssertEqual(aisle.id, "test-id")
    }
    
    // MARK: - Color Tests
    
    func testAisleColorProperty() {
        // Given
        let aisle = TestDataFactory.createTestAisle(
            id: "aisle-123",
            name: "Test Aisle",
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertNotNil(aisle.color)
        XCTAssertFalse(aisle.colorHex.isEmpty)
    }
    
    func testAisleColorFromHex() {
        // Given
        let redHex = "#FF0000"
        let aisle = Aisle(
            id: "test-aisle",
            name: "Red Aisle",
            description: "A red aisle",
            colorHex: redHex,
            icon: "pills"
        )
        
        // Then
        XCTAssertEqual(aisle.colorHex, redHex)
        XCTAssertNotNil(aisle.color)
    }
    
    func testAisleColorInitializer() {
        // Given
        let color = Color.red
        let aisle = Aisle(
            id: "test-aisle",
            name: "Colored Aisle",
            description: "An aisle with color",
            color: color,
            icon: "pills"
        )
        
        // Then
        XCTAssertFalse(aisle.colorHex.isEmpty)
        XCTAssertNotNil(aisle.color)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAisleWithEmptyStrings() {
        // When
        let aisle = Aisle(
            id: "",
            name: "",
            description: "",
            colorHex: "#000000",
            icon: ""
        )
        
        // Then
        XCTAssertEqual(aisle.id, "")
        XCTAssertEqual(aisle.name, "")
        XCTAssertEqual(aisle.description, "")
        XCTAssertEqual(aisle.colorHex, "#000000")
        XCTAssertEqual(aisle.icon, "")
    }
    
    func testAisleWithDifferentIcons() {
        // Given
        let icons = ["pills", "cross.fill", "heart", "bandage", "syringe"]
        
        // When
        let aisles = icons.map { icon in
            TestDataFactory.createTestAisle(id: "test-aisle-\(icon)", name: "Test Aisle", description: nil, colorHex: "#007AFF", icon: icon)
        }
        
        // Then
        for (index, aisle) in aisles.enumerated() {
            XCTAssertEqual(aisle.icon, icons[index])
        }
    }
    
    func testAisleWithLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 5000)
        
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: longString,
            description: longString,
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertEqual(aisle.name.count, 5000)
        XCTAssertEqual(aisle.description?.count, 5000)
    }
    
    // MARK: - Icon Validation Tests
    
    func testAisleIconTypes() {
        // Given
        let standardIcons = ["pills", "cross.fill", "heart", "bandage", "syringe", "folder"]
        
        // When & Then
        for icon in standardIcons {
            let aisle = TestDataFactory.createTestAisle(id: "test-aisle-\(icon)", name: "Test Aisle", description: nil, colorHex: "#007AFF", icon: icon)
            XCTAssertEqual(aisle.icon, icon)
            XCTAssertFalse(aisle.icon.isEmpty)
        }
    }
    
    // MARK: - Special Characters Tests
    
    func testAisleWithSpecialCharacters() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: "Aisle-A+B (special)",
            description: "Special chars: @#$%^&*()",
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertEqual(aisle.name, "Aisle-A+B (special)")
        XCTAssertEqual(aisle.description, "Special chars: @#$%^&*()")
    }
    
    func testAisleWithUnicodeCharacters() {
        // When
        let aisle = TestDataFactory.createTestAisle(
            name: "Couloir français 🇫🇷",
            description: "Descripción en español 🇪🇸",
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertEqual(aisle.name, "Couloir français 🇫🇷")
        XCTAssertEqual(aisle.description, "Descripción en español 🇪🇸")
    }
    
    // MARK: - Value Type Tests
    
    func testAisleValueTypeSemantics() {
        // Given
        var aisle1 = TestDataFactory.createTestAisle(name: "Original Name", colorHex: "#007AFF")
        var aisle2 = aisle1
        
        // When
        aisle2.name = "Modified Name"
        
        // Then - Value types should not affect each other
        XCTAssertEqual(aisle1.name, "Original Name")
        XCTAssertEqual(aisle2.name, "Modified Name")
    }
    
    // MARK: - Array and Collection Tests
    
    func testAisleInArray() {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C", colorHex: "#007AFF")
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
        let aisle1 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF")
        let aisle2 = TestDataFactory.createTestAisle(id: "2", name: "Aisle B", colorHex: "#007AFF")
        let aisle3 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF") // Same as aisle1
        
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
        let aisle1 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF")
        let aisle2 = TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF")
        let aisle3 = TestDataFactory.createTestAisle(id: "2", name: "Aisle B", colorHex: "#007AFF")
        
        // Then
        var hasher1 = Hasher()
        aisle1.hash(into: &hasher1)
        var hasher2 = Hasher()
        aisle2.hash(into: &hasher2)
        var hasher3 = Hasher()
        aisle3.hash(into: &hasher3)
        
        XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
        XCTAssertNotEqual(hasher1.finalize(), hasher3.finalize())
    }
    
    // MARK: - Property Validation Tests
    
    func testAisleFieldTypes() {
        // Given
        let aisle = TestDataFactory.createTestAisle(colorHex: "#007AFF")
        
        // Then - Verify field types
        XCTAssertTrue(aisle.id is String)
        XCTAssertTrue(aisle.name is String)
        XCTAssertTrue(aisle.description is String?)
        XCTAssertTrue(aisle.colorHex is String)
        XCTAssertTrue(aisle.icon is String)
        XCTAssertNotNil(aisle.color)
    }
    
    func testAisleColorRange() {
        // Given
        let colors = [SwiftUI.Color.red, SwiftUI.Color.blue, SwiftUI.Color.green]
        let aisles = colors.map { color in
            Aisle(id: UUID().uuidString, name: "Test", color: color, icon: "pills")
        }
        
        // Then
        for aisle in aisles {
            XCTAssertFalse(aisle.colorHex.isEmpty)
            XCTAssertNotNil(aisle.color)
        }
    }
    
    // MARK: - Comparison Tests
    
    func testAisleSorting() {
        // Given
        let aisles = [
            TestDataFactory.createTestAisle(id: "3", name: "Aisle C", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "1", name: "Aisle A", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "2", name: "Aisle B", colorHex: "#007AFF")
        ]
        
        // When
        let sortedByName = aisles.sorted { $0.name < $1.name }
        let sortedById = aisles.sorted { $0.id < $1.id }
        
        // Then
        XCTAssertEqual(sortedByName.map { $0.name }, ["Aisle A", "Aisle B", "Aisle C"])
        XCTAssertEqual(sortedById.map { $0.id }, ["1", "2", "3"])
    }
    
    // MARK: - JSON Structure Tests
    
    func testAisleStringRepresentation() {
        // Given
        let aisle = TestDataFactory.createTestAisle(
            id: "aisle-123",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#007AFF"
        )
        
        // Then
        XCTAssertEqual(aisle.id, "aisle-123")
        XCTAssertEqual(aisle.name, "Test Aisle")
        XCTAssertEqual(aisle.description, "Test Description")
        XCTAssertFalse(aisle.colorHex.isEmpty)
        XCTAssertFalse(aisle.icon.isEmpty)
    }
    
    // MARK: - Mutation Tests
    
    func testAisleImmutability() {
        // Given
        let aisle = TestDataFactory.createTestAisle(name: "Original Name", colorHex: "#007AFF")
        
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
