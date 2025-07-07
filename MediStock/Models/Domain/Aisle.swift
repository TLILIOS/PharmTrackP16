import Foundation
import SwiftUI

struct Aisle: Identifiable, Equatable {
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
    
    static func == (lhs: Aisle, rhs: Aisle) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.description == rhs.description &&
               lhs.colorHex == rhs.colorHex &&
               lhs.icon == rhs.icon
    }
}
