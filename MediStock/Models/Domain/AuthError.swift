import Foundation

enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknownError(Error?)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "L'adresse e-mail n'est pas valide."
        case .invalidPassword:
            return "Le mot de passe n'est pas valide."
        case .weakPassword:
            return "Le mot de passe est trop faible. Utilisez au moins 6 caractères."
        case .emailAlreadyInUse:
            return "Cette adresse e-mail est déjà utilisée par un autre compte."
        case .userNotFound:
            return "Aucun utilisateur ne correspond à cette adresse e-mail."
        case .wrongPassword:
            return "Le mot de passe est incorrect."
        case .networkError:
            return "Une erreur réseau est survenue. Vérifiez votre connexion internet."
        case .unknownError(let error):
            return error?.localizedDescription ?? "Une erreur inconnue est survenue."
        }
    }
}
