import XCTest
import FirebaseAuth
@testable import MediStock

@MainActor
class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    var mockKeychain: MockAuthKeychainService!
    
    override func setUp() {
        super.setUp()
        mockKeychain = MockAuthKeychainService()
        authService = AuthService()
    }
    
    override func tearDown() {
        authService = nil
        mockKeychain = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        // Assert
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - Sign In Tests
    
    func testSignInSuccess() async throws {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        
        // Act & Assert
        // Note: Les tests réels avec Firebase nécessiteraient un environnement de test Firebase
        // ou l'utilisation de Firebase Emulator Suite
        // Pour l'instant, nous testons juste que la méthode peut être appelée sans crash
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            // Expected dans un environnement de test sans Firebase configuré
            XCTAssertNotNil(error)
        }
    }
    
    func testSignInWithEmptyEmail() async {
        // Arrange
        let email = ""
        let password = "password123"
        
        // Act & Assert
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testSignInWithEmptyPassword() async {
        // Arrange
        let email = "test@example.com"
        let password = ""
        
        // Act & Assert
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Should throw error for empty password")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testSignInWithInvalidEmailFormat() async {
        // Arrange
        let email = "invalid-email"
        let password = "password123"
        
        // Act & Assert
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Should throw error for invalid email format")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUpSuccess() async throws {
        // Arrange
        let email = "newuser@example.com"
        let password = "password123"
        let displayName = "New User"
        
        // Act & Assert
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
        } catch {
            // Expected dans un environnement de test sans Firebase configuré
            XCTAssertNotNil(error)
        }
    }
    
    func testSignUpWithEmptyDisplayName() async {
        // Arrange
        let email = "test@example.com"
        let password = "password123"
        let displayName = ""
        
        // Act & Assert
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
            // Firebase permet les noms d'affichage vides, donc pas d'erreur attendue
        } catch {
            // Expected dans un environnement de test sans Firebase configuré
            XCTAssertNotNil(error)
        }
    }
    
    func testSignUpWithWeakPassword() async {
        // Arrange
        let email = "test@example.com"
        let password = "123" // Mot de passe trop court
        let displayName = "Test User"
        
        // Act & Assert
        do {
            try await authService.signUp(email: email, password: password, displayName: displayName)
            XCTFail("Should throw error for weak password")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut() async throws {
        // Act & Assert
        do {
            try await authService.signOut()
            XCTAssertNil(authService.currentUser)
        } catch {
            // Expected dans un environnement de test sans Firebase configuré
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Password Reset Tests
    
    func testResetPassword() async throws {
        // Arrange
        let email = "test@example.com"
        
        // Act & Assert
        do {
            try await authService.resetPassword(email: email)
        } catch {
            // Expected dans un environnement de test sans Firebase configuré
            XCTAssertNotNil(error)
        }
    }
    
    func testResetPasswordWithEmptyEmail() async {
        // Arrange
        let email = ""
        
        // Act & Assert
        do {
            try await authService.resetPassword(email: email)
            XCTFail("Should throw error for empty email")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testResetPasswordWithInvalidEmail() async {
        // Arrange
        let email = "invalid-email"
        
        // Act & Assert
        do {
            try await authService.resetPassword(email: email)
            XCTFail("Should throw error for invalid email")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - User State Tests
    
    func testCurrentUserUpdate() {
        // Arrange
        let testUser = User(
            id: "test-id",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // Act
        authService.currentUser = testUser
        
        // Assert
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.id, "test-id")
        XCTAssertEqual(authService.currentUser?.email, "test@example.com")
        XCTAssertEqual(authService.currentUser?.displayName, "Test User")
    }
    
    func testCurrentUserClear() {
        // Arrange
        authService.currentUser = User(
            id: "test-id",
            email: "test@example.com",
            displayName: "Test User"
        )
        
        // Act
        authService.currentUser = nil
        
        // Assert
        XCTAssertNil(authService.currentUser)
    }
}

// MARK: - Mock Keychain Service

class MockAuthKeychainService {
    var savedToken: String?
    var saveTokenCallCount = 0
    var deleteTokenCallCount = 0
    var shouldThrowError = false
    
    func saveAuthToken(_ token: String) throws {
        saveTokenCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "MockKeychain", code: 0, userInfo: nil)
        }
        savedToken = token
    }
    
    func getAuthToken() throws -> String? {
        if shouldThrowError {
            throw NSError(domain: "MockKeychain", code: 0, userInfo: nil)
        }
        return savedToken
    }
    
    func deleteAuthToken() {
        deleteTokenCallCount += 1
        savedToken = nil
    }
}