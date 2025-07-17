import Foundation

class UpdateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol {
    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    
    init(medicineRepository: MedicineRepositoryProtocol, historyRepository: HistoryRepositoryProtocol) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
    }
    
    func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine {
        guard let medicine = try await medicineRepository.getMedicine(id: medicineId) else {
            throw MedicineError.notFound
        }
        
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
        
        try await medicineRepository.saveMedicine(updatedMedicine)
        
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: getCurrentUserId(),
            action: "Mise à jour stock",
            details: "\(comment). Nouveau stock: \(newQuantity) \(medicine.unit)",
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
        
        return updatedMedicine
    }
}
