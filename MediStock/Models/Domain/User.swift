import Foundation

public struct User: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public var email: String?
    public var displayName: String?
    
    public init(id: String, email: String? = nil, displayName: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
    }
}
