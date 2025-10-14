import SwiftUI

// MARK: - Vues Placeholder pour la Navigation
// Ces vues seront implémentées ultérieurement

// MARK: - MedicineHistoryView

struct MedicineHistoryView: View {
    let medicine: Medicine

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Historique du médicament")
                .font(.title2)
                .fontWeight(.semibold)

            Text(medicine.name)
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Cette fonctionnalité sera disponible prochainement")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Compte") {
                    if let user = appState.currentUser {
                        LabeledContent("Email", value: user.email ?? "Non défini")
                        LabeledContent("Nom", value: user.displayName ?? "Non défini")
                    }

                    Button(role: .destructive) {
                        Task {
                            await appState.signOut()
                        }
                    } label: {
                        Label("Déconnexion", systemImage: "arrow.right.square")
                    }
                }

                Section("Préférences") {
                    NavigationLink {
                        AppearanceView()
                    } label: {
                        Label("Apparence", systemImage: "paintbrush")
                    }

                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                Section("À propos") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("À propos", systemImage: "info.circle")
                    }

                    NavigationLink {
                        HelpView()
                    } label: {
                        Label("Aide", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AppearanceView

struct AppearanceView: View {
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some View {
        Form {
            Section {
                Picker("Mode d'apparence", selection: $appearance) {
                    ForEach(Appearance.allCases) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.rawValue)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } header: {
                Text("Thème de l'application")
            } footer: {
                Text("Choisissez le thème de l'application. Le mode Système suit automatiquement les réglages de votre appareil.")
            }
        }
        .navigationTitle("Apparence")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Appearance Enum

enum Appearance: String, CaseIterable, Identifiable {
    case system = "Système"
    case light = "Clair"
    case dark = "Sombre"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - NotificationsSettingsView

struct NotificationsSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("stockAlertEnabled") private var stockAlertEnabled = true
    @AppStorage("expiryAlertEnabled") private var expiryAlertEnabled = true
    @AppStorage("expiryAlertDays") private var expiryAlertDays = 30

    var body: some View {
        Form {
            Section {
                Toggle("Activer les notifications", isOn: $notificationsEnabled)
            } footer: {
                Text("Autorisez l'application à vous envoyer des notifications pour rester informé.")
            }

            Section {
                Toggle("Alertes de stock critique", isOn: $stockAlertEnabled)
                    .disabled(!notificationsEnabled)
            } header: {
                Text("Alertes de stock")
            } footer: {
                Text("Recevez une notification lorsqu'un médicament atteint le seuil critique.")
            }

            Section {
                Toggle("Alertes d'expiration", isOn: $expiryAlertEnabled)
                    .disabled(!notificationsEnabled)

                if expiryAlertEnabled {
                    Stepper("Alerter \(expiryAlertDays) jours avant", value: $expiryAlertDays, in: 7...90, step: 7)
                        .disabled(!notificationsEnabled)
                }
            } header: {
                Text("Alertes d'expiration")
            } footer: {
                Text("Recevez une notification avant qu'un médicament n'expire.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AboutView

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "pills.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)

                    Text("MediStock")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            .listRowBackground(Color.clear)

            Section("Description") {
                Text("MediStock est une application de gestion d'inventaire médical, conçue pour vous aider à suivre vos médicaments, gérer les stocks et prévenir les ruptures.")
            }

            Section("Informations") {
                LabeledContent("Développeur", value: "OpenClassrooms P16")
                LabeledContent("Plateforme", value: "iOS 16+")
                LabeledContent("Architecture", value: "MVVM Strict")
            }

            Section("Légal") {
                NavigationLink("Conditions d'utilisation") {
                    ScrollView {
                        Text("Les conditions d'utilisation seront disponibles prochainement.")
                            .padding()
                    }
                    .navigationTitle("Conditions")
                }

                NavigationLink("Politique de confidentialité") {
                    ScrollView {
                        Text("La politique de confidentialité sera disponible prochainement.")
                            .padding()
                    }
                    .navigationTitle("Confidentialité")
                }
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - HelpView

struct HelpView: View {
    var body: some View {
        List {
            Section("Démarrage rapide") {
                HelpRow(
                    icon: "plus.circle",
                    title: "Ajouter un médicament",
                    description: "Appuyez sur le bouton '+' pour créer un nouveau médicament."
                )

                HelpRow(
                    icon: "square.grid.2x2",
                    title: "Organiser par rayons",
                    description: "Créez des rayons pour organiser vos médicaments par catégorie."
                )

                HelpRow(
                    icon: "chart.bar",
                    title: "Suivre les statistiques",
                    description: "Consultez le tableau de bord pour voir les stocks critiques et les expirations proches."
                )
            }

            Section("Gestion des stocks") {
                HelpRow(
                    icon: "arrow.up.circle",
                    title: "Ajuster le stock",
                    description: "Utilisez les boutons '+' et '-' pour modifier les quantités en stock."
                )

                HelpRow(
                    icon: "bell",
                    title: "Notifications",
                    description: "Activez les notifications pour être alerté des stocks faibles et des expirations proches."
                )
            }

            Section("Exportation") {
                HelpRow(
                    icon: "square.and.arrow.up",
                    title: "Exporter les données",
                    description: "Exportez votre inventaire au format PDF depuis le tableau de bord."
                )
            }

            Section("Support") {
                HelpRow(
                    icon: "envelope",
                    title: "Contacter le support",
                    description: "Envoyez vos questions à support@medistock.app"
                )
            }
        }
        .navigationTitle("Aide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - HelpRow Component

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

struct PlaceholderViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                SettingsView()
            }

            NavigationStack {
                AppearanceView()
            }

            NavigationStack {
                NotificationsSettingsView()
            }

            NavigationStack {
                AboutView()
            }

            NavigationStack {
                HelpView()
            }
        }
    }
}
