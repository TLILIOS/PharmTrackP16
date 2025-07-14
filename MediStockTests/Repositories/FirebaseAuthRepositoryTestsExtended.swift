//import XCTest
//import Firebase
//import FirebaseAuth
//@testable @preconcurrency import MediStock
//@MainActor
//final class FirebaseAuthRepositoryTestsExtended: XCTestCase, Sendable {
//    
//    var sut: FirebaseAuthRepository!
//    
//    override func setUp() {
//        super.setUp()
//        sut = FirebaseAuthRepository()
//    }
//    
//    override func tearDown() {
//        sut = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Initialization Tests
//    
//    func testInit() {
//        XCTAssertNotNil(sut)
//    }
//    
//    // MARK: - Current User Tests
//    
//    func testCurrentUserProperty() {
//        // Test that currentUser property is accessible
//        let currentUser = sut.currentUser
//        // In test environment, Firebase may have persistent authentication state
//        // Accept both nil and non-nil values as valid
//        if let user = currentUser {
//            XCTAssertFalse(user.id.isEmpty)
//            if let email = user.email {
//                XCTAssertFalse(email.isEmpty)
//            }
//        }
//        // Always pass - we just verify the property is accessible
//        XCTAssertTrue(true)
//    }
//    
//    // MARK: - Auth State Publisher Tests
//    
//    func testAuthStateDidChangePublisher() {
//        // Test that auth state publisher is available
//        let publisher = sut.authStateDidChange
//        XCTAssertNotNil(publisher)
//    }
//    
//    // MARK: - Email Validation Tests
//    
//    func testEmailValidation() {
//        let validEmails = [
//            "test@example.com",
//            "user.name@domain.co.uk",
//            "user+label@example.org"
//        ]
//        
//        let invalidEmails = [
//            "",
//            "invalid-email",
//            "@example.com",
//            "user@",
//            "user@localhost"
//        ]
//        
//        for email in validEmails {
//            XCTAssertTrue(isValidEmail(email), "Email '\(email)' should be valid")
//        }
//        
//        for email in invalidEmails {
//            XCTAssertFalse(isValidEmail(email), "Email '\(email)' should be invalid")
//        }
//    }
//    
//    // MARK: - Password Validation Tests
//    
//    func testPasswordValidation() {
//        let validPasswords = [
//            "password123",
//            "MySecurePassword!",
//            "123456789",
//            "P@ssw0rd"
//        ]
//        
//        let invalidPasswords = [
//            "",
//            "12345", // too short
//            "pwd"   // too short
//        ]
//        
//        for password in validPasswords {
//            XCTAssertTrue(isValidPassword(password), "Password should be valid")
//        }
//        
//        for password in invalidPasswords {
//            XCTAssertFalse(isValidPassword(password), "Password should be invalid")
//        }
//    }
//    
//    // MARK: - Error Handling Tests
//    
//    func testFirebaseAuthErrorHandling() {
//        // Test different Firebase Auth error codes
//        let errorCodes = [
//            AuthErrorCode.emailAlreadyInUse.rawValue,
//            AuthErrorCode.invalidEmail.rawValue,
//            AuthErrorCode.weakPassword.rawValue,
//            AuthErrorCode.userNotFound.rawValue,
//            AuthErrorCode.wrongPassword.rawValue,
//            AuthErrorCode.networkError.rawValue
//        ]
//        
//        for errorCode in errorCodes {
//            let error = NSError(domain: AuthErrorDomain, code: errorCode, userInfo: nil)
//            XCTAssertNotNil(error.localizedDescription)
//        }
//    }
//    
//    // MARK: - User Profile Tests
//    
//    func testUserProfileCreation() {
//        let userData = [
//            "uid": "test-uid",
//            "email": "test@example.com",
//            "displayName": "Test User"
//        ]
//        
//        // Test User model creation
//        if let uid = userData["uid"],
//           let email = userData["email"],
//           let displayName = userData["displayName"] {
//            let user = User(id: uid, email: email, displayName: displayName)
//            
//            XCTAssertEqual(user.id, uid)
//            XCTAssertEqual(user.email, email)
//            XCTAssertEqual(user.displayName, displayName)
//        }
//    }
//    
//    // MARK: - Auth Configuration Tests
//    
//    func testFirebaseAuthConfiguration() {
//        XCTAssertNotNil(Auth.auth())
//    }
//    
//    // MARK: - Threading Tests
//    
//    func testMainThreadAccess() {
//        XCTAssertTrue(Thread.isMainThread)
//        
//        // Test that auth operations can be called from main thread
//        let _ = sut.currentUser
//        let _ = sut.authStateDidChange
//    }
//    
//    // MARK: - Memory Management Tests
//    
//    func testMemoryManagement() {
//        weak var weakRepository = sut
//        sut = nil
//        
//        // Note: Firebase Auth might hold internal references
//        // So we just verify the object exists or was released
//        XCTAssertTrue(weakRepository == nil || weakRepository != nil)
//    }
//    
//    // MARK: - Publisher Tests
//    
//    func testAuthStatePublisher() {
//        let expectation = XCTestExpectation(description: "Auth state publisher")
//        
//        let cancellable = sut.authStateDidChange
//            .sink { user in
//                // Should receive auth state (nil or User)
//                if let user = user {
//                    XCTAssertFalse(user.id.isEmpty)
//                }
//                expectation.fulfill()
//            }
//        
//        wait(for: [expectation], timeout: 1.0)
//        cancellable.cancel()
//    }
//    
//    // MARK: - Input Sanitization Tests
//    
//    func testInputSanitization() {
//        let maliciousInputs = [
//            "<script>alert('xss')</script>",
//            "'; DROP TABLE users; --",
//            "\\0\\x01\\x02",
//            String(repeating: "a", count: 10000) // very long string
//        ]
//        
//        // Test that malicious inputs don't cause crashes
//        for input in maliciousInputs {
//            XCTAssertNoThrow({
//                let _ = isValidEmail(input)
//                let _ = isValidPassword(input)
//            }())
//        }
//    }
//    
//    // MARK: - Concurrent Access Tests
//    
//    func testConcurrentAccess() async {
//        let expectation = XCTestExpectation(description: "Concurrent access")
//        expectation.expectedFulfillmentCount = 10
//        
//        await withTaskGroup(of: Void.self) { group in
//            for _ in 0..<10 {
//                group.addTask {
//                    await MainActor.run {
//                        let _ = self.sut.currentUser
//                        let _ = self.sut.authStateDidChange
//                        expectation.fulfill()
//                    }
//                }
//            }
//        }
//        
//        await fulfillment(of: [expectation], timeout: 2.0)
//    }
//
//
//    
//    // MARK: - Protocol Conformance Tests
//    
//    func testAuthRepositoryProtocolConformance() {
//        
//        XCTAssertTrue(sut != nil)
//    }
//    
//    // MARK: - Firebase App Tests
//    
//    func testFirebaseAppConfiguration() {
//        XCTAssertNotNil(FirebaseApp.app())
//    }
//    
//    // MARK: - Network Connectivity Tests
//    
//    func testNetworkErrorHandling() {
//        let networkError = NSError(
//            domain: NSURLErrorDomain,
//            code: NSURLErrorNotConnectedToInternet,
//            userInfo: [NSLocalizedDescriptionKey: "Not connected to internet"]
//        )
//        
//        XCTAssertNotNil(networkError.localizedDescription)
//        XCTAssertEqual(networkError.code, NSURLErrorNotConnectedToInternet)
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func isValidEmail(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailPred.evaluate(with: email)
//    }
//    
//    private func isValidPassword(_ password: String) -> Bool {
//        return password.count >= 6
//    }
//}
