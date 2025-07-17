import SwiftUI

// Vue simple pour les paramètres d'apparence (mode sombre)
struct AppearanceSettingsView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceMode = .system
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Apparence")) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        HStack {
                            Image(systemName: mode.iconName)
                                .foregroundColor(mode.color)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.body)
                                
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedAppearance == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .font(.headline)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAppearance = mode
                        }
                    }
                }
                
                Section(footer: Text("Le mode système s'adapte automatiquement aux préférences de votre appareil.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Apparence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Énumération des modes d'apparence
enum AppearanceMode: String, CaseIterable {
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
            return "Automatique"
        }
    }
    
    var description: String {
        switch self {
        case .light:
            return "Interface toujours claire"
        case .dark:
            return "Interface toujours sombre"
        case .system:
            return "Suit les préférences système"
        }
    }
    
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .light:
            return .yellow
        case .dark:
            return .indigo
        case .system:
            return .gray
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

#Preview {
    AppearanceSettingsView()
}