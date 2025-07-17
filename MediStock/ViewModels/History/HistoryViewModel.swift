import Foundation
import SwiftUI
import Combine

enum HistoryViewState: Equatable {
    case idle
    case loading
    case success
    case error(String)
}


@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getHistoryUseCase: GetHistoryUseCaseProtocol
    private let getMedicinesUseCase: GetMedicinesUseCaseProtocol
    
    @Published private(set) var history: [HistoryEntry] = []
    @Published private(set) var medicines: [Medicine] = []
    @Published private(set) var state: HistoryViewState = .idle
    @Published private(set) var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        getHistoryUseCase: GetHistoryUseCaseProtocol,
        getMedicinesUseCase: GetMedicinesUseCaseProtocol
    ) {
        self.getHistoryUseCase = getHistoryUseCase
        self.getMedicinesUseCase = getMedicinesUseCase
    }
    
    // Convenience initializer for specific medicine
    convenience init(
        medicineId: String,
        getHistoryUseCase: GetHistoryUseCaseProtocol,
        medicineRepository: any MedicineRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol
    ) {
        self.init(
            getHistoryUseCase: getHistoryUseCase,
            getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: medicineRepository)
        )
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func fetchHistory() async {
        isLoading = true
        state = .loading
        
        do {
            history = try await getHistoryUseCase.execute()
            
            // Tri par date décroissante (plus récent d'abord)
            history.sort { $0.timestamp > $1.timestamp }
            
            state = .success
        } catch {
            state = .error("Erreur lors du chargement de l'historique: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchMedicines() async {
        do {
            medicines = try await getMedicinesUseCase.execute()
        } catch {
            // Ne pas modifier l'état principal en cas d'erreur
            print("Erreur lors du chargement des médicaments: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadHistoryForMedicine(medicineId: String) async {
        isLoading = true
        state = .loading
        
        do {
            let allHistory = try await getHistoryUseCase.execute()
            history = allHistory.filter { $0.medicineId == medicineId }
                .sorted { $0.timestamp > $1.timestamp }
            
            medicines = try await getMedicinesUseCase.execute()
            
            state = .success
        } catch {
            state = .error("Erreur lors du chargement de l'historique: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd_MM_yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}


