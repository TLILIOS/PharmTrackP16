import Foundation
import Combine
import Observation

@MainActor
@Observable
class AisleFormViewModel { 
    var name: String = ""
    var description: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showingSuccessMessage: Bool = false
    
    private let addAisleUseCase: AddAisleUseCaseProtocol
    private let updateAisleUseCase: UpdateAisleUseCaseProtocol
    private let existingAisle: Aisle?
    
    var isEditing: Bool {
        existingAisle != nil
    }
    
    var title: String {
        isEditing ? "Modifier le rayon" : "Ajouter un rayon"
    }
    
    init(
        addAisleUseCase: AddAisleUseCaseProtocol,
        updateAisleUseCase: UpdateAisleUseCaseProtocol,
        aisle: Aisle? = nil
    ) {
        self.addAisleUseCase = addAisleUseCase
        self.updateAisleUseCase = updateAisleUseCase
        self.existingAisle = aisle
        
        if let aisle = aisle {
            self.name = aisle.name
            self.description = aisle.description ?? ""
        }
    }
    
    func save() async {
        guard !name.isEmpty else {
            errorMessage = "Le nom du rayon ne peut pas être vide"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingAisle = existingAisle {
                // Update existing aisle
                let updatedAisle = Aisle(
                    id: existingAisle.id,
                    name: name,
                    description: description.isEmpty ? nil : description
                )
                try await updateAisleUseCase.execute(aisle: updatedAisle)
            } else {
                // Add new aisle
                let newAisle = Aisle(
                    id: UUID().uuidString,
                    name: name,
                    description: description.isEmpty ? nil : description
                )
                try await addAisleUseCase.execute(aisle: newAisle)
            }
            
            showingSuccessMessage = true
            
            // Reset form if adding new aisle
            if existingAisle == nil {
                name = ""
                description = ""
            }
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func dismissSuccessMessage() {
        showingSuccessMessage = false
    }
    
    func dismissErrorMessage() {
        errorMessage = nil
    }
}
