import SwiftUI

struct NewDashboardView: View {
    @Environment(\.medicineRepository) private var medicineRepository
    @Environment(\.aisleRepository) private var aisleRepository
    @Environment(\.historyRepository) private var historyRepository
    @Environment(\.authRepository) private var authRepository
    
    @State private var viewModel: ObservableDashboardViewModel?
    @State private var refreshTimestamp = Date()
    @State private var showingSearchSheet = false
    
    // Animation properties
    @State private var headerScale = 0.95
    @State private var headerOpacity = 0.0
    @State private var cardsOffset: [Int: CGFloat] = [:]
    @State private var cardsOpacity: [Int: Double] = [:]
    @State private var actionsOffset = CGFloat(30)
    @State private var actionsOpacity = Double(0)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête avec salutation
                welcomeHeader
                
                // Cartes de résumé
                summaryCards
                
                // Section stocks critiques
                if let viewModel = viewModel, !viewModel.criticalStockMedicines.isEmpty {
                    stockAlertSection
                }
                
                // Actions rapides
                quickActionsSection
                
                // Activité récente
                if let viewModel = viewModel, !viewModel.recentHistory.isEmpty {
                    recentActivitySection
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .refreshable {
            refreshTimestamp = Date()
            await viewModel?.fetchData()
        }
        .navigationTitle("MediStock")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSearchSheet = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.body)
                }
            }
        }
        .sheet(isPresented: $showingSearchSheet) {
            NavigationStack {
                Text("Recherche (à implémenter)")
            }
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ObservableDashboardViewModel(
                    medicineRepository: medicineRepository,
                    aisleRepository: aisleRepository,
                    historyRepository: historyRepository,
                    authRepository: authRepository
                )
            }
        }
        .task {
            await viewModel?.fetchData()
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await viewModel?.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded"))) { _ in
            Task {
                await viewModel?.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))) { _ in
            Task {
                await viewModel?.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await viewModel?.fetchData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        VStack(spacing: 10) {
            if let userName = viewModel?.userName {
                Text("Bonjour, \(userName) 👋")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Bienvenue dans MediStock 👋")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("Dernière mise à jour: \(formatDateTime(refreshTimestamp))")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 10)
        .scaleEffect(headerScale)
        .opacity(headerOpacity)
    }
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
            // Carte Total des médicaments
            DashboardCard(
                title: "Total des médicaments",
                value: "\(viewModel?.totalMedicines ?? 0)",
                icon: "pills",
                color: .blue,
                offset: cardsOffset[0, default: 50],
                opacity: cardsOpacity[0, default: 0]
            )
            .onTapGesture {
                NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 1)
            }
            
            // Carte Total des rayons
            DashboardCard(
                title: "Nombre de rayons",
                value: "\(viewModel?.totalAisles ?? 0)",
                icon: "tray.full",
                color: .purple,
                offset: cardsOffset[1, default: 50],
                opacity: cardsOpacity[1, default: 0]
            )
            .onTapGesture {
                NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 2)
            }
            
            // Carte Stock critique
            NavigationLink(destination: NewCriticalStockView()) {
                DashboardCard(
                    title: "Médicaments critiques",
                    value: "\(viewModel?.criticalStockMedicines.count ?? 0)",
                    icon: "exclamationmark.triangle",
                    color: (viewModel?.criticalStockMedicines.isEmpty ?? true) ? .green : .red,
                    offset: cardsOffset[2, default: 50],
                    opacity: cardsOpacity[2, default: 0]
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Carte Expirations proches
            NavigationLink(destination: NewExpiringMedicinesView()) {
                DashboardCard(
                    title: "Expirations proches",
                    value: "\(viewModel?.expiringMedicines.count ?? 0)",
                    icon: "clock",
                    color: (viewModel?.expiringMedicines.isEmpty ?? true) ? .green : .orange,
                    offset: cardsOffset[3, default: 50],
                    opacity: cardsOpacity[3, default: 0]
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var stockAlertSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stocks critiques")
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel?.criticalStockMedicines.prefix(5) ?? []) { medicine in
                        NavigationLink(destination: NewMedicineDetailView(medicineId: medicine.id)) {
                            CriticalStockCard(medicine: medicine)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 5)
            }
            
            if (viewModel?.criticalStockMedicines.count ?? 0) > 5 {
                NavigationLink(destination: NewCriticalStockView()) {
                    Text("Voir tous les stocks critiques")
                        .font(.caption)
                        .foregroundColor(.accentApp)
                        .padding(.top, 5)
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Actions rapides")
                .font(.headline)
                .padding(.bottom, 5)
            
            VStack(spacing: 12) {
                // Ajouter un médicament
                NavigationLink(destination: NewMedicineFormView(medicineId: nil)) {
                    QuickActionButtonContent(
                        title: "Ajouter un médicament",
                        icon: "plus.circle",
                        color: .accentApp
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Ajuster un stock
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 1) // Switch to MedicineListView tab
                }) {
                    QuickActionButtonContent(
                        title: "Ajuster un stock",
                        icon: "arrow.up.arrow.down",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Consulter l'historique
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 3)
                }) {
                    QuickActionButtonContent(
                        title: "Consulter l'historique",
                        icon: "clock.arrow.circlepath",
                        color: .purple
                    )
                }
                
                // Gérer les rayons
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 2)
                }) {
                    QuickActionButtonContent(
                        title: "Gérer les rayons",
                        icon: "tray.2",
                        color: .blue
                    )
                }
            }
            .offset(y: actionsOffset)
            .opacity(actionsOpacity)
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activité récente")
                .font(.headline)
                .padding(.bottom, 5)
            
            VStack(spacing: 12) {
                ForEach(viewModel?.recentHistory.prefix(3) ?? []) { entry in
                    HStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(viewModel?.getMedicineName(for: entry.medicineId) ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(entry.action)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(timeAgo(from: entry.timestamp))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 3)
                }) {
                    Text("Voir tout l'historique")
                        .font(.caption)
                        .foregroundColor(.accentApp)
                        .padding(.top, 5)
                }
            }
            .offset(y: actionsOffset)
            .opacity(actionsOpacity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnimations() {
        // Animation de l'en-tête
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            headerScale = 1.0
            headerOpacity = 1.0
        }
        
        // Animation des cartes (séquentielle)
        for i in 0...3 {
            withAnimation(.easeOut(duration: 0.5).delay(0.1 + Double(i) * 0.1)) {
                cardsOffset[i] = 0
                cardsOpacity[i] = 1.0
            }
        }
        
        // Animation des actions rapides
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            actionsOffset = 0
            actionsOpacity = 1.0
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "il y a 1 jour" : "il y a \(day) jours"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "il y a 1 heure" : "il y a \(hour) heures"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "il y a 1 minute" : "il y a \(minute) minutes"
        } else {
            return "à l'instant"
        }
    }
}

// MARK: - Dashboard ViewModel with @Observable
@Observable
final class ObservableDashboardViewModel {
    // MARK: - Published Properties
    var totalMedicines: Int = 0
    var totalAisles: Int = 0
    var criticalStockMedicines: [Medicine] = []
    var expiringMedicines: [Medicine] = []
    var recentHistory: [HistoryEntry] = []
    var userName: String?
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let medicineRepository: any MedicineRepositoryProtocol
    private let aisleRepository: any AisleRepositoryProtocol
    private let historyRepository: any HistoryRepositoryProtocol
    private let authRepository: any AuthRepositoryProtocol
    
    // MARK: - Private Properties
    private var allMedicines: [Medicine] = []
    private var allAisles: [Aisle] = []
    private var medicineNames: [String: String] = [:]
    
    // MARK: - Initializer
    init(
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol,
        historyRepository: any HistoryRepositoryProtocol,
        authRepository: any AuthRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.historyRepository = historyRepository
        self.authRepository = authRepository
    }
    
    // MARK: - Methods
    @MainActor
    func fetchData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Charger les données en parallèle
            async let medicinesTask = medicineRepository.getMedicines()
            async let aislesTask = aisleRepository.getAisles()
            async let historyTask = historyRepository.getRecentHistory(limit: 10)
            async let userTask = authRepository.getCurrentUser()
            
            let medicines = try await medicinesTask
            let aisles = try await aislesTask
            let history = try await historyTask
            let user = try await userTask
            
            // Mettre à jour les données
            allMedicines = medicines
            allAisles = aisles
            totalMedicines = medicines.count
            totalAisles = aisles.count
            
            // Calculer les médicaments critiques
            criticalStockMedicines = medicines.filter { medicine in
                medicine.currentQuantity <= medicine.criticalThreshold
            }
            
            // Calculer les médicaments expirant bientôt
            let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            expiringMedicines = medicines.filter { medicine in
                guard let expiryDate = medicine.expiryDate else { return false }
                return expiryDate <= thirtyDaysFromNow
            }
            
            // Historique récent
            recentHistory = history
            
            // Nom d'utilisateur
            userName = user?.displayName ?? user?.email
            
            // Créer le dictionnaire des noms de médicaments
            medicineNames = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0.name) })
            
        } catch {
            errorMessage = "Erreur lors du chargement des données: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func getMedicineName(for medicineId: String) -> String {
        return medicineNames[medicineId] ?? "Médicament inconnu"
    }
}

// MARK: - Placeholder Views for Navigation
struct NewCriticalStockView: View {
    @Environment(\.medicineRepository) private var medicineRepository
    @Environment(\.aisleRepository) private var aisleRepository
    @Environment(\.historyRepository) private var historyRepository
    @Environment(\.authRepository) private var authRepository
    
    @State private var criticalMedicines: [Medicine] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if criticalMedicines.isEmpty {
                CriticalStockEmptyView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(criticalMedicines) { medicine in
                            NavigationLink(destination: NewMedicineDetailView(medicineId: medicine.id)) {
                                CriticalStockCard(medicine: medicine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            
            if let error = errorMessage {
                VStack {
                    Spacer()
                    MessageView(message: error, type: .error) {
                        errorMessage = nil
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Stocks critiques")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadCriticalMedicines()
        }
        .onAppear {
            Task {
                await loadCriticalMedicines()
            }
        }
    }
    
    private func loadCriticalMedicines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allMedicines = try await medicineRepository.getMedicines()
            criticalMedicines = allMedicines.filter { $0.currentQuantity <= $0.criticalThreshold }
                .sorted { $0.currentQuantity < $1.currentQuantity }
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct CriticalStockCard: View {
    let medicine: Medicine
    
    private var stockPercentage: Double {
        guard medicine.maxQuantity > 0 else { return 0 }
        return Double(medicine.currentQuantity) / Double(medicine.maxQuantity)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage ?? "Dosage non spécifié")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(medicine.currentQuantity)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("/ \(medicine.maxQuantity) \(medicine.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * stockPercentage, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            HStack {
                Label("Seuil critique: \(medicine.criticalThreshold)", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                
                Spacer()
                
                if let reference = medicine.reference {
                    Text("Réf: \(reference)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct NewExpiringMedicinesView: View {
    @Environment(\.medicineRepository) private var medicineRepository
    
    @State private var expiringMedicines: [Medicine] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if expiringMedicines.isEmpty {
                ExpiringMedicinesEmptyView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(expiringMedicines) { medicine in
                            NavigationLink(destination: NewMedicineDetailView(medicineId: medicine.id)) {
                                ExpiringMedicineCard(medicine: medicine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            
            if let error = errorMessage {
                VStack {
                    Spacer()
                    MessageView(message: error, type: .error) {
                        errorMessage = nil
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Expirations proches")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadExpiringMedicines()
        }
        .onAppear {
            Task {
                await loadExpiringMedicines()
            }
        }
    }
    
    private func loadExpiringMedicines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let allMedicines = try await medicineRepository.getMedicines()
            let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
            
            expiringMedicines = allMedicines.filter { medicine in
                guard let expiryDate = medicine.expiryDate else { return false }
                return expiryDate <= thirtyDaysFromNow
            }.sorted { (medicine1, medicine2) in
                guard let date1 = medicine1.expiryDate, let date2 = medicine2.expiryDate else { return false }
                return date1 < date2
            }
        } catch {
            errorMessage = "Erreur lors du chargement: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ExpiringMedicineCard: View {
    let medicine: Medicine
    
    private var daysUntilExpiry: Int {
        guard let expiryDate = medicine.expiryDate else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        return max(0, days)
    }
    
    private var expiryColor: Color {
        let days = daysUntilExpiry
        if days <= 7 {
            return .red
        } else if days <= 14 {
            return .orange
        } else {
            return .yellow
        }
    }
    
    private var expiryText: String {
        let days = daysUntilExpiry
        if days == 0 {
            return "Expire aujourd'hui"
        } else if days == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(days) jours"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage ?? "Dosage non spécifié")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let expiryDate = medicine.expiryDate {
                        Text(formatDate(expiryDate))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(expiryColor)
                    }
                    
                    Text("Stock: \(medicine.currentQuantity) \(medicine.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundColor(expiryColor)
                
                Text(expiryText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(expiryColor)
                
                Spacer()
                
                if let reference = medicine.reference {
                    Text("Réf: \(reference)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

struct ExpiringMedicinesEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Aucune expiration proche")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tous vos médicaments ont des dates d'expiration suffisamment éloignées.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}