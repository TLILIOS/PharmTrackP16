import XCTest
import Combine
@testable import MediStock

// MARK: - Pure Unit Tests (No Firebase Dependencies)

@MainActor
final class AuthRepositoryUnitTests: XCTestCase, Sendable {
    
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
    
    // MARK: - Auth Error Tests
    
    func testAuthErrorEquality() {
        // Given
        let error1 = AuthError.invalidEmail
        let error2 = AuthError.invalidEmail
        let error3 = AuthError.wrongPassword
        
        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    func testAuthErrorDescription() {
        // Given
        let errors: [AuthError] = [
            .invalidEmail,
            .wrongPassword,
            .userNotFound,
            .emailAlreadyInUse,
            .weakPassword,
            .networkError,
            .unknownError(NSError(domain: "Test", code: 1, userInfo: nil))
        ]
        
        // Then
        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
    
    func testAuthErrorUnknownErrorWrapping() {
        // Given
        let originalError = NSError(domain: "TestDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "Test Error"])
        let authError = AuthError.unknownError(originalError)
        
        // When
        if case .unknownError(let wrappedError) = authError {
            let nsError = wrappedError as NSError
            
            // Then
            XCTAssertEqual(nsError.domain, "TestDomain")
            XCTAssertEqual(nsError.code, 42)
            XCTAssertEqual(nsError.localizedDescription, "Test Error")
        } else {
            XCTFail("Should be unknownError case")
        }
    }
    
    // MARK: - User Model Tests
    
    func testUserInitialization() {
        // Given
        let id = "test-user-id"
        let email = "test@example.com"
        let displayName = "Test User"
        
        // When
        let user = User(id: id, email: email, displayName: displayName)
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
    }
    
    func testUserWithOptionalDisplayName() {
        // Given
        let id = "test-user-id"
        let email = "test@example.com"
        
        // When
        let user = User(id: id, email: email, displayName: nil)
        
        // Then
        XCTAssertEqual(user.id, id)
        XCTAssertEqual(user.email, email)
        XCTAssertNil(user.displayName)
    }
    
    func testUserEquality() {
        // Given
        let user1 = User(id: "1", email: "test@example.com", displayName: "Test")
        let user2 = User(id: "1", email: "test@example.com", displayName: "Test")
        let user3 = User(id: "2", email: "other@example.com", displayName: "Other")
        
        // Then
        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }
    
    // MARK: - Email Validation Logic Tests
    
    func testValidEmailFormats() {
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+label@example.org",
            "firstname.lastname@example.com",
            "email@subdomain.example.com",
            "firstname-lastname@example.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(isValidEmailFormat(email), "Email '\(email)' should be valid")
        }
    }
    
    func testInvalidEmailFormats() {
        let invalidEmails = [
            "",
            "invalid-email",
            "@example.com",
            "user@",
            "user@localhost",
            "user name@example.com", // space
            "user@example", // no TLD
            "user@@example.com" // double @
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(isValidEmailFormat(email), "Email '\(email)' should be invalid")
        }
    }
    
    // MARK: - Password Validation Logic Tests
    
    func testValidPasswords() {
        let validPasswords = [
            "password123",
            "MySecurePassword!",
            "123456789",
            "P@ssw0rd",
            "abcdef" // minimum 6 chars
        ]
        
        for password in validPasswords {
            XCTAssertTrue(isValidPasswordFormat(password), "Password should be valid")
        }
    }
    
    func testInvalidPasswords() {
        let invalidPasswords = [
            "",
            "12345", // too short
            "pwd",   // too short
            "a",     // too short
            "12"     // too short
        ]
        
        for password in invalidPasswords {
            XCTAssertFalse(isValidPasswordFormat(password), "Password should be invalid")
        }
    }
    
    // MARK: - Input Sanitization Tests
    
    func testEmailSanitization() {
        let testCases = [
            ("  test@example.com  ", "test@example.com"),
            ("TEST@EXAMPLE.COM", "test@example.com"),
            ("Test@Example.Com", "test@example.com")
        ]
        
        for (input, expected) in testCases {
            XCTAssertEqual(sanitizeEmail(input), expected)
        }
    }
    
    func testPasswordSanitization() {
        let testCases = [
            ("  password123  ", "password123"), // trim whitespace
            ("password123", "password123"), // no change needed
        ]
        
        for (input, expected) in testCases {
            XCTAssertEqual(sanitizePassword(input), expected)
        }
    }
    
    // MARK: - Security Tests
    
    func testMaliciousInputHandling() {
        let maliciousInputs = [
            "<script>alert('xss')</script>",
            "'; DROP TABLE users; --",
            "\\0\\x01\\x02",
            String(repeating: "a", count: 10000), // very long string
            "test@example.com<script>",
            "password'; DELETE FROM users; --"
        ]
        
        // Test that malicious inputs don't cause crashes
        for input in maliciousInputs {
            XCTAssertNoThrow({
                let _ = isValidEmailFormat(input)
                let _ = isValidPasswordFormat(input)
                let _ = sanitizeEmail(input)
                let _ = sanitizePassword(input)
            }())
        }
    }
    
    // MARK: - Performance Tests
    
    func testEmailValidationPerformance() {
        let emails = Array(repeating: "test@example.com", count: 1000)
        
        measure {
            for email in emails {
                _ = isValidEmailFormat(email)
            }
        }
    }
    
    func testPasswordValidationPerformance() {
        let passwords = Array(repeating: "password123", count: 1000)
        
        measure {
            for password in passwords {
                _ = isValidPasswordFormat(password)
            }
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentValidation() async {
        let expectation = XCTestExpectation(description: "Concurrent validation")
        expectation.expectedFulfillmentCount = 100
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let email = "test\(i)@example.com"
                    let password = "password\(i)"
                    
                    _ = isValidEmailFormat(email)
                    _ = isValidPasswordFormat(password)
                    
                    await MainActor.run {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Edge Cases
    
    func testVeryLongEmailValidation() {
        let longEmail = String(repeating: "a", count: 1000) + "@example.com"
        
        // Should handle gracefully without crashing
        XCTAssertNoThrow({
            _ = isValidEmailFormat(longEmail)
        }())
    }
    
    func testVeryLongPasswordValidation() {
        let longPassword = String(repeating: "a", count: 10000)
        
        // Should handle gracefully without crashing
        XCTAssertNoThrow({
            _ = isValidPasswordFormat(longPassword)
        }())
    }
    
    func testUnicodeInEmailAndPassword() {
        let unicodeEmail = "tëst@éxämplé.com"
        let unicodePassword = "pässwörd123"
        
        XCTAssertNoThrow({
            _ = isValidEmailFormat(unicodeEmail)
            _ = isValidPasswordFormat(unicodePassword)
        }())
    }
}

// MARK: - Helper Functions (Pure Logic)

private func isValidEmailFormat(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

private func isValidPasswordFormat(_ password: String) -> Bool {
    return password.count >= 6
}

private func sanitizeEmail(_ email: String) -> String {
    return email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

private func sanitizePassword(_ password: String) -> String {
    return password.trimmingCharacters(in: .whitespacesAndNewlines)
}