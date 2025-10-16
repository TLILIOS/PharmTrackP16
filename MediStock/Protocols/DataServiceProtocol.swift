import Foundation

// MARK: - Protocol pour abstraction du service de données

/// Protocole définissant le contrat pour les services de données
/// Permet l'injection de dépendances et le testing avec mocks
protocol DataServiceProtocol {
    // MARK: - Medicines

    /// Récupère tous les médicaments de l'utilisateur
    func getMedicines() async throws -> [Medicine]

    /// Récupère les médicaments avec pagination
    func getMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine]

    /// Sauvegarde un médicament (création ou mise à jour)
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine

    /// Met à jour le stock d'un médicament
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine

    /// Supprime un médicament
    func deleteMedicine(id: String) async throws

    // MARK: - Aisles

    /// Récupère tous les rayons de l'utilisateur
    func getAisles() async throws -> [Aisle]

    /// Récupère les rayons avec pagination
    func getAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle]

    /// Sauvegarde un rayon (création ou mise à jour)
    func saveAisle(_ aisle: Aisle) async throws -> Aisle

    /// Supprime un rayon
    func deleteAisle(id: String) async throws

    // MARK: - History

    /// Récupère l'historique des actions
    func getHistory() async throws -> [HistoryEntry]

    /// Ajoute une entrée dans l'historique
    func addHistoryEntry(_ entry: HistoryEntry) async throws

    // MARK: - Batch Operations

    /// Met à jour plusieurs médicaments en batch
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws

    /// Supprime plusieurs médicaments en batch
    func deleteMultipleMedicines(ids: [String]) async throws

    // MARK: - Listeners

    /// Démarre l'écoute en temps réel des médicaments
    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void)

    /// Démarre l'écoute en temps réel des rayons
    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void)

    /// Arrête tous les listeners actifs
    func stopListening()
}
