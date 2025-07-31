import SwiftUI
import Combine

// MARK: - État global de l'application (remplace tous les ViewModels)

@MainActor
class AppState: ObservableObject {
    // États de l'app
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Données
    @Published var medicines: [Medicine] = []
    @Published var aisles: [Aisle] = []
    @Published var history: [HistoryEntry] = []
    @Published var stockHistory: [StockHistory] = []
    
    // États de pagination
    @Published var isLoadingMore = false
    @Published var hasMoreMedicines = true
    @Published var hasMoreAisles = true
    
    // Navigation
    @Published var selectedTab = 0
    @Published var navigationPath = NavigationPath()
    
    // Filtres et recherche
    @Published var searchText = ""
    @Published var selectedAisleId: String?
    
    // Services (injection simplifiée)
    let auth: AuthService
    let data: DataService
    let notifications: NotificationService
    
    init() {
        self.auth = AuthService()
        self.data = DataService()
        self.notifications = NotificationService()
        
        // Observer l'état d'authentification
        auth.$currentUser
            .assign(to: &$currentUser)
        
        // Charger les données au démarrage si connecté
        Task {
            if currentUser != nil {
                await loadData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }
    
    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon || $0.isExpired }
    }
    
    var filteredMedicines: [Medicine] {
        var result = medicines
        
        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { medicine in
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                (medicine.reference?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Filtre par rayon
        if let aisleId = selectedAisleId {
            result = result.filter { $0.aisleId == aisleId }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    // MARK: - Actions principales
    
    func loadData() async {
        isLoading = true
        do {
            // Charger la première page avec pagination
            async let medicinesTask = data.getMedicinesPaginated(refresh: true)
            async let aislesTask = data.getAislesPaginated(refresh: true)
            
            let (meds, aisls) = try await (medicinesTask, aislesTask)
            medicines = meds
            aisles = aisls
            hasMoreMedicines = meds.count >= 20
            hasMoreAisles = aisls.count >= 20
            
            // Vérifier les notifications d'expiration
            await notifications.checkExpirations(medicines: medicines)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadMoreMedicines() async {
        guard !isLoadingMore && hasMoreMedicines else { return }
        
        isLoadingMore = true
        do {
            let newMedicines = try await data.getMedicinesPaginated()
            medicines.append(contentsOf: newMedicines)
            hasMoreMedicines = newMedicines.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }
    
    func loadMoreAisles() async {
        guard !isLoadingMore && hasMoreAisles else { return }
        
        isLoadingMore = true
        do {
            let newAisles = try await data.getAislesPaginated()
            aisles.append(contentsOf: newAisles)
            hasMoreAisles = newAisles.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingMore = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await auth.signIn(email: email, password: password)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await auth.signUp(email: email, password: password, displayName: name)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await auth.signOut()
            // Nettoyer les données
            medicines = []
            aisles = []
            history = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Gestion des médicaments
    
    func saveMedicine(_ medicine: Medicine) async {
        isLoading = true
        do {
            let saved = try await data.saveMedicine(medicine)
            if let index = medicines.firstIndex(where: { $0.id == saved.id }) {
                medicines[index] = saved
            } else {
                medicines.append(saved)
            }
            
            // Ajouter à l'historique
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: saved.id,
                userId: currentUser?.id ?? "",
                action: medicine.id.isEmpty ? "Ajout" : "Modification",
                details: "Médicament: \(saved.name)",
                timestamp: Date()
            )
            try await data.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteMedicine(_ medicine: Medicine) async {
        isLoading = true
        do {
            try await data.deleteMedicine(id: medicine.id)
            medicines.removeAll { $0.id == medicine.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func adjustStock(medicine: Medicine, adjustment: Int, reason: String) async {
        let newQuantity = max(0, medicine.currentQuantity + adjustment)
        var updatedMedicine = medicine
        updatedMedicine.currentQuantity = newQuantity
        
        do {
            let saved = try await data.updateMedicineStock(id: medicine.id, newStock: newQuantity)
            if let index = medicines.firstIndex(where: { $0.id == saved.id }) {
                medicines[index] = saved
            }
            
            // Historique avec les quantités avant/après
            let historyEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicine.id,
                userId: currentUser?.id ?? "",
                action: adjustment > 0 ? "Ajout stock" : "Retrait stock",
                details: "\(abs(adjustment)) \(medicine.unit) - \(reason) (Stock: \(medicine.currentQuantity) → \(newQuantity))",
                timestamp: Date()
            )
            try await data.addHistoryEntry(historyEntry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Gestion des rayons
    
    func saveAisle(_ aisle: Aisle) async {
        isLoading = true
        do {
            let saved = try await data.saveAisle(aisle)
            if let index = aisles.firstIndex(where: { $0.id == saved.id }) {
                aisles[index] = saved
            } else {
                aisles.append(saved)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteAisle(_ aisle: Aisle) async {
        isLoading = true
        do {
            try await data.deleteAisle(id: aisle.id)
            aisles.removeAll { $0.id == aisle.id }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // MARK: - Historique
    
    func loadHistory() async {
        do {
            history = try await data.getHistory()
            // Convertir l'historique en StockHistory pour la vue
            stockHistory = history.compactMap { entry in
                // Parser l'action pour déterminer le type
                let type: StockHistory.HistoryType
                if entry.action.contains("Ajout stock") || entry.action.contains("Retrait stock") || entry.action.contains("Ajustement de stock") {
                    type = .adjustment
                } else if entry.action == "Ajout" || entry.action == "Création" {
                    type = .addition
                } else if entry.action.contains("Suppression") || entry.action.contains("supprim") {
                    type = .deletion
                } else {
                    type = .adjustment
                }
                
                // Extraire le changement et les quantités depuis les détails
                let change = extractChange(from: entry.details)
                let quantities = extractQuantities(from: entry.details)
                
                // Calculer le changement à partir des quantités si disponibles
                let actualChange = quantities.previous > 0 && quantities.new > 0 
                    ? quantities.new - quantities.previous 
                    : (entry.action.contains("Retrait") ? -change : change)
                
                return StockHistory(
                    id: entry.id,
                    medicineId: entry.medicineId,
                    userId: entry.userId,
                    type: type,
                    date: entry.timestamp,
                    change: actualChange,
                    previousQuantity: quantities.previous,
                    newQuantity: quantities.new,
                    reason: extractReason(from: entry.details)
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func extractChange(from details: String) -> Int {
        // Extraire le nombre depuis "X unités - raison"
        if let match = details.firstMatch(of: /(\d+)\s+\w+/) {
            return Int(match.1) ?? 0
        }
        return 0
    }
    
    private func extractQuantities(from details: String) -> (previous: Int, new: Int) {
        // Extraire les quantités depuis "(Stock: X → Y)"
        if let match = details.firstMatch(of: /Stock:\s*(\d+)\s*→\s*(\d+)/) {
            let previous = Int(match.1) ?? 0
            let new = Int(match.2) ?? 0
            return (previous, new)
        }
        return (0, 0)
    }
    
    private func extractReason(from details: String) -> String? {
        // Extraire la raison après le tiret et avant "(Stock:"
        if let dashIndex = details.firstIndex(of: "-") {
            let reasonStart = details.index(after: dashIndex)
            let remainingString = String(details[reasonStart...])
            
            // Enlever la partie "(Stock: X → Y)" si elle existe
            if let stockIndex = remainingString.firstIndex(of: "(") {
                let reason = String(remainingString[..<stockIndex])
                return reason.trimmingCharacters(in: .whitespaces)
            } else {
                return remainingString.trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }
    
    func clearError() {
        errorMessage = nil
    }
}