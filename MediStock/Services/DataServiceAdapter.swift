import Foundation
import FirebaseFirestore

// MARK: - Adaptateur pour maintenir la compatibilité avec l'ancien DataService
// Ce fichier permet une migration progressive sans casser le code existant

/// Facade qui maintient l'interface de l'ancien DataService
/// tout en utilisant les nouveaux services modulaires en interne
class DataServiceAdapter {
    // Services modulaires
    private let medicineService: MedicineDataService
    private let aisleService: AisleDataService
    private let historyService: HistoryDataService
    
    // Listeners pour la rétrocompatibilité
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - Singleton pour compatibilité
    static let shared = DataServiceAdapter()
    
    // MARK: - Initialisation
    
    init() {
        // Créer les services avec injection de dépendances
        self.historyService = HistoryDataService()
        self.medicineService = MedicineDataService(historyService: historyService)
        self.aisleService = AisleDataService(historyService: historyService)
    }
    
    // Pour les tests avec injection
    init(
        medicineService: MedicineDataService,
        aisleService: AisleDataService,
        historyService: HistoryDataService
    ) {
        self.medicineService = medicineService
        self.aisleService = aisleService
        self.historyService = historyService
    }
    
    // MARK: - API de Compatibilité Médicaments
    
    func getMedicines() async throws -> [Medicine] {
        return try await medicineService.getAllMedicines()
    }
    
    func getMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        return try await medicineService.getMedicinesPaginated(limit: limit, refresh: refresh)
    }
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        return try await medicineService.saveMedicine(medicine)
    }
    
    func deleteMedicine(_ medicine: Medicine) async throws {
        try await medicineService.deleteMedicine(medicine)
    }
    
    func deleteMedicine(id: String) async throws {
        // Récupérer le médicament pour pouvoir le supprimer
        guard let medicine = try await medicineService.getMedicine(by: id) else {
            throw NSError(domain: "DataServiceAdapter", code: 404, userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"])
        }
        try await medicineService.deleteMedicine(medicine)
    }
    
    func adjustStock(medicineId: String, adjustment: Int) async throws -> Medicine {
        return try await medicineService.adjustStock(medicineId: medicineId, adjustment: adjustment)
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        return try await medicineService.updateMedicineStock(id: id, newStock: newStock)
    }
    
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        try await medicineService.updateMultipleMedicines(medicines)
    }
    
    func deleteMultipleMedicines(ids: [String]) async throws {
        // Supprimer chaque médicament individuellement
        for id in ids {
            try await deleteMedicine(id: id)
        }
    }
    
    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        let listener = medicineService.createMedicinesListener(completion: completion)
        listeners.append(listener)
    }
    
    // MARK: - API de Compatibilité Rayons
    
    func getAisles() async throws -> [Aisle] {
        return try await aisleService.getAllAisles()
    }
    
    func getAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        return try await aisleService.getAislesPaginated(limit: limit, refresh: refresh)
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        return try await aisleService.saveAisle(aisle)
    }
    
    func deleteAisle(_ aisle: Aisle) async throws {
        try await aisleService.deleteAisle(aisle)
    }
    
    func deleteAisle(id: String) async throws {
        // Récupérer le rayon pour pouvoir le supprimer
        guard let aisle = try await aisleService.getAisle(by: id) else {
            throw NSError(domain: "DataServiceAdapter", code: 404, userInfo: [NSLocalizedDescriptionKey: "Rayon non trouvé"])
        }
        try await aisleService.deleteAisle(aisle)
    }
    
    func checkAisleExists(_ aisleId: String) async throws -> Bool {
        return try await aisleService.checkAisleExists(aisleId)
    }
    
    func countMedicinesInAisle(_ aisleId: String) async throws -> Int {
        return try await aisleService.countMedicinesInAisle(aisleId)
    }
    
    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        let listener = aisleService.createAislesListener(completion: completion)
        listeners.append(listener)
    }
    
    // MARK: - API de Compatibilité Historique
    
    func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        return try await historyService.getHistory(medicineId: medicineId)
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        // Comme HistoryEntry n'a pas de metadata dans le modèle de base,
        // on utilise une logique simple basée sur l'action et les détails
        
        // Si l'entrée concerne un médicament (medicineId non vide)
        if !entry.medicineId.isEmpty {
            // Extraire le nom du médicament des détails si possible
            let medicineName = extractMedicineName(from: entry.details)
            
            try await historyService.recordMedicineAction(
                medicineId: entry.medicineId,
                medicineName: medicineName,
                action: entry.action,
                details: entry.details
            )
        } else {
            // Si pas de medicineId, c'est probablement une action sur un rayon
            // ou une action générale - on enregistre comme suppression générique
            try await historyService.recordDeletion(
                itemType: "general",
                itemId: entry.id,
                itemName: "",
                details: entry.details
            )
        }
    }
    
    // Helper pour extraire le nom du médicament des détails
    private func extractMedicineName(from details: String) -> String {
        // Recherche de patterns courants dans les détails
        // Ex: "Modification du médicament Doliprane"
        if let range = details.range(of: "médicament ") {
            let afterMedicine = String(details[range.upperBound...])
            let name = afterMedicine.split(separator: " ").first ?? ""
            return String(name)
        }
        return ""
    }
    
    // MARK: - Gestion des Listeners
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    deinit {
        stopListening()
    }
}

// MARK: - Extension pour Migration Progressive

extension DataServiceAdapter {
    /// Guide de migration pour les développeurs
    static var migrationGuide: String {
        """
        🔄 GUIDE DE MIGRATION DATASERVICE
        
        L'ancien DataService monolithique a été refactorisé en 3 services spécialisés :
        
        1. MedicineDataService - Gestion des médicaments
        2. AisleDataService - Gestion des rayons  
        3. HistoryDataService - Gestion de l'historique
        
        MIGRATION PROGRESSIVE :
        
        Phase 1 (Actuelle) : Utiliser DataServiceAdapter
        - Remplacez DataService par DataServiceAdapter dans votre code
        - L'API reste identique, aucun changement fonctionnel
        
        Phase 2 : Migration ViewModels
        - Injectez les services spécifiques dans vos ViewModels
        - Exemple : MedicineListViewModel(medicineService: MedicineDataService())
        
        Phase 3 : Suppression de l'adaptateur
        - Une fois tous les ViewModels migrés
        - Supprimer DataServiceAdapter et l'ancien DataService
        
        Cette approche garantit zéro régression pendant la migration.
        """
    }
}

// MARK: - Alias pour Faciliter la Migration

/// NOTE: N'utilisez pas le typealias si vous avez encore l'ancien DataService.swift
/// Utilisez directement DataServiceAdapter dans votre code pour éviter les conflits