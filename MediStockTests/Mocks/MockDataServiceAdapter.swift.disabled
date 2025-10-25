import Foundation
import FirebaseFirestore
@testable import MediStock

/// Mock DataServiceAdapter pour les tests unitaires
/// N'utilise aucune dépendance Firebase et stocke tout en mémoire
class MockDataServiceAdapter: DataServiceAdapter {
    
    // MARK: - Storage
    
    /// Stockage en mémoire des médicaments
    private var medicines: [Medicine] = []
    
    /// Stockage en mémoire des rayons
    private var aisles: [Aisle] = []
    
    /// Stockage en mémoire de l'historique
    private var history: [HistoryEntry] = []
    
    /// Utilisateur actuel simulé
    private var currentUser: User?
    
    // MARK: - Configuration
    
    /// Indique si le service doit simuler des erreurs
    var shouldThrowError = false
    
    /// L'erreur à lancer si shouldThrowError est true
    var errorToThrow: Error = NSError(domain: "MockDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    /// Délai simulé pour les opérations (en secondes)
    var simulatedDelay: TimeInterval = 0
    
    /// Nombre d'appels pour chaque méthode (pour vérifier dans les tests)
    var callCounts: [String: Int] = [:]
    
    // MARK: - Initialization
    
    override init() {
        // Initialiser les propriétés de l'instance
        self.medicines = []
        self.aisles = []
        self.history = []
        self.currentUser = nil
        self.shouldThrowError = false
        self.errorToThrow = NSError(domain: "MockDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        self.simulatedDelay = 0
        self.callCounts = [:]
        
        // Appeler super.init() APRES avoir initialisé toutes les propriétés
        super.init()
    }
    
    /// Configure le mock avec des données de test
    func configure(
        medicines: [Medicine] = [],
        aisles: [Aisle] = [],
        history: [HistoryEntry] = [],
        currentUser: User? = nil
    ) {
        self.medicines = medicines
        self.aisles = aisles
        self.history = history
        self.currentUser = currentUser
    }
    
    // MARK: - Helper Methods
    
    private func incrementCallCount(for method: String) {
        callCounts[method, default: 0] += 1
    }
    
    private func simulateNetworkDelay() async {
        if simulatedDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
    }
    
    private func checkError() throws {
        if shouldThrowError {
            throw errorToThrow
        }
    }
    
    // MARK: - Medicine Operations
    
    override func getMedicines() async throws -> [Medicine] {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        return medicines
    }
    
    override func getMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        // Simulation simple de la pagination
        return Array(medicines.prefix(limit))
    }
    
    override func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        // Générer un ID si nécessaire
        var medicineToSave = medicine
        if medicineToSave.id.isEmpty {
            medicineToSave = Medicine(
                id: UUID().uuidString,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: medicine.currentQuantity,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: medicine.createdAt,
                updatedAt: Date()
            )
        }
        
        // Mise à jour ou ajout
        if let index = medicines.firstIndex(where: { $0.id == medicineToSave.id }) {
            medicines[index] = medicineToSave
        } else {
            medicines.append(medicineToSave)
        }
        
        return medicineToSave
    }
    
    override func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw ValidationError.invalidId
        }
        
        let oldMedicine = medicines[index]
        let updatedMedicine = Medicine(
            id: oldMedicine.id,
            name: oldMedicine.name,
            description: oldMedicine.description,
            dosage: oldMedicine.dosage,
            form: oldMedicine.form,
            reference: oldMedicine.reference,
            unit: oldMedicine.unit,
            currentQuantity: newStock,
            maxQuantity: oldMedicine.maxQuantity,
            warningThreshold: oldMedicine.warningThreshold,
            criticalThreshold: oldMedicine.criticalThreshold,
            expiryDate: oldMedicine.expiryDate,
            aisleId: oldMedicine.aisleId,
            createdAt: oldMedicine.createdAt,
            updatedAt: Date()
        )
        
        medicines[index] = updatedMedicine
        return updatedMedicine
    }
    
    override func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        for medicine in medicines {
            _ = try await saveMedicine(medicine)
        }
    }
    
    override func deleteMedicine(id: String) async throws {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        medicines.removeAll { $0.id == id }
    }
    
    override func deleteMultipleMedicines(ids: [String]) async throws {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        medicines.removeAll { ids.contains($0.id) }
    }
    
    // MARK: - Aisle Operations
    
    override func getAisles() async throws -> [Aisle] {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        return aisles
    }
    
    override func getAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        return Array(aisles.prefix(limit))
    }
    
    override func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        // Générer un ID si nécessaire
        var aisleToSave = aisle
        if aisleToSave.id.isEmpty {
            aisleToSave = Aisle(
                id: UUID().uuidString,
                name: aisle.name,
                description: aisle.description,
                colorHex: aisle.colorHex,
                icon: aisle.icon
            )
        }
        
        // Mise à jour ou ajout
        if let index = aisles.firstIndex(where: { $0.id == aisleToSave.id }) {
            aisles[index] = aisleToSave
        } else {
            aisles.append(aisleToSave)
        }
        
        return aisleToSave
    }
    
    override func deleteAisle(id: String) async throws {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        aisles.removeAll { $0.id == id }
    }
    
    // MARK: - History Operations
    
    override func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        if let medicineId = medicineId {
            return history.filter { $0.medicineId == medicineId }
        }
        return history
    }
    
    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        incrementCallCount(for: #function)
        await simulateNetworkDelay()
        try checkError()
        
        history.append(entry)
    }
    
    // MARK: - Test Utilities
    
    /// Réinitialise toutes les données
    func reset() {
        medicines.removeAll()
        aisles.removeAll()
        history.removeAll()
        currentUser = nil
        callCounts.removeAll()
        shouldThrowError = false
        simulatedDelay = 0
    }
    
    /// Retourne le nombre d'appels pour une méthode donnée
    func callCount(for method: String) -> Int {
        return callCounts[method] ?? 0
    }
    
    /// Ajoute des données de test par défaut
    func loadTestData() {
        medicines = TestData.mockMedicines
        aisles = TestData.mockAisles
        currentUser = User.mock()
    }
}