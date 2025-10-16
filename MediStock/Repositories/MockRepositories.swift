import Foundation

// MARK: - Mock Repositories pour Tests et Previews
// Ces mocks permettent de tester les ViewModels sans Firebase

#if DEBUG

// MARK: - MockMedicineRepository

class MockMedicineRepository: MedicineRepositoryProtocol {
    var medicines: [Medicine] = []
    var shouldThrowError = false

    func fetchMedicines() async throws -> [Medicine] {
        if shouldThrowError { throw MockError.simulatedError }
        return medicines
    }

    func fetchMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        if shouldThrowError { throw MockError.simulatedError }
        return Array(medicines.prefix(limit))
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        if shouldThrowError { throw MockError.simulatedError }

        var saved = medicine
        if saved.id?.isEmpty ?? true {
            saved = Medicine(
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
                createdAt: Date(),
                updatedAt: Date()
            )
            medicines.append(saved)
        } else {
            if let index = medicines.firstIndex(where: { $0.id == saved.id }) {
                medicines[index] = saved
            }
        }
        return saved
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        if shouldThrowError { throw MockError.simulatedError }

        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw MockError.notFound
        }

        var updated = medicines[index]
        updated = Medicine(
            id: updated.id,
            name: updated.name,
            description: updated.description,
            dosage: updated.dosage,
            form: updated.form,
            reference: updated.reference,
            unit: updated.unit,
            currentQuantity: newStock,
            maxQuantity: updated.maxQuantity,
            warningThreshold: updated.warningThreshold,
            criticalThreshold: updated.criticalThreshold,
            expiryDate: updated.expiryDate,
            aisleId: updated.aisleId,
            createdAt: updated.createdAt,
            updatedAt: Date()
        )
        medicines[index] = updated
        return updated
    }

    func deleteMedicine(id: String) async throws {
        if shouldThrowError { throw MockError.simulatedError }
        medicines.removeAll { $0.id == id }
    }

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        if shouldThrowError { throw MockError.simulatedError }
        for medicine in medicines {
            _ = try await saveMedicine(medicine)
        }
    }

    func deleteMultipleMedicines(ids: [String]) async throws {
        if shouldThrowError { throw MockError.simulatedError }
        medicines.removeAll { medicine in
            guard let medicineId = medicine.id else { return false }
            return ids.contains(medicineId)
        }
    }

    // MARK: - Real-time Listeners (Mock)

    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        // Mock: call completion immediately with current medicines
        completion(medicines)
    }

    func stopListening() {
        // Mock: nothing to stop
    }
}

// MARK: - MockAisleRepository

class MockAisleRepository: AisleRepositoryProtocol {
    var aisles: [Aisle] = []
    var shouldThrowError = false

    func fetchAisles() async throws -> [Aisle] {
        if shouldThrowError { throw MockError.simulatedError }
        return aisles
    }

    func fetchAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        if shouldThrowError { throw MockError.simulatedError }
        return Array(aisles.prefix(limit))
    }

    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if shouldThrowError { throw MockError.simulatedError }

        var saved = aisle
        if saved.id == nil || saved.id?.isEmpty == true {
            saved.id = UUID().uuidString
            aisles.append(saved)
        } else {
            if let index = aisles.firstIndex(where: { $0.id == saved.id }) {
                aisles[index] = saved
            }
        }
        return saved
    }

    func deleteAisle(id: String) async throws {
        if shouldThrowError { throw MockError.simulatedError }
        aisles.removeAll { $0.id == id }
    }

    // MARK: - Real-time Listeners (Mock)

    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        // Mock: call completion immediately with current aisles
        completion(aisles)
    }

    func stopListening() {
        // Mock: nothing to stop
    }
}

// MARK: - MockHistoryRepository

class MockHistoryRepository: HistoryRepositoryProtocol {
    var historyEntries: [HistoryEntry] = []
    var shouldThrowError = false

    func fetchHistory() async throws -> [HistoryEntry] {
        if shouldThrowError { throw MockError.simulatedError }
        return historyEntries
    }

    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        if shouldThrowError { throw MockError.simulatedError }
        historyEntries.append(entry)
    }

    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        if shouldThrowError { throw MockError.simulatedError }
        return historyEntries.filter { $0.medicineId == medicineId }
    }
}

// MARK: - MockError

enum MockError: LocalizedError {
    case simulatedError
    case notFound

    var errorDescription: String? {
        switch self {
        case .simulatedError:
            return "Erreur simulée pour les tests"
        case .notFound:
            return "Élément non trouvé"
        }
    }
}

// MARK: - Sample Data for Previews

extension MockMedicineRepository {
    static func withSampleData() -> MockMedicineRepository {
        let repo = MockMedicineRepository()
        repo.medicines = [
            Medicine(
                id: "1",
                name: "Paracétamol",
                description: "Antalgique et antipyrétique",
                dosage: "500mg",
                form: "Comprimé",
                reference: "PAR-500",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 200,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Medicine(
                id: "2",
                name: "Ibuprofène",
                description: "Anti-inflammatoire",
                dosage: "400mg",
                form: "Comprimé",
                reference: "IBU-400",
                unit: "comprimés",
                currentQuantity: 15,
                maxQuantity: 150,
                warningThreshold: 30,
                criticalThreshold: 10,
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        return repo
    }
}

extension MockAisleRepository {
    static func withSampleData() -> MockAisleRepository {
        let repo = MockAisleRepository()

        var aisle1 = Aisle(
            name: "Antalgiques",
            description: "Médicaments contre la douleur",
            colorHex: "#FF6B6B",
            icon: "pills.fill"
        )
        aisle1.id = "aisle1"

        var aisle2 = Aisle(
            name: "Antibiotiques",
            description: "Médicaments antibactériens",
            colorHex: "#4ECDC4",
            icon: "cross.case.fill"
        )
        aisle2.id = "aisle2"

        repo.aisles = [aisle1, aisle2]
        return repo
    }
}

extension MockHistoryRepository {
    static func withSampleData() -> MockHistoryRepository {
        let repo = MockHistoryRepository()
        repo.historyEntries = [
            HistoryEntry(
                id: "h1",
                medicineId: "1",
                userId: "user1",
                action: "Ajout stock",
                details: "Ajout de 50 comprimés",
                timestamp: Date()
            ),
            HistoryEntry(
                id: "h2",
                medicineId: "2",
                userId: "user1",
                action: "Modification",
                details: "Mise à jour des seuils d'alerte",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            )
        ]
        return repo
    }
}

#endif
