import XCTest
@testable import MediStock

final class AppStateTests: XCTestCase {
    var sut: AppState!
    
    override func setUp() {
        super.setUp()
        sut = AppState()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(sut.currentUser)
        XCTAssertTrue(sut.medicines.isEmpty)
        XCTAssertTrue(sut.aisles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFilteredMedicines() {
        // Test à implémenter
    }
    
    func testCriticalMedicines() {
        // Test à implémenter
    }
}