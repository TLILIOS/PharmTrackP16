import Foundation
import SwiftUI

// MARK: - Protocol de Base pour tous les ViewModels
// Élimine la duplication de la gestion d'erreurs et du loading

@MainActor
protocol ViewModelBase: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

// MARK: - Extension avec l'implémentation commune

extension ViewModelBase {
    /// Exécute une opération asynchrone avec gestion automatique du loading et des erreurs
    /// - Parameter operation: L'opération async à exécuter
    /// - Returns: Le résultat de l'opération ou nil si erreur
    @MainActor
    func performOperation<T>(_ operation: @escaping () async throws -> T) async -> T? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            return try await operation()
        } catch {
            handleError(error)
            return nil
        }
    }
    
    /// Exécute une opération sans retour avec gestion du loading et des erreurs
    @MainActor
    func performOperation(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await operation()
        } catch {
            handleError(error)
        }
    }
    
    /// Gestion centralisée des erreurs avec messages localisés
    @MainActor
    func handleError(_ error: Error) {
        // Gestion spécifique selon le type d'erreur
        if let validationError = error as? ValidationError {
            errorMessage = validationError.localizedDescription
        } else if let authError = error as? AuthError {
            errorMessage = authError.localizedDescription
        } else {
            // Message générique pour les autres erreurs
            errorMessage = "Une erreur est survenue: \(error.localizedDescription)"
        }
        
        // Log pour debug (sans exposer d'infos sensibles)
        print("❌ Erreur ViewModel: \(type(of: error)) - \(errorMessage ?? "")")
    }
    
    /// Réinitialise l'état d'erreur
    @MainActor
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Classe de Base Concrète (Optionnelle)

/// Classe de base pour les ViewModels qui préfèrent l'héritage
/// Note: En Swift, préférer la composition avec le protocol
@MainActor
class BaseViewModel: ObservableObject, ViewModelBase {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Initialisation par défaut
    init() {}
}

// MARK: - Exemple d'Utilisation

/*
 Migration d'un ViewModel existant :
 
 AVANT:
 ```swift
 class MedicineListViewModel: ObservableObject {
     @Published var isLoading = false
     @Published var errorMessage: String?
     
     func loadMedicines() async {
         isLoading = true
         errorMessage = nil
         
         do {
             medicines = try await repository.fetchMedicines()
         } catch {
             errorMessage = error.localizedDescription
         }
         
         isLoading = false
     }
 }
 ```
 
 APRÈS:
 ```swift
 class MedicineListViewModel: ObservableObject, ViewModelBase {
     @Published var isLoading = false
     @Published var errorMessage: String?
     
     func loadMedicines() async {
         medicines = await performOperation {
             try await repository.fetchMedicines()
         } ?? []
     }
 }
 ```
 
 Réduction: ~10 lignes → 3 lignes par méthode async
 */