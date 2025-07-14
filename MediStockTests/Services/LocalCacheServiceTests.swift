import XCTest
@testable @preconcurrency import MediStock

@MainActor
final class LocalCacheServiceTests: XCTestCase, Sendable {
    
    var cacheService: LocalCacheService!
    let testKey = "test_key"
    fileprivate let testData = TestCacheData(id: "123", name: "Test", value: 42)
    
    override func setUp() {
        super.setUp()
        cacheService = LocalCacheService(expirationTimeInterval: 60) // 1 minute for testing
    }
    
    override func tearDown() {
        cacheService.clearAll()
        cacheService = nil
        super.tearDown()
    }
    
    func testSaveAndFetch() throws {
        try cacheService.save(testData, forKey: testKey)
        
        let fetchedData: TestCacheData? = try cacheService.fetch(forKey: testKey)
        
        XCTAssertNotNil(fetchedData)
        XCTAssertEqual(fetchedData?.id, testData.id)
        XCTAssertEqual(fetchedData?.name, testData.name)
        XCTAssertEqual(fetchedData?.value, testData.value)
    }
    
    func testFetchNonExistentKey() throws {
        let fetchedData: TestCacheData? = try cacheService.fetch(forKey: "non_existent_key")
        
        XCTAssertNil(fetchedData)
    }
    
    func testSaveOverwritesExistingData() throws {
        try cacheService.save(testData, forKey: testKey)
        
        let newData = TestCacheData(id: "456", name: "New Test", value: 84)
        try cacheService.save(newData, forKey: testKey)
        
        let fetchedData: TestCacheData? = try cacheService.fetch(forKey: testKey)
        
        XCTAssertNotNil(fetchedData)
        XCTAssertEqual(fetchedData?.id, "456")
        XCTAssertEqual(fetchedData?.name, "New Test")
        XCTAssertEqual(fetchedData?.value, 84)
    }
    
    func testRemove() throws {
        try cacheService.save(testData, forKey: testKey)
        XCTAssertTrue(cacheService.exists(forKey: testKey))
        
        cacheService.remove(forKey: testKey)
        
        XCTAssertFalse(cacheService.exists(forKey: testKey))
        let fetchedData: TestCacheData? = try cacheService.fetch(forKey: testKey)
        XCTAssertNil(fetchedData)
    }
    
    func testExists() throws {
        XCTAssertFalse(cacheService.exists(forKey: testKey))
        
        try cacheService.save(testData, forKey: testKey)
        
        XCTAssertTrue(cacheService.exists(forKey: testKey))
    }
    
    func testClearAll() throws {
        try cacheService.save(testData, forKey: "key1")
        try cacheService.save(testData, forKey: "key2")
        try cacheService.save(testData, forKey: "key3")
        
        XCTAssertTrue(cacheService.exists(forKey: "key1"))
        XCTAssertTrue(cacheService.exists(forKey: "key2"))
        XCTAssertTrue(cacheService.exists(forKey: "key3"))
        
        cacheService.clearAll()
        
        XCTAssertFalse(cacheService.exists(forKey: "key1"))
        XCTAssertFalse(cacheService.exists(forKey: "key2"))
        XCTAssertFalse(cacheService.exists(forKey: "key3"))
    }
    
    func testExpirationWithShortInterval() throws {
        let shortExpirationService = LocalCacheService(expirationTimeInterval: 0.1) // 0.1 seconds
        
        try shortExpirationService.save(testData, forKey: testKey)
        XCTAssertTrue(shortExpirationService.exists(forKey: testKey))
        
        // Wait for expiration
        let expectation = XCTestExpectation(description: "Cache expiration")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(shortExpirationService.exists(forKey: testKey))
        let fetchedData: TestCacheData? = try shortExpirationService.fetch(forKey: testKey)
        XCTAssertNil(fetchedData)
        
        shortExpirationService.clearAll()
    }
    
    func testSaveWithSpecialCharactersInKey() throws {
        let specialKeys = [
            "key with spaces",
            "key@with#special$characters",
            "key/with\\slashes",
            "key?with&query=params",
            "key_with_underscores",
            "key-with-hyphens"
        ]
        
        for (index, key) in specialKeys.enumerated() {
            let data = TestCacheData(id: "\(index)", name: "Test \(index)", value: index)
            try cacheService.save(data, forKey: key)
            
            let fetchedData: TestCacheData? = try cacheService.fetch(forKey: key)
            XCTAssertNotNil(fetchedData)
            XCTAssertEqual(fetchedData?.id, "\(index)")
        }
    }
    
    func testSaveDifferentDataTypes() throws {
        // Test with String
        try cacheService.save("Hello World", forKey: "string_key")
        let stringData: String? = try cacheService.fetch(forKey: "string_key")
        XCTAssertEqual(stringData, "Hello World")
        
        // Test with Int
        try cacheService.save(42, forKey: "int_key")
        let intData: Int? = try cacheService.fetch(forKey: "int_key")
        XCTAssertEqual(intData, 42)
        
        // Test with Array
        let arrayData = [1, 2, 3, 4, 5]
        try cacheService.save(arrayData, forKey: "array_key")
        let fetchedArray: [Int]? = try cacheService.fetch(forKey: "array_key")
        XCTAssertEqual(fetchedArray, arrayData)
        
        // Test with Dictionary
        let dictData = ["key1": "value1", "key2": "value2"]
        try cacheService.save(dictData, forKey: "dict_key")
        let fetchedDict: [String: String]? = try cacheService.fetch(forKey: "dict_key")
        XCTAssertEqual(fetchedDict, dictData)
    }
    
    func testInitializationWithDefaultExpiration() {
        let defaultService = LocalCacheService()
        XCTAssertNotNil(defaultService)
        
        // Test that it works
        do {
            try defaultService.save(testData, forKey: testKey)
            let fetchedData: TestCacheData? = try defaultService.fetch(forKey: testKey)
            XCTAssertNotNil(fetchedData)
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
        
        defaultService.clearAll()
    }
    
    func testInitializationWithCustomExpiration() {
        let customService = LocalCacheService(expirationTimeInterval: 3600) // 1 hour
        XCTAssertNotNil(customService)
        
        do {
            try customService.save(testData, forKey: testKey)
            XCTAssertTrue(customService.exists(forKey: testKey))
        } catch {
            XCTFail("Should not throw error: \(error)")
        }
        
        customService.clearAll()
    }
    
    func testRemoveNonExistentKey() {
        // Should not crash when removing non-existent key
        cacheService.remove(forKey: "non_existent_key")
        XCTAssertTrue(true) // If we reach here, no crash occurred
    }
    
    func testConcurrentAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        let cacheService = self.cacheService!
        for i in 0..<10 {
            DispatchQueue.global().async {
                do {
                    let data = TestCacheData(id: "\(i)", name: "Test \(i)", value: i)
                    try cacheService.save(data, forKey: "concurrent_key_\(i)")
                    expectation.fulfill()
                } catch {
                    XCTFail("Concurrent save failed: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify all items were saved
        for i in 0..<10 {
            XCTAssertTrue(cacheService.exists(forKey: "concurrent_key_\(i)"))
        }
    }
}

// Test data structure
fileprivate struct TestCacheData: Codable, Equatable {
    let id: String
    let name: String
    let value: Int
}
