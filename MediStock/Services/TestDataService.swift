import Foundation

class TestDataService {
    private let medicineRepository: MedicineRepositoryProtocol
    private let aisleRepository: AisleRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(
        medicineRepository: MedicineRepositoryProtocol,
        aisleRepository: AisleRepositoryProtocol,
        historyRepository: HistoryRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.historyRepository = historyRepository
    }
    
    func generateAllTestData() async throws {
        print("🧪 Génération des données de test...")
        
        try await generateTestAisles()
        try await generateTestMedicines()
        try await generateTestHistory()
        
        print("✅ Données de test générées avec succès!")
    }
    
    private func generateTestAisles() async throws {
        let testAisles = [
            Aisle(id: "", name: "Pharmacie Générale", description: "Médicaments courants", colorHex: "#007AFF", icon: "pills"),
            Aisle(id: "", name: "Urgences", description: "Médicaments d'urgence", colorHex: "#FF3B30", icon: "heart.text.square"),
            Aisle(id: "", name: "Cardiologie", description: "Médicaments cardiovasculaires", colorHex: "#FF9500", icon: "heart"),
            Aisle(id: "", name: "Antibiotiques", description: "Traitements anti-infectieux", colorHex: "#30D158", icon: "shield"),
            Aisle(id: "", name: "Analgésiques", description: "Médicaments contre la douleur", colorHex: "#AF52DE", icon: "bandage")
        ]
        
        for aisle in testAisles {
            try await aisleRepository.saveAisle(aisle)
        }
        
        print("✅ Rayons de test créés")
    }
    
    private func generateTestMedicines() async throws {
        let aisles = try await aisleRepository.getAisles()
        guard !aisles.isEmpty else {
            throw NSError(domain: "TestDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No aisles found"])
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        let testMedicines = [
            // Pharmacie Générale
            Medicine(
                id: "",
                name: "Paracétamol 500mg",
                description: "Antalgique et antipyrétique",
                dosage: "500mg",
                form: "Comprimé",
                reference: "PAR-500",
                unit: "comprimé",
                currentQuantity: 150,
                maxQuantity: 500,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: calendar.date(byAdding: .month, value: 8, to: today),
                aisleId: aisles[0].id,
                createdAt: today,
                updatedAt: today
            ),
            Medicine(
                id: "",
                name: "Ibuprofène 400mg",
                description: "Anti-inflammatoire non stéroïdien",
                dosage: "400mg",
                form: "Comprimé",
                reference: "IBU-400",
                unit: "comprimé",
                currentQuantity: 5, // Stock critique
                maxQuantity: 200,
                warningThreshold: 30,
                criticalThreshold: 10,
                expiryDate: calendar.date(byAdding: .day, value: 15, to: today), // Expire bientôt
                aisleId: aisles[0].id,
                createdAt: today,
                updatedAt: today
            ),
            // Urgences
            Medicine(
                id: "",
                name: "Épinéphrine 1mg/ml",
                description: "Traitement d'urgence anaphylaxie",
                dosage: "1mg/ml",
                form: "Injection",
                reference: "EPI-001",
                unit: "ampoule",
                currentQuantity: 25,
                maxQuantity: 50,
                warningThreshold: 10,
                criticalThreshold: 5,
                expiryDate: calendar.date(byAdding: .month, value: 12, to: today),
                aisleId: aisles[1].id,
                createdAt: today,
                updatedAt: today
            ),
            // Cardiologie
            Medicine(
                id: "",
                name: "Aspirine 75mg",
                description: "Antiagrégant plaquettaire",
                dosage: "75mg",
                form: "Comprimé",
                reference: "ASP-075",
                unit: "comprimé",
                currentQuantity: 8, // Stock critique
                maxQuantity: 300,
                warningThreshold: 50,
                criticalThreshold: 15,
                expiryDate: calendar.date(byAdding: .month, value: 6, to: today),
                aisleId: aisles[2].id,
                createdAt: today,
                updatedAt: today
            ),
            // Antibiotiques
            Medicine(
                id: "",
                name: "Amoxicilline 500mg",
                description: "Antibiotique à large spectre",
                dosage: "500mg",
                form: "Gélule",
                reference: "AMX-500",
                unit: "gélule",
                currentQuantity: 120,
                maxQuantity: 250,
                warningThreshold: 40,
                criticalThreshold: 20,
                expiryDate: calendar.date(byAdding: .day, value: 20, to: today), // Expire bientôt
                aisleId: aisles[3].id,
                createdAt: today,
                updatedAt: today
            )
        ]
        
        for medicine in testMedicines {
            try await medicineRepository.saveMedicine(medicine)
        }
        
        print("✅ Médicaments de test créés")
    }
    
    private func generateTestHistory() async throws {
        let medicines = try await medicineRepository.getMedicines()
        guard !medicines.isEmpty else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        let historyEntries = [
            HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicines[0].id,
                userId: "test_user",
                action: "Ajout initial",
                details: "Stock initial ajouté: 150 unités",
                timestamp: calendar.date(byAdding: .day, value: -5, to: today) ?? today
            ),
            HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicines[0].id,
                userId: "test_user",
                action: "Dispensation",
                details: "Dispensation de 20 unités",
                timestamp: calendar.date(byAdding: .day, value: -2, to: today) ?? today
            ),
            HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicines[1].id,
                userId: "test_user",
                action: "Stock critique",
                details: "Alerte stock critique détectée",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: today) ?? today
            )
        ]
        
        for entry in historyEntries {
            try await historyRepository.addHistoryEntry(entry)
        }
        
        print("✅ Historique de test créé")
    }
}