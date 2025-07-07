import Foundation
import FirebaseFirestore
struct UserDTO: Codable {
    @DocumentID var id: String?
    var email: String?
    var displayName: String?
    
    func toDomain() -> User {
        return User(
            id: id ?? UUID().uuidString,
            email: email,
            displayName: displayName
        )
    }
    
    static func fromDomain(_ user: User) -> UserDTO {
        return UserDTO(
            id: user.id,
            email: user.email,
            displayName: user.displayName
        )
    }
}
