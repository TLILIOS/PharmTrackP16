import Foundation

// Fichier de compatibilité temporaire - à supprimer une fois les références nettoyées dans le projet Xcode
// Ce fichier existe uniquement pour éviter l'erreur de build "Build input file cannot be found"

// La classe vide ci-dessous ne sera pas utilisée, mais permet au projet de compiler
class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // Propriétés vides pour la compatibilité
    let getMedicineUseCase: Any? = nil
    let adjustStockUseCase: Any? = nil
}
