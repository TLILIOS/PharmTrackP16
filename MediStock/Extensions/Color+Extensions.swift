import SwiftUI
import UIKit

// MARK: - Color Extensions Centralisées

extension Color {
    // MARK: - Hex Color Support
    
    init?(hex: String) {
        let r, g, b: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])
        
        guard hexColor.count == 6,
              let hexNumber = Int(hexColor, radix: 16) else { return nil }
        
        r = Double((hexNumber & 0xff0000) >> 16) / 255
        g = Double((hexNumber & 0x00ff00) >> 8) / 255
        b = Double((hexNumber & 0x0000ff)) / 255
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    // MARK: - Light/Dark Mode Support
    
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    init(light: UIColor, dark: UIColor) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        })
    }
    
    // MARK: - Random Colors
    
    static var randomPastel: Color {
        let colors: [Color] = [.blue, .green, .orange, .red, .purple, .pink, .yellow, .indigo]
        return colors.randomElement() ?? .blue
    }
}