import Foundation
import SwiftUI

enum MedicineFormViewState: Equatable {
    case idle
    case loading
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
    @Published private(set) var state: MedicineFormViewState = .idle
    
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
    
    @MainActor
    func fetchAisles() async {
        state = .loading
        
        do {
            aisles = try await getAislesUseCase.execute()
            state = .idle
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
            state = .idle
        } catch {
            state = .error("Erreur lors du chargement: \(error.localizedDescription)")
        }
    }
}

