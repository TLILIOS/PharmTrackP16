import Foundation

enum MedicineError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    case deleteFailed
    case unknownError(Error?)
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Le médicament demandé n'a pas été trouvé."
        case .invalidData:
            return "Les données du médicament sont invalides."
        case .saveFailed:
            return "Échec de l'enregistrement du médicament."
        case .deleteFailed:
            return "Échec de la suppression du médicament."
        case .unknownError(let error):
            return error?.localizedDescription ?? "Une erreur inconnue est survenue."
        }
    }
}

enum StockError: LocalizedError {
    case insufficientStock
    case invalidAmount
    
    var errorDescription: String? {
        switch self {
        case .insufficientStock:
            return "Stock insuffisant pour effectuer cette opération."
        case .invalidAmount:
            return "La quantité spécifiée n'est pas valide."
        }
    }
}
