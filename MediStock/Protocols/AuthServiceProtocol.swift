import Foundation
import Combine

// MARK: - Protocol pour abstraction du service d'authentification

/// Protocole définissant le contrat pour les services d'authentification
/// Permet l'injection de dépendances et le testing avec mocks
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    /// Utilisateur actuellement connecté
    var currentUser: User? { get set }

    /// Publisher pour observer les changements de l'utilisateur courant
    var currentUserPublisher: AnyPublisher<User?, Never> { get }

    /// Connexion avec email et mot de passe
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    /// - Throws: Erreurs d'authentification
    func signIn(email: String, password: String) async throws

    /// Inscription d'un nouvel utilisateur
    /// - Parameters:
    ///   - email: Email de l'utilisateur
    ///   - password: Mot de passe
    ///   - displayName: Nom d'affichage
    /// - Throws: Erreurs de création de compte
    func signUp(email: String, password: String, displayName: String) async throws

    /// Déconnexion de l'utilisateur
    /// - Throws: Erreurs de déconnexion
    func signOut() async throws

    /// Réinitialisation du mot de passe
    /// - Parameter email: Email pour la réinitialisation
    /// - Throws: Erreurs d'envoi d'email
    func resetPassword(email: String) async throws

    /// Récupération du token d'authentification
    /// - Returns: Token JWT valide ou nil
    func getAuthToken() async throws -> String?
}
