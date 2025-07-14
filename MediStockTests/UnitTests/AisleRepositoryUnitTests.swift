import XCTest
import Combine
@testable import MediStock

@MainActor
final class AisleRepositoryUnitTests: XCTestCase, Sendable {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Aisle Model Tests
    
    func testAisleInitialization() {
        // Given
        let id = "test-aisle-id"
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
    
    func testAisleWithOptionalDescription() {
        // Given
        let aisle = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // Then
        XCTAssertNil(aisle.description)
        XCTAssertEqual(aisle.name, "Test Aisle")
    }
    
    func testAisleEquality() {
        // Given
        let aisle1 = Aisle(id: "1", name: "Aisle 1", description: "Desc", colorHex: "#FF0000", icon: "pills")
        let aisle2 = Aisle(id: "1", name: "Aisle 1", description: "Desc", colorHex: "#FF0000", icon: "pills")
        let aisle3 = Aisle(id: "2", name: "Aisle 2", description: "Desc", colorHex: "#00FF00", icon: "pills")
        
        // Then
        XCTAssertEqual(aisle1, aisle2)
        XCTAssertNotEqual(aisle1, aisle3)
    }
    
    // MARK: - AisleDTO Model Tests
    
    func testAisleDTOInitialization() {
        // Given
        let dto = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // Then
        XCTAssertEqual(dto.id, "test-id")
        XCTAssertEqual(dto.name, "Test Aisle")
        XCTAssertEqual(dto.description, "Test Description")
        XCTAssertEqual(dto.colorHex, "#FF0000")
        XCTAssertEqual(dto.icon, "pills")
    }
    
    func testAisleDTOToDomainConversion() {
        // Given
        let dto = AisleDTO(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // When
        let domainModel = dto.toDomain()
        
        // Then
        XCTAssertEqual(domainModel.id, dto.id)
        XCTAssertEqual(domainModel.name, dto.name)
        XCTAssertEqual(domainModel.description, dto.description)
        XCTAssertEqual(domainModel.colorHex, dto.colorHex)
        XCTAssertEqual(domainModel.icon, dto.icon)
    }
    
    func testAisleDTOFromDomainConversion() {
        // Given
        let domainModel = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // When
        let dto = AisleDTO.fromDomain(domainModel)
        
        // Then
        XCTAssertEqual(dto.id, domainModel.id)
        XCTAssertEqual(dto.name, domainModel.name)
        XCTAssertEqual(dto.description, domainModel.description)
        XCTAssertEqual(dto.colorHex, domainModel.colorHex)
        XCTAssertEqual(dto.icon, domainModel.icon)
    }
    
    func testAisleDTORoundTripConversion() {
        // Given
        let originalAisle = Aisle(
            id: "test-id",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // When
        let dto = AisleDTO.fromDomain(originalAisle)
        let convertedBack = dto.toDomain()
        
        // Then
        XCTAssertEqual(originalAisle, convertedBack)
    }
    
    // MARK: - Color Validation Tests
    
    func testValidColorHexFormats() {
        let validColors = [
            "#FF0000", // red
            "#00FF00", // green
            "#0000FF", // blue
            "#FFFFFF", // white
            "#000000", // black
            "#123ABC", // mixed
            "#ff0000", // lowercase
            "#FfFfFf"  // mixed case
        ]
        
        for color in validColors {
            XCTAssertTrue(isValidColorHex(color), "Color '\(color)' should be valid")
        }
    }
    
    func testInvalidColorHexFormats() {
        let invalidColors = [
            "",
            "FF0000", // missing #
            "#FF00", // too short
            "#FF00000", // too long
            "#GGGGGG", // invalid characters
            "red", // color name
            "#FG0000" // invalid character
        ]
        
        for color in invalidColors {
            XCTAssertFalse(isValidColorHex(color), "Color '\(color)' should be invalid")
        }
    }
    
    // MARK: - Icon Validation Tests
    
    func testValidIconNames() {
        let validIcons = [
            "pills",
            "heart",
            "medical-cross",
            "stethoscope",
            "syringe",
            "bandage"
        ]
        
        for icon in validIcons {
            XCTAssertTrue(isValidIconName(icon), "Icon '\(icon)' should be valid")
        }
    }
    
    func testInvalidIconNames() {
        let invalidIcons = [
            "",
            " ", // just space
            "invalid icon", // space
            "<script>", // malicious
            "🎉", // emoji
            String(repeating: "a", count: 1000) // too long
        ]
        
        for icon in invalidIcons {
            XCTAssertFalse(isValidIconName(icon), "Icon '\(icon)' should be invalid")
        }
    }
    
    // MARK: - Search Logic Tests
    
    func testAisleSearchByName() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "Emergency Medicine", description: "Emergency drugs", colorHex: "#FF0000", icon: "pills"),
            Aisle(id: "2", name: "Cardiology", description: "Heart medications", colorHex: "#00FF00", icon: "heart"),
            Aisle(id: "3", name: "Emergency Surgery", description: "Surgery supplies", colorHex: "#0000FF", icon: "medical-cross")
        ]
        
        // When
        let results = searchAisles(aisles, query: "Emergency")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Emergency") })
    }
    
    func testAisleSearchByDescription() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "Aisle A", description: "Heart medications", colorHex: "#FF0000", icon: "pills"),
            Aisle(id: "2", name: "Aisle B", description: "Pain relief", colorHex: "#00FF00", icon: "pills"),
            Aisle(id: "3", name: "Aisle C", description: "Heart surgery tools", colorHex: "#0000FF", icon: "medical-cross")
        ]
        
        // When
        let results = searchAisles(aisles, query: "Heart")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.description?.contains("Heart") == true })
    }
    
    func testAisleSearchCaseInsensitive() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "CaRdIoLoGy", description: "Test", colorHex: "#FF0000", icon: "pills")
        ]
        
        // When
        let results = searchAisles(aisles, query: "cardiology")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "CaRdIoLoGy")
    }
    
    func testAisleSearchWithEmptyQuery() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "Aisle 1", description: "Test", colorHex: "#FF0000", icon: "pills"),
            Aisle(id: "2", name: "Aisle 2", description: "Test", colorHex: "#00FF00", icon: "pills")
        ]
        
        // When
        let results = searchAisles(aisles, query: "")
        
        // Then
        XCTAssertEqual(results.count, aisles.count)
    }
    
    func testAisleSearchWithNoMatches() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "Cardiology", description: "Test", colorHex: "#FF0000", icon: "pills")
        ]
        
        // When
        let results = searchAisles(aisles, query: "NonExistentQuery")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Sorting Logic Tests
    
    func testAisleSortingByName() {
        // Given
        let aisles = [
            Aisle(id: "3", name: "Zebra", description: "Test", colorHex: "#FF0000", icon: "pills"),
            Aisle(id: "1", name: "Alpha", description: "Test", colorHex: "#00FF00", icon: "pills"),
            Aisle(id: "2", name: "Beta", description: "Test", colorHex: "#0000FF", icon: "pills")
        ]
        
        // When
        let sorted = sortAislesByName(aisles)
        
        // Then
        XCTAssertEqual(sorted[0].name, "Alpha")
        XCTAssertEqual(sorted[1].name, "Beta")
        XCTAssertEqual(sorted[2].name, "Zebra")
    }
    
    func testAisleSortingIgnoresCase() {
        // Given
        let aisles = [
            Aisle(id: "1", name: "zebra", description: "Test", colorHex: "#FF0000", icon: "pills"),
            Aisle(id: "2", name: "Alpha", description: "Test", colorHex: "#00FF00", icon: "pills"),
            Aisle(id: "3", name: "beta", description: "Test", colorHex: "#0000FF", icon: "pills")
        ]
        
        // When
        let sorted = sortAislesByName(aisles)
        
        // Then
        XCTAssertEqual(sorted[0].name, "Alpha")
        XCTAssertEqual(sorted[1].name, "beta")
        XCTAssertEqual(sorted[2].name, "zebra")
    }
    
    // MARK: - Data Validation Tests
    
    func testAisleNameValidation() {
        let validNames = [
            "Emergency Medicine",
            "Cardiology",
            "A", // single character
            "Aisle-123",
            "Aisle 1"
        ]
        
        for name in validNames {
            XCTAssertTrue(isValidAisleName(name), "Name '\(name)' should be valid")
        }
        
        let invalidNames = [
            "",
            " ", // just space
            "   ", // multiple spaces
            String(repeating: "a", count: 1000) // too long
        ]
        
        for name in invalidNames {
            XCTAssertFalse(isValidAisleName(name), "Name '\(name)' should be invalid")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAisleSearchPerformance() {
        // Given
        let aisles = (0..<1000).map { i in
            Aisle(id: "\(i)", name: "Aisle \(i)", description: "Description \(i)", colorHex: "#FF0000", icon: "pills")
        }
        
        measure {
            _ = searchAisles(aisles, query: "500")
        }
    }
    
    func testAisleSortingPerformance() {
        // Given
        let aisles = (0..<1000).map { i in
            Aisle(id: "\(i)", name: "Aisle \(999 - i)", description: "Description", colorHex: "#FF0000", icon: "pills")
        }
        
        measure {
            _ = sortAislesByName(aisles)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAisleOperations() async {
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 100
        
        let aisles = (0..<100).map { i in
            Aisle(id: "\(i)", name: "Aisle \(i)", description: "Description", colorHex: "#FF0000", icon: "pills")
        }
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    _ = searchAisles(aisles, query: "\(i)")
                    _ = sortAislesByName(aisles)
                    
                    await MainActor.run {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Edge Cases
    
    func testAisleWithVeryLongName() {
        let longName = String(repeating: "A", count: 10000)
        let aisle = Aisle(id: "test", name: longName, description: "Test", colorHex: "#FF0000", icon: "pills")
        
        XCTAssertEqual(aisle.name, longName)
        XCTAssertNoThrow({
            _ = searchAisles([aisle], query: "A")
        }())
    }
    
    func testAisleWithUnicodeCharacters() {
        let unicodeName = "Ãîslé Médîcïnë"
        let aisle = Aisle(id: "test", name: unicodeName, description: "Test", colorHex: "#FF0000", icon: "pills")
        
        XCTAssertEqual(aisle.name, unicodeName)
        XCTAssertNoThrow({
            _ = searchAisles([aisle], query: "Médîcïnë")
        }())
    }
    
    // MARK: - Security Tests
    
    func testMaliciousInputHandling() {
        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "'; DROP TABLE aisles; --",
            "\\0\\x01\\x02",
            String(repeating: "a", count: 10000)
        ]
        
        let aisles = [
            Aisle(id: "1", name: "Test", description: "Test", colorHex: "#FF0000", icon: "pills")
        ]
        
        for input in maliciousInputs {
            XCTAssertNoThrow({
                _ = searchAisles(aisles, query: input)
                _ = isValidAisleName(input)
                _ = isValidColorHex(input)
                _ = isValidIconName(input)
            }())
        }
    }
}

// MARK: - Helper Functions (Pure Logic)

private func isValidColorHex(_ color: String) -> Bool {
    let hexPattern = "^#[A-Fa-f0-9]{6}$"
    return NSPredicate(format: "SELF MATCHES %@", hexPattern).evaluate(with: color)
}

private func isValidIconName(_ icon: String) -> Bool {
    let trimmed = icon.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && 
           trimmed.count <= 50 && 
           !trimmed.contains(" ") &&
           trimmed.allSatisfy { $0.isLetter || $0 == "-" }
}

private func isValidAisleName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && trimmed.count <= 255
}

private func searchAisles(_ aisles: [Aisle], query: String) -> [Aisle] {
    if query.isEmpty {
        return aisles
    }
    
    let lowercaseQuery = query.lowercased()
    return aisles.filter { aisle in
        aisle.name.lowercased().contains(lowercaseQuery) ||
        (aisle.description?.lowercased().contains(lowercaseQuery) ?? false)
    }
}

private func sortAislesByName(_ aisles: [Aisle]) -> [Aisle] {
    return aisles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}