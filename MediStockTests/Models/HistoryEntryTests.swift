import XCTest
@testable @preconcurrency import MediStock
@MainActor
final class HistoryEntryTests: XCTestCase, Sendable {
    
    // MARK: - Initialization Tests
    
    func testHistoryEntryInitialization_AllFields() {
        // Given
        let id = "history-123"
        let medicineId = "medicine-456"
        let userId = "user-789"
        let action = "Stock Updated"
        let details = "Updated from 50 to 75 units"
        let timestamp = Date()
        
        // When
        let historyEntry = HistoryEntry(
            id: id,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(historyEntry.id, id)
        XCTAssertEqual(historyEntry.medicineId, medicineId)
        XCTAssertEqual(historyEntry.userId, userId)
        XCTAssertEqual(historyEntry.action, action)
        XCTAssertEqual(historyEntry.details, details)
        XCTAssertEqual(historyEntry.timestamp, timestamp)
    }
    
    func testHistoryEntryInitialization_MinimalFields() {
        // When
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            id: "min-history",
            medicineId: "med-123",
            action: "Added"
        )
        
        // Then
        XCTAssertEqual(historyEntry.id, "min-history")
        XCTAssertEqual(historyEntry.medicineId, "med-123")
        XCTAssertEqual(historyEntry.action, "Added")
        XCTAssertNotNil(historyEntry.userId)
        XCTAssertNotNil(historyEntry.details)
        XCTAssertNotNil(historyEntry.timestamp)
    }
    
    // MARK: - Equatable Tests
    
    func testHistoryEntryEquality_SameValues() {
        // Given
        let timestamp = Date()
        let historyEntry1 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            medicineId: "med-1",
            action: "Added",
            timestamp: timestamp
        )
        let historyEntry2 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            medicineId: "med-1",
            action: "Added",
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(historyEntry1, historyEntry2)
    }
    
    func testHistoryEntryEquality_DifferentIds() {
        // Given
        let historyEntry1 = TestDataFactory.createTestHistoryEntry(id: "history-1")
        let historyEntry2 = TestDataFactory.createTestHistoryEntry(id: "history-2")
        
        // Then
        XCTAssertNotEqual(historyEntry1, historyEntry2)
    }
    
    func testHistoryEntryEquality_DifferentActions() {
        // Given
        let historyEntry1 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            action: "Added"
        )
        let historyEntry2 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            action: "Updated"
        )
        
        // Then
        XCTAssertNotEqual(historyEntry1, historyEntry2)
    }
    
    func testHistoryEntryEquality_DifferentTimestamps() {
        // Given
        let timestamp1 = Date()
        let timestamp2 = Date(timeInterval: 3600, since: timestamp1)
        let historyEntry1 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            timestamp: timestamp1
        )
        let historyEntry2 = TestDataFactory.createTestHistoryEntry(
            id: "history-1",
            timestamp: timestamp2
        )
        
        // Then
        XCTAssertNotEqual(historyEntry1, historyEntry2)
    }
    
    // MARK: - Identifiable Tests
    
    func testHistoryEntryIdentifiable() {
        // Given
        let historyEntry = TestDataFactory.createTestHistoryEntry(id: "test-id")
        
        // Then
        XCTAssertEqual(historyEntry.id, "test-id")
    }
    
    // MARK: - Codable Tests
    
    func testHistoryEntryEncoding() throws {
        // Given
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "Stock Updated",
            details: "Updated stock from 50 to 75"
        )
        
        // When
        let encoded = try JSONEncoder().encode(historyEntry)
        
        // Then
        XCTAssertNotNil(encoded)
        XCTAssertGreaterThan(encoded.count, 0)
    }
    
    func testHistoryEntryDecoding() throws {
        // Given
        let originalHistoryEntry = TestDataFactory.createTestHistoryEntry(
            id: "history-123",
            medicineId: "medicine-456",
            action: "Added",
            details: "Medicine added to inventory"
        )
        let encoded = try JSONEncoder().encode(originalHistoryEntry)
        
        // When
        let decoded = try JSONDecoder().decode(HistoryEntry.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, originalHistoryEntry.id)
        XCTAssertEqual(decoded.medicineId, originalHistoryEntry.medicineId)
        XCTAssertEqual(decoded.userId, originalHistoryEntry.userId)
        XCTAssertEqual(decoded.action, originalHistoryEntry.action)
        XCTAssertEqual(decoded.details, originalHistoryEntry.details)
    }
    
    func testHistoryEntryRoundTripCoding() throws {
        // Given
        let originalHistoryEntry = TestDataFactory.createTestHistoryEntry(
            medicineId: "medicine-789",
            action: "Stock Updated",
            details: "Updated from 100 to 150 units"
        )
        
        // When
        let encoded = try JSONEncoder().encode(originalHistoryEntry)
        let decoded = try JSONDecoder().decode(HistoryEntry.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded, originalHistoryEntry)
    }
    
    // MARK: - Edge Cases Tests
    
    func testHistoryEntryWithEmptyStrings() {
        // When
        let historyEntry = HistoryEntry(
            id: "",
            medicineId: "",
            userId: "",
            action: "",
            details: "",
            timestamp: Date()
        )
        
        // Then
        XCTAssertEqual(historyEntry.id, "")
        XCTAssertEqual(historyEntry.medicineId, "")
        XCTAssertEqual(historyEntry.userId, "")
        XCTAssertEqual(historyEntry.action, "")
        XCTAssertEqual(historyEntry.details, "")
    }
    
    func testHistoryEntryWithLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 5000)
        
        // When
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            id: longString,
            medicineId: longString,
            userId: longString,
            action: longString,
            details: longString
        )
        
        // Then
        XCTAssertEqual(historyEntry.id.count, 5000)
        XCTAssertEqual(historyEntry.medicineId.count, 5000)
        XCTAssertEqual(historyEntry.userId.count, 5000)
        XCTAssertEqual(historyEntry.action.count, 5000)
        XCTAssertEqual(historyEntry.details.count, 5000)
    }
    
    // MARK: - Date Handling Tests
    
    func testHistoryEntryWithVariousTimestamps() {
        // Given
        let now = Date()
        let past = Date(timeInterval: -86400, since: now) // 1 day ago
        let future = Date(timeInterval: 86400, since: now) // 1 day from now
        
        // When
        let currentEntry = TestDataFactory.createTestHistoryEntry(timestamp: now)
        let pastEntry = TestDataFactory.createTestHistoryEntry(timestamp: past)
        let futureEntry = TestDataFactory.createTestHistoryEntry(timestamp: future)
        
        // Then
        XCTAssertEqual(currentEntry.timestamp, now)
        XCTAssertEqual(pastEntry.timestamp, past)
        XCTAssertEqual(futureEntry.timestamp, future)
        XCTAssertLessThan(pastEntry.timestamp, currentEntry.timestamp)
        XCTAssertGreaterThan(futureEntry.timestamp, currentEntry.timestamp)
    }
    
    func testHistoryEntryTimestampPrecision() {
        // Given
        let timestamp = Date()
        
        // When
        let historyEntry = TestDataFactory.createTestHistoryEntry(timestamp: timestamp)
        
        // Then
        XCTAssertEqual(historyEntry.timestamp.timeIntervalSince1970, 
                       timestamp.timeIntervalSince1970, 
                       accuracy: 0.001) // Within 1ms
    }
    
    // MARK: - Special Characters Tests
    
    func testHistoryEntryWithSpecialCharacters() {
        // When
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            action: "Stock-Update+Adjustment (urgent)",
            details: "Special chars: @#$%^&*() - quantity changed"
        )
        
        // Then
        XCTAssertEqual(historyEntry.action, "Stock-Update+Adjustment (urgent)")
        XCTAssertEqual(historyEntry.details, "Special chars: @#$%^&*() - quantity changed")
    }
    
    func testHistoryEntryWithUnicodeCharacters() {
        // When
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            action: "Ajouté médicament 🇫🇷",
            details: "Descripción del cambio 🇪🇸 - 薬を追加しました 🇯🇵"
        )
        
        // Then
        XCTAssertEqual(historyEntry.action, "Ajouté médicament 🇫🇷")
        XCTAssertEqual(historyEntry.details, "Descripción del cambio 🇪🇸 - 薬を追加しました 🇯🇵")
    }
    
    // MARK: - Value Type Tests
    
    func testHistoryEntryValueTypeSemantics() {
        // Given
        let entry1 = TestDataFactory.createTestHistoryEntry(action: "Original Action")
        var entry2 = entry1
        
        // When
        entry2 = HistoryEntry(
            id: entry2.id,
            medicineId: entry2.medicineId,
            userId: entry2.userId,
            action: "Modified Action",
            details: entry2.details,
            timestamp: entry2.timestamp
        )
        
        // Then - Value types should not affect each other
        XCTAssertEqual(entry1.action, "Original Action")
        XCTAssertEqual(entry2.action, "Modified Action")
    }
    
    // MARK: - Array and Collection Tests
    
    func testHistoryEntryInArray() {
        // Given
        let entries = [
            TestDataFactory.createTestHistoryEntry(id: "1", action: "Added"),
            TestDataFactory.createTestHistoryEntry(id: "2", action: "Updated"),
            TestDataFactory.createTestHistoryEntry(id: "3", action: "Deleted")
        ]
        
        // When
        let addedEntry = entries.first { $0.action == "Added" }
        let entryById = entries.first { $0.id == "2" }
        
        // Then
        XCTAssertNotNil(addedEntry)
        XCTAssertEqual(addedEntry?.action, "Added")
        XCTAssertNotNil(entryById)
        XCTAssertEqual(entryById?.action, "Updated")
    }
    
    func testHistoryEntryInSet() {
        // Given - Create identical entries (same ID and all other fields)
        let timestamp = Date()
        let entry1 = TestDataFactory.createTestHistoryEntry(id: "1", action: "Added", timestamp: timestamp)
        let entry2 = TestDataFactory.createTestHistoryEntry(id: "2", action: "Updated", timestamp: timestamp)
        let entry3 = TestDataFactory.createTestHistoryEntry(id: "1", action: "Added", timestamp: timestamp) // Truly identical to entry1
        
        // When
        let entrySet: Set<HistoryEntry> = [entry1, entry2, entry3]
        
        // Then - Since HistoryEntry uses struct equality (all fields), entries must be truly identical
        XCTAssertEqual(entrySet.count, 2) // entry3 should be the same as entry1
        XCTAssertTrue(entrySet.contains(entry1))
        XCTAssertTrue(entrySet.contains(entry2))
    }
    
    // MARK: - Hashable Tests
    
    func testHistoryEntryHashable() {
        // Given
        let timestamp = Date()
        let entry1 = TestDataFactory.createTestHistoryEntry(
            id: "1",
            action: "Added",
            timestamp: timestamp
        )
        let entry2 = TestDataFactory.createTestHistoryEntry(
            id: "1",
            action: "Added",
            timestamp: timestamp
        )
        let entry3 = TestDataFactory.createTestHistoryEntry(
            id: "2",
            action: "Updated",
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(entry1.hashValue, entry2.hashValue)
        XCTAssertNotEqual(entry1.hashValue, entry3.hashValue)
    }
    
    // MARK: - Property Validation Tests
    
    func testHistoryEntryFieldTypes() {
        // Given
        let historyEntry = TestDataFactory.createTestHistoryEntry()
        
        // Then - Verify field types
        XCTAssertTrue(historyEntry.id is String)
        XCTAssertTrue(historyEntry.medicineId is String)
        XCTAssertTrue(historyEntry.userId is String)
        XCTAssertTrue(historyEntry.action is String)
        XCTAssertTrue(historyEntry.details is String)
        XCTAssertTrue(historyEntry.timestamp is Date)
    }
    
    // MARK: - Action Types Tests
    
    func testHistoryEntryCommonActions() {
        // Given
        let commonActions = [
            "Added",
            "Updated",
            "Deleted",
            "Stock Updated",
            "Stock Depleted",
            "Expiry Warning",
            "Critical Stock"
        ]
        
        // When & Then
        for action in commonActions {
            let entry = TestDataFactory.createTestHistoryEntry(action: action)
            XCTAssertEqual(entry.action, action)
            XCTAssertFalse(entry.action.isEmpty)
        }
    }
    
    // MARK: - Sorting Tests
    
    func testHistoryEntrySortingByTimestamp() {
        // Given
        let now = Date()
        let entries = [
            TestDataFactory.createTestHistoryEntry(id: "3", timestamp: Date(timeInterval: 3600, since: now)),
            TestDataFactory.createTestHistoryEntry(id: "1", timestamp: Date(timeInterval: -3600, since: now)),
            TestDataFactory.createTestHistoryEntry(id: "2", timestamp: now)
        ]
        
        // When
        let sortedByTimestamp = entries.sorted { $0.timestamp < $1.timestamp }
        let sortedDescending = entries.sorted { $0.timestamp > $1.timestamp }
        
        // Then
        XCTAssertEqual(sortedByTimestamp.map { $0.id }, ["1", "2", "3"])
        XCTAssertEqual(sortedDescending.map { $0.id }, ["3", "2", "1"])
    }
    
    func testHistoryEntrySortingByAction() {
        // Given
        let entries = [
            TestDataFactory.createTestHistoryEntry(id: "1", action: "Updated"),
            TestDataFactory.createTestHistoryEntry(id: "2", action: "Added"),
            TestDataFactory.createTestHistoryEntry(id: "3", action: "Deleted")
        ]
        
        // When
        let sortedByAction = entries.sorted { $0.action < $1.action }
        
        // Then
        XCTAssertEqual(sortedByAction.map { $0.action }, ["Added", "Deleted", "Updated"])
    }
    
    // MARK: - JSON Structure Tests
    
    func testHistoryEntryJSONStructure() throws {
        // Given
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "Stock Updated",
            details: "Updated from 50 to 75 units"
        )
        
        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(historyEntry)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"id\""))
        XCTAssertTrue(jsonString.contains("\"medicineId\""))
        XCTAssertTrue(jsonString.contains("\"userId\""))
        XCTAssertTrue(jsonString.contains("\"action\""))
        XCTAssertTrue(jsonString.contains("\"details\""))
        XCTAssertTrue(jsonString.contains("\"timestamp\""))
        XCTAssertTrue(jsonString.contains("history-123"))
        XCTAssertTrue(jsonString.contains("medicine-456"))
        XCTAssertTrue(jsonString.contains("Stock Updated"))
    }
    
    // MARK: - Filtering Tests
    
    func testHistoryEntryFiltering() {
        // Given
        let entries = [
            TestDataFactory.createTestHistoryEntry(medicineId: "med-1", action: "Added"),
            TestDataFactory.createTestHistoryEntry(medicineId: "med-2", action: "Updated"),
            TestDataFactory.createTestHistoryEntry(medicineId: "med-1", action: "Deleted"),
            TestDataFactory.createTestHistoryEntry(medicineId: "med-3", action: "Added")
        ]
        
        // When
        let med1Entries = entries.filter { $0.medicineId == "med-1" }
        let addedEntries = entries.filter { $0.action == "Added" }
        
        // Then
        XCTAssertEqual(med1Entries.count, 2)
        XCTAssertEqual(addedEntries.count, 2)
        XCTAssertTrue(med1Entries.allSatisfy { $0.medicineId == "med-1" })
        XCTAssertTrue(addedEntries.allSatisfy { $0.action == "Added" })
    }
}
