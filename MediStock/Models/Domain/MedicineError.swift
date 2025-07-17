import Foundation

enum MedicineError: LocalizedError, Equatable {
    case notFound
    case invalidData
    case saveFailed
    case deleteFailed
    case invalidQuantity
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
        case .invalidQuantity:
            return "La quantité spécifiée n'est pas valide."
        case .unknownError(let error):
            return error?.localizedDescription ?? "Une erreur inconnue est survenue."
        }
    }
    
    static func == (lhs: MedicineError, rhs: MedicineError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound),
             (.invalidData, .invalidData),
             (.saveFailed, .saveFailed),
             (.deleteFailed, .deleteFailed),
             (.invalidQuantity, .invalidQuantity):
            return true
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        default:
            return false
        }
    }
}

enum StockError: LocalizedError, Equatable {
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
