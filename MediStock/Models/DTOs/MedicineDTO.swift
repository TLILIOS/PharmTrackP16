import Foundation
import FirebaseFirestore

struct MedicineDTO: Codable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    var dosage: String?
    var form: String?
    var reference: String?
    var unit: String
    var currentQuantity: Int
    var maxQuantity: Int
    var warningThreshold: Int
    var criticalThreshold: Int
    var expiryDate: Date?
    var aisleId: String
    var createdAt: Date
    var updatedAt: Date
    
    // Legacy compatibility
    var stock: Int { currentQuantity }
    var aisle: String { aisleId }
    
    func toDomain() -> Medicine {
        return Medicine(
            id: id ?? UUID().uuidString,
            name: name,
            description: description,
            dosage: dosage,
            form: form,
            reference: reference,
            unit: unit,
            currentQuantity: currentQuantity,
            maxQuantity: maxQuantity,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: expiryDate,
            aisleId: aisleId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    static func fromDomain(_ medicine: Medicine) -> MedicineDTO {
        return MedicineDTO(
            id: medicine.id,
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
    }
}
