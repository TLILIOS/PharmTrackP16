import Foundation

enum ExportError: LocalizedError {
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .unknownError:
            return "Erreur inconnue lors de l'export."
        }
    }
}