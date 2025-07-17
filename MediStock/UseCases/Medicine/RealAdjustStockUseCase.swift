import Foundation

class RealAdjustStockUseCase: AdjustStockUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicineId: String, adjustment: Int, reason: String) async throws -> Medicine {
        guard let medicine = try await medicineRepository.getMedicine(id: medicineId) else {
            throw MedicineError.notFound
        }
        
        let newQuantity = medicine.currentQuantity + adjustment
        
        guard newQuantity >= 0 else {
            throw MedicineError.invalidQuantity
        }
        
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
        
        let savedMedicine = try await medicineRepository.saveMedicine(updatedMedicine)
        
        let action = adjustment > 0 ? "Ajout de stock" : "Retrait de stock"
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "current_user", // TODO: Get from Auth
            action: action,
            details: "\(action) de \(abs(adjustment)) unité(s). Nouveau stock: \(newQuantity). Raison: \(reason)",
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
        
        return savedMedicine
    }
}