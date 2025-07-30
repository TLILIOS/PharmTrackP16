import Foundation

// MARK: - Erreurs de validation métier
enum ValidationError: LocalizedError {
    // Erreurs communes
    case emptyName
    case nameTooLong(maxLength: Int)
    case nameAlreadyExists(name: String)
    case invalidId
    
    // Erreurs Aisle
    case invalidColorFormat(provided: String)
    case invalidIcon(provided: String)
    case tooManyAisles(max: Int)
    
    // Erreurs Medicine
    case negativeQuantity(field: String)
    case invalidMaxQuantity
    case invalidThresholds(critical: Int, warning: Int)
    case expiredDate(date: Date)
    case invalidAisleReference(aisleId: String)
    case invalidUnit
    case missingRequiredField(field: String)
    
    var errorDescription: String? {
        switch self {
        // Erreurs communes
        case .emptyName:
            return "Le nom ne peut pas être vide"
        case .nameTooLong(let maxLength):
            return "Le nom ne peut pas dépasser \(maxLength) caractères"
        case .nameAlreadyExists(let name):
            return "Un élément avec le nom '\(name)' existe déjà"
        case .invalidId:
            return "L'identifiant est invalide"
            
        // Erreurs Aisle
        case .invalidColorFormat(let provided):
            return "Format de couleur invalide '\(provided)'. Utilisez le format #RRGGBB"
        case .invalidIcon(let provided):
            return "Icône SF Symbol '\(provided)' invalide ou non disponible"
        case .tooManyAisles(let max):
            return "Vous avez atteint la limite de \(max) rayons"
            
        // Erreurs Medicine
        case .negativeQuantity(let field):
            return "La valeur de '\(field)' ne peut pas être négative"
        case .invalidMaxQuantity:
            return "La quantité maximale doit être supérieure ou égale à la quantité actuelle"
        case .invalidThresholds(let critical, let warning):
            return "Le seuil critique (\(critical)) doit être inférieur au seuil d'alerte (\(warning))"
        case .expiredDate(let date):
            return "La date d'expiration (\(date.formattedDate)) est déjà passée"
        case .invalidAisleReference(let aisleId):
            return "Le rayon sélectionné (ID: \(aisleId)) n'existe pas"
        case .invalidUnit:
            return "L'unité de mesure est invalide"
        case .missingRequiredField(let field):
            return "Le champ '\(field)' est obligatoire"
        }
    }
}