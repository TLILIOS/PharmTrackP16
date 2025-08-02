import Foundation
@testable import MediStock

// MARK: - Mock DataServiceAdapter pour les tests

@MainActor
class MockDataServiceAdapterForIntegration: DataServiceAdapter {
    var shouldThrowError = false
    var aisles: [Aisle] = []
    var medicines: [Medicine] = []
    var history: [HistoryEntry] = []
    
    override func getAisles() async throws -> [Aisle] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return aisles
    }
    
    override func getAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return Array(aisles.prefix(limit))
    }
    
    override func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        // Validation
        do {
            try aisle.validate()
        } catch {
            throw error
        }
        
        // Vérifier l'unicité du nom
        if aisles.contains(where: { $0.name == aisle.name && $0.id != aisle.id }) {
            throw ValidationError.duplicateAisleName(name: aisle.name)
        }
        
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        var savedAisle = aisle
        if aisle.id.isEmpty {
            savedAisle = Aisle(
                id: UUID().uuidString,
                name: aisle.name,
                description: aisle.description,
                colorHex: aisle.colorHex,
                icon: aisle.icon
            )
            aisles.append(savedAisle)
        } else {
            if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
                aisles[index] = aisle
            }
        }
        
        return savedAisle
    }
    
    override func deleteAisle(_ aisle: Aisle) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        aisles.removeAll { $0.id == aisle.id }
    }
    
    override func getMedicines() async throws -> [Medicine] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return medicines
    }
    
    override func getMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return Array(medicines.prefix(limit))
    }
    
    override func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        // Validation
        do {
            try medicine.validate()
        } catch {
            throw error
        }
        
        // Vérifier que le rayon existe
        if !aisles.contains(where: { $0.id == medicine.aisleId }) {
            throw ValidationError.invalidAisleReference(aisleId: medicine.aisleId)
        }
        
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        var savedMedicine = medicine
        if medicine.id.isEmpty {
            savedMedicine = Medicine(
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
                updatedAt: medicine.updatedAt
            )
            medicines.append(savedMedicine)
        } else {
            if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
                medicines[index] = medicine
            }
        }
        
        return savedMedicine
    }
    
    override func deleteMedicine(_ medicine: Medicine) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        medicines.removeAll { $0.id == medicine.id }
    }
    
    override func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Test", code: 404)
        }
        
        medicines[index].currentQuantity = newStock
        return medicines[index]
    }
    
    override func adjustStock(medicineId: String, adjustment: Int) async throws -> Medicine {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        guard let index = medicines.firstIndex(where: { $0.id == medicineId }) else {
            throw NSError(domain: "Test", code: 404)
        }
        
        medicines[index].currentQuantity = max(0, medicines[index].currentQuantity + adjustment)
        return medicines[index]
    }
    
    override func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        if let medicineId = medicineId {
            return history.filter { $0.medicineId == medicineId }
        }
        
        return history
    }
    
    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        history.append(entry)
    }
}