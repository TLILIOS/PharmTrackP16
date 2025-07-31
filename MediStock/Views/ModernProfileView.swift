import SwiftUI

struct ModernProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    @State private var showingNotificationSettings = false
    @State private var selectedStat: StatType? = nil
    @Environment(\.colorScheme) var colorScheme
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    enum StatType: String, CaseIterable, Identifiable {
        case medicines = "Médicaments"
        case aisles = "Rayons"
        case critical = "Stocks critiques"
        case expiring = "Expirations"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .medicines: return "pills.fill"
            case .aisles: return "square.grid.2x2.fill"
            case .critical: return "exclamationmark.triangle.fill"
            case .expiring: return "clock.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .medicines: return .blue
            case .aisles: return .purple
            case .critical: return .orange
            case .expiring: return .red
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modern Profile Header
                profileHeader
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Statistics Grid
                statisticsGrid
                    .padding(.horizontal)
                
                // Settings Section
                settingsSection
                    .padding(.horizontal)
                
                // Sign Out Button
                signOutButton
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .alert("Se déconnecter ?", isPresented: $showingSignOutAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Se déconnecter", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
        .sheet(isPresented: $showingNotificationSettings) {
            ModernNotificationSettingsView()
        }
        .sheet(item: $selectedStat) { stat in
            StatDetailView(stat: stat)
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Avatar with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(userInitials)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 5)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            
            // User Info
            VStack(spacing: 6) {
                Text(authViewModel.currentUser?.displayName ?? "Utilisateur")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authViewModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Role Badge
                if let role = getUserRole() {
                    Text(role)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 2)
        )
    }
    
    private var statisticsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ProfileStatCard(
                type: StatType.medicines,
                value: "\(appState.medicines.count)",
                trend: calculateTrend(for: .medicines)
            )
            .onTapGesture {
                impactFeedback.impactOccurred()
                selectedStat = .medicines
            }
            
            ProfileStatCard(
                type: StatType.aisles,
                value: "\(appState.aisles.count)",
                trend: nil
            )
            .onTapGesture {
                impactFeedback.impactOccurred()
                selectedStat = .aisles
            }
            
            ProfileStatCard(
                type: StatType.critical,
                value: "\(appState.criticalMedicines.count)",
                trend: calculateTrend(for: .critical),
                isAlert: appState.criticalMedicines.count > 0
            )
            .onTapGesture {
                impactFeedback.impactOccurred()
                selectedStat = .critical
            }
            
            ProfileStatCard(
                type: StatType.expiring,
                value: "\(appState.expiringMedicines.count)",
                trend: calculateTrend(for: .expiring),
                isAlert: appState.expiringMedicines.count > 0
            )
            .onTapGesture {
                impactFeedback.impactOccurred()
                selectedStat = .expiring
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(spacing: 12) {
            SettingRow(
                icon: "bell.fill",
                title: "Notifications",
                color: .orange,
                badge: getNotificationBadge()
            ) {
                showingNotificationSettings = true
            }
            
            NavigationLink {
                ModernAboutView()
            } label: {
                SettingRow(
                    icon: "info.circle.fill",
                    title: "À propos",
                    color: .blue,
                    showChevron: true
                ) {}
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            impactFeedback.impactOccurred()
            showingSignOutAlert = true
        }) {
            HStack {
                Image(systemName: "arrow.right.square.fill")
                    .font(.title3)
                Text("Se déconnecter")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.9), Color.red],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Helper computed properties
    private var userInitials: String {
        let name = authViewModel.currentUser?.displayName ?? "U"
        return name.split(separator: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }
    
    private func getUserRole() -> String? {
        // Implement based on your user model
        return "Pharmacien"
    }
    
    private func calculateTrend(for stat: StatType) -> String? {
        // Calculate trend based on historical data
        return "+12%"
    }
    
    private func getNotificationBadge() -> Int? {
        let criticalCount = appState.criticalMedicines.count
        let expiringCount = appState.expiringMedicines.count
        let total = criticalCount + expiringCount
        return total > 0 ? total : nil
    }
}

// MARK: - Supporting Views

struct ProfileStatCard: View {
    let type: ModernProfileView.StatType
    let value: String
    let trend: String?
    var isAlert: Bool = false
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isAlert ? .white : type.color)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.contains("+") ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                        Text(trend)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(trend.contains("+") ? .green : .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isAlert ? .white : .primary)
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundStyle(isAlert ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isAlert ? type.color : Color(.secondarySystemGroupedBackground))
                .shadow(
                    color: isAlert ? type.color.opacity(0.3) : Color.black.opacity(0.05),
                    radius: isAlert ? 8 : 4,
                    y: 2
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.rawValue): \(value)" + (trend != nil ? ", variation \(trend!)" : ""))
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let color: Color
    var badge: Int? = nil
    var showChevron: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .cornerRadius(8)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let badge = badge {
                    Text("\(badge)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Detail Views

struct StatDetailView: View {
    let stat: ModernProfileView.StatType
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Implementation based on stat type
                Text("Détails pour \(stat.rawValue)")
            }
            .navigationTitle(stat.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

struct ModernNotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notifyLowStock") private var notifyLowStock = true
    @AppStorage("notifyExpiry") private var notifyExpiry = true
    @AppStorage("expiryDays") private var expiryDays = 30
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $notifyLowStock) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stock faible")
                                Text("Alertes quand le stock est bas")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .tint(.accentColor)
                    
                    Toggle(isOn: .constant(true)) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Stock critique")
                                Text("Toujours activé pour la sécurité")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(true)
                } header: {
                    Text("Notifications de stock")
                }
                
                Section {
                    Toggle(isOn: $notifyExpiry) {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Médicaments expirant")
                                Text("Rappels avant expiration")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.purple)
                        }
                    }
                    .tint(.accentColor)
                    
                    if notifyExpiry {
                        HStack {
                            Label("Délai d'alerte", systemImage: "calendar")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Picker("Jours", selection: $expiryDays) {
                                Text("7 jours").tag(7)
                                Text("14 jours").tag(14)
                                Text("30 jours").tag(30)
                                Text("60 jours").tag(60)
                                Text("90 jours").tag(90)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } header: {
                    Text("Notifications d'expiration")
                }
                
                Section {
                    Button(action: { showingPermissionAlert = true }) {
                        HStack {
                            Label("Paramètres système", systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Les notifications critiques ne peuvent pas être désactivées pour votre sécurité. Configurez les permissions dans les réglages iOS.")
                        .font(.caption)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Ouvrir les réglages ?", isPresented: $showingPermissionAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Ouvrir") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Gérez les permissions de notification dans les réglages iOS.")
        }
    }
}

struct ModernAboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon and Info
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "pills.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 10)
                    
                    VStack(spacing: 8) {
                        Text("MediStock")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Build 2024.1")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.top, 20)
                
                // Info Cards
                VStack(spacing: 16) {
                    InfoCard(
                        icon: "person.fill",
                        title: "Développeur",
                        value: "Vincent Saluzzo",
                        color: .blue
                    )
                    
                    InfoCard(
                        icon: "envelope.fill",
                        title: "Support",
                        value: "support@medistock.com",
                        color: .green,
                        isLink: true
                    )
                    
                    InfoCard(
                        icon: "doc.text.fill",
                        title: "Licence",
                        value: "MIT License",
                        color: .orange
                    )
                    
                    InfoCard(
                        icon: "globe",
                        title: "Site web",
                        value: "medistock.com",
                        color: .purple,
                        isLink: true
                    )
                }
                .padding(.horizontal)
                
                // Technologies
                VStack(spacing: 12) {
                    Text("Développé avec")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        TechBadge(name: "SwiftUI", icon: "swift")
                        TechBadge(name: "Firebase", icon: "flame.fill")
                        TechBadge(name: "Core Data", icon: "externaldrive.fill")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .padding(.horizontal)
                
                // Footer
                Text("Made with ❤️ in France")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var isLink: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(isLink ? color : .primary)
            }
            
            Spacer()
            
            if isLink {
                Image(systemName: "arrow.up.forward")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

struct TechBadge: View {
    let name: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview

struct ModernProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ModernProfileView()
            // Note: For preview, inject mock ViewModels in the app
        }
    }
}