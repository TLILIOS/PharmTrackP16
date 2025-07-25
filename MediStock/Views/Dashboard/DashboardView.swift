import SwiftUI

// Import du fichier NavigationDestinations pour accéder aux types de destinations
// Note: Assurez-vous que ce fichier est dans le même target

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @Environment(\.viewModelCreator) private var viewModelCreator
    @State private var refreshTimestamp = Date()
    @State private var showingSearchSheet = false
    
    // Animation properties
    @State private var headerScale = 0.95
    @State private var headerOpacity = 0.0
    @State private var cardsOffset: [Int: CGFloat] = [:]
    @State private var cardsOpacity: [Int: Double] = [:]
    @State private var actionsOffset = CGFloat(30)
    @State private var actionsOpacity = Double(0)
    
    init(dashboardViewModel: DashboardViewModel) {
        self._viewModel = StateObject(wrappedValue: dashboardViewModel)
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 20) {
                    // En-tête avec salutation
                    welcomeHeader
                    
                    // Cartes de résumé
                    summaryCards
                    
                    // Section stocks critiques
                    if !viewModel.criticalStockMedicines.isEmpty {
                        stockAlertSection
                    }
                    
                    // Actions rapides
                    quickActionsSection
                    
                    // Activité récente
                    if !viewModel.recentHistory.isEmpty {
                        recentActivitySection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .refreshable {
                refreshTimestamp = Date()
                await viewModel.fetchData()
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
        .task {
            await viewModel.fetchData()
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await viewModel.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded"))) { _ in
            Task {
                await viewModel.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))) { _ in
            Task {
                await viewModel.fetchData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await viewModel.fetchData()
            }
        }
    }
    
    // MARK: - View Components
    
    private var welcomeHeader: some View {
        VStack(spacing: 10) {
            if let userName = viewModel.userName {
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
                value: "\(viewModel.totalMedicines)",
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
                value: "\(viewModel.totalAisles)",
                icon: "tray.full",
                color: .purple,
                offset: cardsOffset[1, default: 50],
                opacity: cardsOpacity[1, default: 0]
            )
            .onTapGesture {
                NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 2)
            }
            
            // Carte Stock critique
            DashboardCard(
                title: "Médicaments critiques",
                value: "\(viewModel.criticalStockMedicines.count)",
                icon: "exclamationmark.triangle",
                color: viewModel.criticalStockMedicines.isEmpty ? .green : .red,
                offset: cardsOffset[2, default: 50],
                opacity: cardsOpacity[2, default: 0]
            )
            
            // Carte Expirations proches
            DashboardCard(
                title: "Expirations proches",
                value: "\(viewModel.expiringMedicines.count)",
                icon: "clock",
                color: viewModel.expiringMedicines.isEmpty ? .green : .orange,
                offset: cardsOffset[3, default: 50],
                opacity: cardsOpacity[3, default: 0]
            )
        }
    }
    
    private var stockAlertSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stocks critiques")
                .font(.headline)
                .padding(.bottom, 5)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(viewModel.criticalStockMedicines.prefix(5)) { medicine in
                        DashboardCriticalStockCard(medicine: medicine) { }
                    }
                }
                .padding(.bottom, 5)
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
                NavigationLink(destination: MedicineFormView(
                    medicineId: nil,
                    viewModel: viewModelCreator.createMedicineFormViewModel(medicineId: nil)
                )) {
                    QuickActionButtonContent(
                        title: "Ajouter un médicament",
                        icon: "plus.circle",
                        color: .accentApp
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Ajuster un stock
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("switchToTab"), object: 1)
                }) {
                    QuickActionButtonContent(
                        title: "Ajuster un stock",
                        icon: "arrow.up.arrow.down",
                        color: .orange
                    )
                }
                
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
                ForEach(viewModel.recentHistory.prefix(3)) { entry in
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
                            Text(viewModel.getMedicineName(for: entry.medicineId))
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
                    viewModel.navigateToHistory()
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

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let offset: CGFloat
    let opacity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(color)
                    .clipShape(Circle())
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .offset(y: offset)
        .opacity(opacity)
    }
}

struct DashboardCriticalStockCard: View {
    let medicine: Medicine
    let onAdjustStock: () -> Void
    
    private var stockPercentage: Double {
        guard medicine.maxQuantity > 0 else { return 0 }
        return Double(medicine.currentQuantity) / Double(medicine.maxQuantity)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(medicine.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack {
                Text("\(medicine.currentQuantity) / \(medicine.maxQuantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(medicine.unit)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            ProgressView(value: stockPercentage)
                .tint(.red)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                        
                        Text("Stock critique")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 150, height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct QuickActionButtonContent: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SearchViewModel
    @State private var searchText = ""
    
    var body: some View {
        List {
            if searchText.isEmpty {
                Section {
                    Text("Commencez à taper pour rechercher des médicaments ou des rayons.")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            } else {
                if !viewModel.medicineResults.isEmpty {
                    Section(header: Text("Médicaments")) {
                        ForEach(viewModel.medicineResults) { medicine in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(medicine.name)
                                        .font(.headline)
                                    Text(medicine.description ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(medicine.currentQuantity) \(medicine.unit)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if !viewModel.aisleResults.isEmpty {
                    Section(header: Text("Rayons")) {
                        ForEach(viewModel.aisleResults) { aisle in
                            HStack {
                                Circle()
                                    .fill(aisle.color)
                                    .frame(width: 20, height: 20)
                                Text(aisle.name)
                                    .font(.headline)
                                if let description = aisle.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.medicineResults.isEmpty && viewModel.aisleResults.isEmpty {
                    Section {
                        Text("Aucun résultat trouvé pour '\(searchText)'.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .navigationTitle("Rechercher")
        .searchable(text: $searchText)
        .onChange(of: searchText) { oldValue, newValue in
            if !newValue.isEmpty {
                Task {
                    await viewModel.search(query: newValue)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Fermer") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let mockViewModel = DashboardViewModel(
        getUserUseCase: MockGetUserUseCase(),
        getMedicinesUseCase: MockGetMedicinesUseCase(),
        getAislesUseCase: MockGetAislesUseCase(),
        getRecentHistoryUseCase: MockGetRecentHistoryUseCase()
    )
    
    DashboardView(dashboardViewModel: mockViewModel)
}
