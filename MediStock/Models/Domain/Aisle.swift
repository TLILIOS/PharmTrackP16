import Foundation
import SwiftUI

struct Aisle: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var description: String?
    var colorHex: String
    var icon: String
    
    /// Couleur associée au rayon, dérivée du code hexadécimal
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // Convenience initializers
    init(id: String, name: String, description: String? = nil, colorHex: String = "#007AFF", icon: String = "folder") {
        self.id = id
        self.name = name
        self.description = description
        self.colorHex = colorHex
        self.icon = icon
    }
    
    init(id: String, name: String, description: String? = nil, color: Color, icon: String) {
        self.id = id
        self.name = name
        self.description = description
        self.colorHex = color.toHex()
        self.icon = icon
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Equatable
    static func == (lhs: Aisle, rhs: Aisle) -> Bool {
        return lhs.id == rhs.id
    }
    
}
