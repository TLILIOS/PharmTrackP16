import Foundation
import Observation
import SwiftUI

enum DashboardViewState {
    case idle
    case loading
    case success
    case error(String)
}

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Properties
    
    private let getUserUseCase: GetUserUseCaseProtocol
    private let getMedicinesUseCase: GetMedicinesUseCaseProtocol
    private let getAislesUseCase: GetAislesUseCaseProtocol
    private let getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol
    
    @Published private(set) var state: DashboardViewState = .idle
    @Published private(set) var userName: String?
    @Published private(set) var totalMedicines: Int = 0
    @Published private(set) var totalAisles: Int = 0
    @Published private(set) var criticalStockMedicines: [Medicine] = []
    @Published private(set) var expiringMedicines: [Medicine] = []
    @Published private(set) var recentHistory: [HistoryEntry] = []
    @Published private(set) var medicines: [Medicine] = []
    @Published private(set) var aisles: [Aisle] = []
    
    // Navigation handlers - Ces propriétés seraient définies par l'AppCoordinator
    var navigateToMedicineDetailHandler: ((Medicine) -> Void)?
    var navigateToMedicineListHandler: (() -> Void)?
    var navigateToAislesHandler: (() -> Void)?
    var navigateToHistoryHandler: (() -> Void)?
    var navigateToCriticalStockHandler: (() -> Void)?
    var navigateToExpiringMedicinesHandler: (() -> Void)?
    var navigateToAdjustStockHandler: (() -> Void)?
    
    // MARK: - Initialization
    
    init(
        getUserUseCase: GetUserUseCaseProtocol,
        getMedicinesUseCase: GetMedicinesUseCaseProtocol,
        getAislesUseCase: GetAislesUseCaseProtocol,
        getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol
    ) {
        self.getUserUseCase = getUserUseCase
        self.getMedicinesUseCase = getMedicinesUseCase
        self.getAislesUseCase = getAislesUseCase
        self.getRecentHistoryUseCase = getRecentHistoryUseCase
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func fetchData() async {
        state = .loading
        
        do {
            // Récupérer l'utilisateur connecté
            let user = try await getUserUseCase.execute()
            userName = user.displayName
            
            // Récupérer les médicaments
            medicines = try await getMedicinesUseCase.execute()
            totalMedicines = medicines.count
            
            // Récupérer les rayons
            aisles = try await getAislesUseCase.execute()
            totalAisles = aisles.count
            
            // Filtrer les médicaments en stock critique
            criticalStockMedicines = medicines.filter { medicine in
                guard medicine.criticalThreshold > 0 else { return false }
                return medicine.currentQuantity <= medicine.criticalThreshold
            }.sorted { $0.currentQuantity < $1.currentQuantity }
            
            // Filtrer les médicaments avec date d'expiration proche (dans les 30 jours)
            let calendar = Calendar.current
            let thirtyDaysFromNow = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            
            expiringMedicines = medicines.filter { medicine in
                guard let expiryDate = medicine.expiryDate else { return false }
                return expiryDate <= thirtyDaysFromNow && expiryDate > Date()
            }.sorted { (med1, med2) -> Bool in
                guard let date1 = med1.expiryDate, let date2 = med2.expiryDate else {
                    return false
                }
                return date1 < date2
            }
            
            // Récupérer l'historique récent (les 10 dernières entrées)
            recentHistory = try await getRecentHistoryUseCase.execute(limit: 10)
            
            state = .success
        } catch {
            state = .error("Erreur lors du chargement des données: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Navigation Methods
    
    func navigateToMedicineDetail(_ medicine: Medicine) {
        navigateToMedicineDetailHandler?(medicine)
    }
    
    func navigateToMedicineList() {
        navigateToMedicineListHandler?()
    }
    
    func navigateToAisles() {
        navigateToAislesHandler?()
    }
    
    func navigateToHistory() {
        navigateToHistoryHandler?()
    }
    
    func navigateToCriticalStock() {
        navigateToCriticalStockHandler?()
    }
    
    func navigateToExpiringMedicines() {
        navigateToExpiringMedicinesHandler?()
    }
    
    func navigateToAdjustStock() {
        navigateToAdjustStockHandler?()
    }
    
    // MARK: - Helper Methods
    
    func getMedicineName(for id: String) -> String {
        medicines.first(where: { $0.id == id })?.name ?? "Médicament inconnu"
    }
}


@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Properties
    
    private let searchMedicineUseCase: SearchMedicineUseCaseProtocol
    private let searchAisleUseCase: SearchAisleUseCaseProtocol
    
    @Published private(set) var medicineResults: [Medicine] = []
    @Published private(set) var aisleResults: [Aisle] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    // MARK: - Initialization
    
    init(
        searchMedicineUseCase: SearchMedicineUseCaseProtocol,
        searchAisleUseCase: SearchAisleUseCaseProtocol
    ) {
        self.searchMedicineUseCase = searchMedicineUseCase
        self.searchAisleUseCase = searchAisleUseCase
    }
    
    // MARK: - Methods
    
    @MainActor
    func search(query: String) async {
        if query.isEmpty {
            medicineResults = []
            aisleResults = []
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            async let medicines = searchMedicineUseCase.execute(query: query)
            async let aisles = searchAisleUseCase.execute(query: query)
            
            let results = try await (medicines, aisles)
            medicineResults = results.0
            aisleResults = results.1
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
