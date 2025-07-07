import Foundation
import FirebaseFirestore

struct AisleDTO: Codable {
    @DocumentID var id: String?
    var name: String
    var description: String?
    var colorHex: String
    var icon: String
    
    func toDomain() -> Aisle {
        return Aisle(
            id: id ?? UUID().uuidString,
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
    }
    
    static func fromDomain(_ aisle: Aisle) -> AisleDTO {
        return AisleDTO(
            id: aisle.id,
            name: aisle.name,
            description: aisle.description,
            colorHex: aisle.colorHex,
            icon: aisle.icon
        )
    }
}
