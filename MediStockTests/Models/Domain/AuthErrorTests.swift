import XCTest
@testable import MediStock

final class AuthErrorTests: XCTestCase {
    
    func testAuthErrorDescriptions() {
        let invalidEmailError = AuthError.invalidEmail
        XCTAssertEqual(invalidEmailError.errorDescription, "L'adresse e-mail n'est pas valide.")
        
        let invalidPasswordError = AuthError.invalidPassword
        XCTAssertEqual(invalidPasswordError.errorDescription, "Le mot de passe n'est pas valide.")
        
        let weakPasswordError = AuthError.weakPassword
        XCTAssertEqual(weakPasswordError.errorDescription, "Le mot de passe est trop faible. Utilisez au moins 6 caractères.")
        
        let emailAlreadyInUseError = AuthError.emailAlreadyInUse
        XCTAssertEqual(emailAlreadyInUseError.errorDescription, "Cette adresse e-mail est déjà utilisée par un autre compte.")
        
        let userNotFoundError = AuthError.userNotFound
        XCTAssertEqual(userNotFoundError.errorDescription, "Aucun utilisateur ne correspond à cette adresse e-mail.")
        
        let wrongPasswordError = AuthError.wrongPassword
        XCTAssertEqual(wrongPasswordError.errorDescription, "Le mot de passe est incorrect.")
        
        let networkError = AuthError.networkError
        XCTAssertEqual(networkError.errorDescription, "Une erreur réseau est survenue. Vérifiez votre connexion internet.")
    }
    
    func testUnknownErrorWithNilError() {
        let unknownError = AuthError.unknownError(nil)
        XCTAssertEqual(unknownError.errorDescription, "Une erreur inconnue est survenue.")
    }
    
    func testUnknownErrorWithSpecificError() {
        let specificError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        let unknownError = AuthError.unknownError(specificError)
        XCTAssertEqual(unknownError.errorDescription, "Test error message")
    }
    
    func testAuthErrorEquality() {
        XCTAssertEqual(AuthError.invalidEmail, AuthError.invalidEmail)
        XCTAssertEqual(AuthError.weakPassword, AuthError.weakPassword)
        XCTAssertNotEqual(AuthError.invalidEmail, AuthError.weakPassword)
    }
    
    func testAuthErrorLocalizedErrorConformance() {
        let error: LocalizedError = AuthError.invalidEmail
        XCTAssertNotNil(error.errorDescription)
    }
    
    func testAllAuthErrorCases() {
        let allCases: [AuthError] = [
            .invalidEmail,
            .invalidPassword,
            .weakPassword,
            .emailAlreadyInUse,
            .userNotFound,
            .wrongPassword,
            .networkError,
            .unknownError(nil)
        ]
        
        for authError in allCases {
            XCTAssertNotNil(authError.errorDescription)
            XCTAssertFalse(authError.errorDescription!.isEmpty)
        }
    }
}