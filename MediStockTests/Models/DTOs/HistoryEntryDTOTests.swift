import XCTest
@testable import MediStock

final class HistoryEntryDTOTests: XCTestCase {
    
    let testDate = Date()
    
    func testHistoryEntryDTOInitialization() {
        let historyEntryDTO = HistoryEntryDTO(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        XCTAssertEqual(historyEntryDTO.id, "history-123")
        XCTAssertEqual(historyEntryDTO.medicineId, "medicine-456")
        XCTAssertEqual(historyEntryDTO.userId, "user-789")
        XCTAssertEqual(historyEntryDTO.action, "ADDED")
        XCTAssertEqual(historyEntryDTO.details, "Added 50 units")
        XCTAssertEqual(historyEntryDTO.timestamp, testDate)
    }
    
    func testHistoryEntryDTOToDomain() {
        let historyEntryDTO = HistoryEntryDTO(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        let historyEntry = historyEntryDTO.toDomain()
        
        XCTAssertEqual(historyEntry.id, "history-123")
        XCTAssertEqual(historyEntry.medicineId, "medicine-456")
        XCTAssertEqual(historyEntry.userId, "user-789")
        XCTAssertEqual(historyEntry.action, "ADDED")
        XCTAssertEqual(historyEntry.details, "Added 50 units")
        XCTAssertEqual(historyEntry.timestamp, testDate)
    }
    
    func testHistoryEntryDTOToDomainWithNilId() {
        var historyEntryDTO = HistoryEntryDTO(
            id: nil,
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        let historyEntry = historyEntryDTO.toDomain()
        
        XCTAssertNotNil(historyEntry.id)
        XCTAssertFalse(historyEntry.id.isEmpty)
        XCTAssertEqual(historyEntry.medicineId, "medicine-456")
        XCTAssertEqual(historyEntry.userId, "user-789")
        XCTAssertEqual(historyEntry.action, "ADDED")
        XCTAssertEqual(historyEntry.details, "Added 50 units")
        XCTAssertEqual(historyEntry.timestamp, testDate)
    }
    
    func testHistoryEntryDTOFromDomain() {
        let historyEntry = HistoryEntry(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        let historyEntryDTO = HistoryEntryDTO.fromDomain(historyEntry)
        
        XCTAssertEqual(historyEntryDTO.id, "history-123")
        XCTAssertEqual(historyEntryDTO.medicineId, "medicine-456")
        XCTAssertEqual(historyEntryDTO.userId, "user-789")
        XCTAssertEqual(historyEntryDTO.action, "ADDED")
        XCTAssertEqual(historyEntryDTO.details, "Added 50 units")
        XCTAssertEqual(historyEntryDTO.timestamp, testDate)
    }
    
    func testHistoryEntryDTORoundTripConversion() {
        let originalHistoryEntry = HistoryEntry(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        let historyEntryDTO = HistoryEntryDTO.fromDomain(originalHistoryEntry)
        let convertedHistoryEntry = historyEntryDTO.toDomain()
        
        XCTAssertEqual(originalHistoryEntry.id, convertedHistoryEntry.id)
        XCTAssertEqual(originalHistoryEntry.medicineId, convertedHistoryEntry.medicineId)
        XCTAssertEqual(originalHistoryEntry.userId, convertedHistoryEntry.userId)
        XCTAssertEqual(originalHistoryEntry.action, convertedHistoryEntry.action)
        XCTAssertEqual(originalHistoryEntry.details, convertedHistoryEntry.details)
        XCTAssertEqual(originalHistoryEntry.timestamp, convertedHistoryEntry.timestamp)
    }
    
    func testHistoryEntryDTOCodable() throws {
        let historyEntryDTO = HistoryEntryDTO(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "ADDED",
            details: "Added 50 units",
            timestamp: testDate
        )
        
        let jsonData = try JSONEncoder().encode(historyEntryDTO)
        let decodedHistoryEntryDTO = try JSONDecoder().decode(HistoryEntryDTO.self, from: jsonData)
        
        XCTAssertEqual(historyEntryDTO.id, decodedHistoryEntryDTO.id)
        XCTAssertEqual(historyEntryDTO.medicineId, decodedHistoryEntryDTO.medicineId)
        XCTAssertEqual(historyEntryDTO.userId, decodedHistoryEntryDTO.userId)
        XCTAssertEqual(historyEntryDTO.action, decodedHistoryEntryDTO.action)
        XCTAssertEqual(historyEntryDTO.details, decodedHistoryEntryDTO.details)
        XCTAssertEqual(historyEntryDTO.timestamp.timeIntervalSince1970, decodedHistoryEntryDTO.timestamp.timeIntervalSince1970, accuracy: 0.001)
    }
    
    func testHistoryEntryDTODifferentActions() {
        let actions = ["ADDED", "REMOVED", "UPDATED", "DELETED", "RESTOCKED"]
        
        for action in actions {
            let historyEntryDTO = HistoryEntryDTO(
                id: "history-123",
                medicineId: "medicine-456",
                userId: "user-789",
                action: action,
                details: "Test details for \(action)",
                timestamp: testDate
            )
            
            XCTAssertEqual(historyEntryDTO.action, action)
            
            let historyEntry = historyEntryDTO.toDomain()
            XCTAssertEqual(historyEntry.action, action)
        }
    }
    
    func testHistoryEntryDTOEmptyStringValues() {
        let historyEntryDTO = HistoryEntryDTO(
            id: "",
            medicineId: "",
            userId: "",
            action: "",
            details: "",
            timestamp: testDate
        )
        
        XCTAssertEqual(historyEntryDTO.id, "")
        XCTAssertEqual(historyEntryDTO.medicineId, "")
        XCTAssertEqual(historyEntryDTO.userId, "")
        XCTAssertEqual(historyEntryDTO.action, "")
        XCTAssertEqual(historyEntryDTO.details, "")
        XCTAssertEqual(historyEntryDTO.timestamp, testDate)
    }
    
    func testHistoryEntryDTOLongDetails() {
        let longDetails = String(repeating: "A", count: 1000)
        let historyEntryDTO = HistoryEntryDTO(
            id: "history-123",
            medicineId: "medicine-456",
            userId: "user-789",
            action: "UPDATED",
            details: longDetails,
            timestamp: testDate
        )
        
        XCTAssertEqual(historyEntryDTO.details, longDetails)
        
        let historyEntry = historyEntryDTO.toDomain()
        XCTAssertEqual(historyEntry.details, longDetails)
    }
}