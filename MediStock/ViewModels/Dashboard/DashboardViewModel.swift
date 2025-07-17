import Foundation
import Observation
import SwiftUI
import Combine

enum DashboardViewState: Equatable {
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
    
    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 300
    private var cancellables = Set<AnyCancellable>()
    
    // AppCoordinator injection pour navigation unifiée
    private weak var appCoordinator: AppCoordinator?
    
    // MARK: - Initialization
    
    init(
        getUserUseCase: GetUserUseCaseProtocol,
        getMedicinesUseCase: GetMedicinesUseCaseProtocol,
        getAislesUseCase: GetAislesUseCaseProtocol,
        getRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol,
        appCoordinator: AppCoordinator? = nil
    ) {
        self.getUserUseCase = getUserUseCase
        self.getMedicinesUseCase = getMedicinesUseCase
        self.getAislesUseCase = getAislesUseCase
        self.getRecentHistoryUseCase = getRecentHistoryUseCase
        self.appCoordinator = appCoordinator
        
        // Écouter les notifications de mise à jour
        setupNotificationListeners()
    }
    
    // MARK: - Public Methods
    
    func resetState() {
        state = .idle
    }
    
    @MainActor
    func fetchData() async {
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpirationInterval,
           !medicines.isEmpty && !aisles.isEmpty {
            return
        }
        
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
            
            lastFetchTime = Date()
            state = .success
        } catch {
            state = .error("Erreur lors du chargement des données: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Navigation Methods
    
    func navigateToMedicineDetail(_ medicine: Medicine) {
        // Navigation gérée par la vue
        print("Navigation vers détail médicament: \(medicine.name)")
    }
    
    func navigateToMedicineList() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.medicineList)
        }
    }
    
    func navigateToAisles() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.aisles)
        }
    }
    
    func navigateToHistory() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.history)
        }
    }
    
    func navigateToCriticalStock() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.criticalStock)
        }
    }
    
    func navigateToExpiringMedicines() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.expiringMedicines)
        }
    }
    
    func navigateToAdjustStock() {
        if let coordinator = appCoordinator {
            coordinator.navigateFromDashboard(.adjustStock(""))
        }
    }
    
    // MARK: - Helper Methods
    
    func getMedicineName(for id: String) -> String {
        medicines.first(where: { $0.id == id })?.name ?? "Médicament inconnu"
    }
    
    // MARK: - Notification Listeners
    
    private func setupNotificationListeners() {
        // Écouter les notifications système pour les changements
        NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let medicine = notification.object as? Medicine {
                    self?.handleMedicineUpdate(medicine)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let medicine = notification.object as? Medicine {
                    self?.handleMedicineAdded(medicine)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let medicineId = notification.object as? String {
                    self?.handleMedicineDeleted(medicineId)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let medicineId = userInfo["medicineId"] as? String,
                   let newQuantity = userInfo["newQuantity"] as? Int {
                    self?.handleStockAdjusted(medicineId, newQuantity: newQuantity)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleMedicineAdded(_ medicine: Medicine) {
        medicines.append(medicine)
        totalMedicines = medicines.count
        updateCriticalStockMedicines()
        updateExpiringMedicines()
    }
    
    private func handleMedicineUpdate(_ medicine: Medicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
            updateCriticalStockMedicines()
            updateExpiringMedicines()
        }
    }
    
    private func handleMedicineDeleted(_ id: String) {
        medicines.removeAll { $0.id == id }
        totalMedicines = medicines.count
        updateCriticalStockMedicines()
        updateExpiringMedicines()
    }
    
    private func handleStockAdjusted(_ medicineId: String, newQuantity: Int) {
        if let index = medicines.firstIndex(where: { $0.id == medicineId }) {
            let medicine = medicines[index]
            let updatedMedicine = Medicine(
                id: medicine.id,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: newQuantity,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: medicine.createdAt,
                updatedAt: Date()
            )
            medicines[index] = updatedMedicine
            updateCriticalStockMedicines()
        }
    }
    
    private func updateCriticalStockMedicines() {
        criticalStockMedicines = medicines.filter { medicine in
            guard medicine.criticalThreshold > 0 else { return false }
            return medicine.currentQuantity <= medicine.criticalThreshold
        }.sorted { $0.currentQuantity < $1.currentQuantity }
    }
    
    private func updateExpiringMedicines() {
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
