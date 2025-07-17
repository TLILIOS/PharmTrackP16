
import Foundation
import SwiftUI

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case success
    case error(String)
}

@MainActor
class MedicineFormViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getMedicineUseCase: GetMedicineUseCaseProtocol
    private let getAislesUseCase: GetAislesUseCaseProtocol
    private let addMedicineUseCase: AddMedicineUseCaseProtocol
    private let updateMedicineUseCase: UpdateMedicineUseCaseProtocol
    
    @Published private(set) var medicine: Medicine?
    @Published private(set) var aisles: [Aisle] = []
    @Published private(set) var state: ViewState = .idle
    
    // MARK: - Computed Properties
    
    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
    
    // MARK: - Initialization
    
    init(
        getMedicineUseCase: GetMedicineUseCaseProtocol,
        getAislesUseCase: GetAislesUseCaseProtocol,
        addMedicineUseCase: AddMedicineUseCaseProtocol,
        updateMedicineUseCase: UpdateMedicineUseCaseProtocol,
        medicine: Medicine? = nil
    ) {
        self.getMedicineUseCase = getMedicineUseCase
        self.getAislesUseCase = getAislesUseCase
        self.addMedicineUseCase = addMedicineUseCase
        self.updateMedicineUseCase = updateMedicineUseCase
        self.medicine = medicine
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    func resetError() {
        if case .error = state {
            state = .idle
        }
    }
    
    @MainActor
    func fetchAisles() async {
        state = .loading
        
        do {
            aisles = try await getAislesUseCase.execute()
            state = .loaded
        } catch {
            state = .error("Erreur lors du chargement des rayons: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addMedicine(_ medicine: Medicine) async {
        state = .loading
        
        do {
            try await addMedicineUseCase.execute(medicine: medicine)
            self.medicine = medicine
            
            // Notifier l'ajout du nouveau médicament
            NotificationCenter.default.post(name: Notification.Name("MedicineAdded"), object: medicine)
            
            state = .success
        } catch {
            state = .error("Erreur lors de l'ajout du médicament: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func updateMedicine(_ medicine: Medicine) async {
        state = .loading
        
        do {
            try await updateMedicineUseCase.execute(medicine: medicine)
            self.medicine = medicine
            
            // Notifier la mise à jour du médicament
            NotificationCenter.default.post(name: Notification.Name("MedicineUpdated"), object: medicine)
            
            state = .success
        } catch {
            state = .error("Erreur lors de la mise à jour du médicament: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func refreshMedicine(id: String) async {
        state = .loading
        
        do {
            let refreshedMedicine = try await getMedicineUseCase.execute(id: id)
            self.medicine = refreshedMedicine
            state = .loaded
        } catch {
            state = .error("Erreur lors du chargement: \(error.localizedDescription)")
        }
    }
}
