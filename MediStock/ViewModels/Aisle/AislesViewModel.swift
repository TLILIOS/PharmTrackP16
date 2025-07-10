import Foundation
import SwiftUI
import Combine

enum AislesViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class AislesViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getAislesUseCase: GetAislesUseCaseProtocol
    private let addAisleUseCase: AddAisleUseCaseProtocol
    private let updateAisleUseCase: UpdateAisleUseCaseProtocol
    private let deleteAisleUseCase: DeleteAisleUseCaseProtocol
    private let getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol
    
    @Published private(set) var aisles: [Aisle] = []
    @Published private(set) var medicineCountByAisle: [String: Int] = [:]
    @Published private(set) var state: AislesViewState = .idle
    @Published private(set) var isLoading: Bool = false
    
    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 300
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        getAislesUseCase: GetAislesUseCaseProtocol,
        addAisleUseCase: AddAisleUseCaseProtocol,
        updateAisleUseCase: UpdateAisleUseCaseProtocol,
        deleteAisleUseCase: DeleteAisleUseCaseProtocol,
        getMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol
    ) {
        self.getAislesUseCase = getAislesUseCase
        self.addAisleUseCase = addAisleUseCase
        self.updateAisleUseCase = updateAisleUseCase
        self.deleteAisleUseCase = deleteAisleUseCase
        self.getMedicineCountByAisleUseCase = getMedicineCountByAisleUseCase
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func fetchAisles() async {
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           !aisles.isEmpty {
            return
        }
        
        isLoading = true
        state = .loading
        
        do {
            aisles = try await getAislesUseCase.execute()
            
            // Récupérer le nombre de médicaments pour chaque rayon
            await fetchMedicineCounts()
            
            lastFetchTime = Date()
            state = .success
        } catch {
            state = .error("Erreur lors du chargement des rayons: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func fetchMedicineCounts() async {
        do {
            var counts: [String: Int] = [:]
            for aisle in aisles {
                let count = try await getMedicineCountByAisleUseCase.execute(aisleId: aisle.id)
                counts[aisle.id] = count
            }
            medicineCountByAisle = counts
        } catch {
            // Ne pas modifier l'état principal en cas d'erreur
            print("Erreur lors du chargement des compteurs de médicaments: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addAisle(name: String, description: String?, color: SwiftUI.Color, icon: String) async {
        state = .loading
        
        do {
            // Créer un nouvel objet Aisle
            let newAisle = Aisle(
                id: UUID().uuidString, // L'ID sera remplacé par Firestore
                name: name,
                description: description,
                color: color,
                icon: icon
            )
            
            // Ajouter le rayon
            try await addAisleUseCase.execute(aisle: newAisle)
            
            // Mettre à jour la liste des rayons
            aisles.append(newAisle)
            
            // Initialiser le compteur de médicaments pour ce rayon
            medicineCountByAisle[newAisle.id] = 0
            
            state = .success
        } catch {
            state = .error("Erreur lors de l'ajout du rayon: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func updateAisle(id: String, name: String, description: String?, color: SwiftUI.Color, icon: String) async {
        state = .loading
        
        do {
            // Créer un objet Aisle mis à jour
            let updatedAisle = Aisle(
                id: id,
                name: name,
                description: description,
                color: color,
                icon: icon
            )
            
            // Mettre à jour le rayon
            try await updateAisleUseCase.execute(aisle: updatedAisle)
            
            // Mettre à jour la liste des rayons
            if let index = aisles.firstIndex(where: { $0.id == id }) {
                aisles[index] = updatedAisle
            }
            
            state = .success
        } catch {
            state = .error("Erreur lors de la mise à jour du rayon: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func deleteAisle(id: String) async {
        state = .loading
        
        do {
            // Vérifier si le rayon a des médicaments associés
            let medicineCount = getMedicineCountFor(aisleId: id)
            if medicineCount > 0 {
                state = .error("Ce rayon contient \(medicineCount) médicament(s). Veuillez d'abord les déplacer ou les supprimer.")
                return
            }
            
            // Supprimer le rayon
            try await deleteAisleUseCase.execute(id: id)
            
            // Mettre à jour la liste des rayons
            aisles.removeAll(where: { $0.id == id })
            
            // Supprimer le compteur de médicaments pour ce rayon
            medicineCountByAisle.removeValue(forKey: id)
            
            state = .success
        } catch {
            state = .error("Erreur lors de la suppression du rayon: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    func getMedicineCountFor(aisleId: String) -> Int {
        return medicineCountByAisle[aisleId] ?? 0
    }
}

