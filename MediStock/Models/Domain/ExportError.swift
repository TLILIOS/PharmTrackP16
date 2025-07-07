import Foundation

enum ExportError: LocalizedError {
    case unsupportedFormat
    case conversionFailed
    case fileSaveFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Format d'exportation non supporté."
        case .conversionFailed:
            return "Échec de la conversion des données pour l'exportation."
        case .fileSaveFailed:
            return "Échec de l'enregistrement du fichier d'exportation."
        }
    }
}
