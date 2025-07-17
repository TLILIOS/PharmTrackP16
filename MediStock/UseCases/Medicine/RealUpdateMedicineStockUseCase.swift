import Foundation

class RealUpdateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol {
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
        
        let oldQuantity = medicine.currentQuantity
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
        
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "current_user", // TODO: Get from Auth
            action: "Stock ajusté",
            details: "Stock modifié de \(oldQuantity) à \(newQuantity). \(comment)",
            timestamp: Date()
        )
        
        try await historyRepository.addHistoryEntry(historyEntry)
        
        return savedMedicine
    }
}