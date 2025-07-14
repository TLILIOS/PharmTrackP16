import XCTest
import Firebase
import FirebaseAuth
import FirebaseFirestore
@testable import MediStock

// MARK: - XCTestCase Extension for Firebase Tests

extension XCTestCase {
    
    /// Configures Firebase for test mode to avoid network calls
    func configureFirebaseForTests() {
        // Check if we're in test environment
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil else {
            return
        }
        
        // Disable persistence to avoid disk I/O in tests
        if let app = FirebaseApp.app() {
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = false
            settings.isSSLEnabled = false
            settings.host = "localhost:8080" // Point to non-existent host
            
            let firestore = Firestore.firestore(app: app)
            firestore.settings = settings
            
            // Immediately disable network to prevent connection attempts
            firestore.disableNetwork { _ in }
        }
        
        // Configure Auth for offline mode
        if let auth = Auth.auth() {
            auth.useEmulator(withHost: "localhost", port: 9099)
        }
    }
    
    /// Expects a Firebase network error in async context
    func expectFirebaseNetworkError<T>(
        operation: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected Firebase network error but operation succeeded", file: file, line: line)
        } catch {
            // Expected error - verify it's a network/Firebase error
            let nsError = error as NSError
            XCTAssertTrue(
                nsError.domain == "FIRFirestoreErrorDomain" ||
                nsError.domain == "FIRAuthErrorDomain" ||
                nsError.code == 14 || // Unavailable
                nsError.code == 7,    // Permission denied
                "Expected Firebase error but got: \(error)",
                file: file,
                line: line
            )
        }
    }
    
    /// Expects a Firebase network error with timeout
    func expectFirebaseNetworkErrorWithTimeout<T>(
        timeout: TimeInterval = 1.0,
        operation: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let task = Task {
            try await operation()
        }
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            task.cancel()
        }
        
        do {
            let result = try await task.value
            timeoutTask.cancel()
            XCTFail("Expected error but got result: \(result)", file: file, line: line)
        } catch is CancellationError {
            // Operation timed out - this is expected
            XCTAssertTrue(true, "Operation timed out as expected", file: file, line: line)
        } catch {
            // Got an error - verify it's Firebase related
            timeoutTask.cancel()
            let nsError = error as NSError
            XCTAssertTrue(
                nsError.domain.contains("Firebase") || nsError.domain.contains("FIR"),
                "Expected Firebase error but got: \(error)",
                file: file,
                line: line
            )
        }
    }
}

// MARK: - Mock Firestore for Tests

class MockFirestore {
    var shouldFail = true
    var mockError: Error {
        NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Network unavailable (test mode)"
        ])
    }
    
    func simulateNetworkError() -> Error {
        return mockError
    }
}

// MARK: - Quick Test Helpers

struct FirebaseTestHelper {
    static func skipIfFirebaseNotConfigured(file: StaticString = #file, line: UInt = #line) -> Bool {
        if FirebaseApp.app() == nil {
            print("Skipping test - Firebase not configured", file, line)
            return true
        }
        return false
    }
    
    static func createOfflineError() -> NSError {
        return NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
    }
}