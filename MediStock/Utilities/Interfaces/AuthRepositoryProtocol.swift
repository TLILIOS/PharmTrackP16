import Foundation
import Combine

protocol AuthRepositoryProtocol {
    /// L'utilisateur actuellement authentifié, nil si aucun
    var currentUser: User? { get }
    
    /// Un publisher qui émet à chaque changement d'état d'authentification
    var authStateDidChange: AnyPublisher<User?, Never> { get }
    
    /// Connecte un utilisateur avec email et mot de passe
    /// - Parameters:
    ///   - email: L'email de l'utilisateur
    ///   - password: Le mot de passe de l'utilisateur
    /// - Returns: L'utilisateur connecté
    /// - Throws: AuthError en cas d'échec
    func signIn(email: String, password: String) async throws -> User
    
    /// Crée un nouveau compte utilisateur
    /// - Parameters:
    ///   - email: L'email de l'utilisateur
    ///   - password: Le mot de passe de l'utilisateur
    /// - Returns: L'utilisateur créé
    /// - Throws: AuthError en cas d'échec
    func signUp(email: String, password: String) async throws -> User
    
    /// Déconnecte l'utilisateur actuel
    /// - Throws: AuthError en cas d'échec
    func signOut() async throws
    
    /// Envoie un email de réinitialisation du mot de passe
    /// - Parameter email: L'email de l'utilisateur
    /// - Throws: AuthError en cas d'échec
    func resetPassword(email: String) async throws
    
    /// Met à jour le profil de l'utilisateur
    /// - Parameter user: L'utilisateur avec les informations mises à jour
    /// - Throws: AuthError en cas d'échec
    func updateUserProfile(user: User) async throws
}
