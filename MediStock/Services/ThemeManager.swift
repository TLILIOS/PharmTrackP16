import SwiftUI
import Combine

// MARK: - Theme Manager pour gérer Light/Dark Mode

@MainActor
class ThemeManager: ObservableObject {
    @Published var theme: Theme = .system {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
            FirebaseService.shared.setUserProperty(.preferredTheme(theme.rawValue))
        }
    }
    
    var colorScheme: ColorScheme? {
        switch theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    init() {
        // Restaurer le thème sauvegardé
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: savedTheme) {
            self.theme = theme
        }
    }
    
    enum Theme: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light:
                return "Clair"
            case .dark:
                return "Sombre"
            case .system:
                return "Système"
            }
        }
        
        var icon: String {
            switch self {
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            case .system:
                return "iphone"
            }
        }
    }
}

// MARK: - App Colors avec support Dark Mode

struct AppColors {
    // Primary Colors
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    
    // Background Colors
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    
    // Grouped Background Colors
    static let groupedBackground = Color(.systemGroupedBackground)
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
    
    // Text Colors
    static let label = Color(.label)
    static let secondaryLabel = Color(.secondaryLabel)
    static let tertiaryLabel = Color(.tertiaryLabel)
    static let quaternaryLabel = Color(.quaternaryLabel)
    
    // System Colors
    static let separator = Color(.separator)
    static let link = Color(.link)
    
    // Stock Status Colors (custom)
    static let stockNormal = Color(light: .systemGreen, dark: .systemGreen)
    static let stockWarning = Color(light: .systemOrange, dark: .systemOrange)
    static let stockCritical = Color(light: .systemRed, dark: .systemRed)
    
    // Custom Colors
    static let cardBackground = Color(light: Color(.systemGray6), dark: Color(.systemGray5))
    static let inputBackground = Color(light: Color(.systemGray6), dark: Color(.systemGray4))
}

// MARK: - Color Extension for Light/Dark Support

extension Color {
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
}

// MARK: - Typography avec Dynamic Type

struct AppFonts {
    // Titles
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    
    // Body
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // Custom Fonts
    static func customTitle(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
    
    static func monospacedDigit(size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing Constants

struct Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    // Padding
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    
    // Corner Radius
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    
    // Card Spacing
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
}

// MARK: - Shadow Styles

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    static let small = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let medium = ShadowStyle(
        color: Color.black.opacity(0.15),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let large = ShadowStyle(
        color: Color.black.opacity(0.2),
        radius: 16,
        x: 0,
        y: 8
    )
}

// MARK: - View Extension for Shadow

extension View {
    func shadowStyle(_ style: ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Form {
            Section("Thème de l'application") {
                ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                    HStack {
                        Label(theme.displayName, systemImage: theme.icon)
                        
                        Spacer()
                        
                        if themeManager.theme == theme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeManager.theme = theme
                        }
                    }
                }
            }
            
            Section {
                VStack(spacing: 12) {
                    Text("L'application s'adapte automatiquement au mode clair ou sombre selon vos préférences système.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("Le mode sélectionné sera appliqué immédiatement à toute l'application.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Apparence")
        .navigationBarTitleDisplayMode(.inline)
    }
}