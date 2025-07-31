import SwiftUI

// MARK: - HistoryDetailView avec filtres et export

struct HistoryDetailView: View {
    @StateObject private var viewModel = HistoryDetailViewModel()
    @State private var showingFilters = false
    @State private var showingExportOptions = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    
    let medicineId: String?
    
    init(medicineId: String? = nil) {
        self.medicineId = medicineId
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de filtres
                FilterBarView(
                    selectedDateRange: $viewModel.selectedDateRange,
                    showingFilters: $showingFilters,
                    activeFiltersCount: activeFiltersCount
                )
                
                // Statistiques
                if let statistics = viewModel.statistics {
                    HistoryStatisticsView(statistics: statistics)
                        .padding()
                }
                
                // Liste d'historique
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Chargement de l'historique...")
                    Spacer()
                } else if viewModel.filteredEntries.isEmpty {
                    EmptyHistoryView()
                } else {
                    HistoryListView(entries: viewModel.filteredEntries)
                }
            }
            .navigationTitle(medicineId == nil ? "Historique" : "Historique médicament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExportOptions = true }) {
                            Label("Exporter", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: refreshHistory) {
                            Label("Actualiser", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                HistoryFiltersView(
                    selectedActionType: $viewModel.selectedActionType,
                    searchText: $viewModel.searchText,
                    onApply: {
                        viewModel.applyFilters()
                    }
                )
            }
            .sheet(isPresented: $showingExportOptions) {
                HistoryExportOptionsView(
                    onExport: { format in
                        Task {
                            await exportHistory(format: format)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .task {
                await loadHistory()
            }
        }
        .trackScreen("HistoryDetail")
    }
    
    // MARK: - Computed Properties
    
    private var activeFiltersCount: Int {
        var count = 0
        if viewModel.selectedActionType != nil { count += 1 }
        if !viewModel.searchText.isEmpty { count += 1 }
        return count
    }
    
    // MARK: - Methods
    
    private func loadHistory() async {
        if let medicineId = medicineId {
            await viewModel.loadHistoryForMedicine(medicineId)
        } else {
            await viewModel.loadHistory()
        }
    }
    
    private func refreshHistory() {
        Task {
            await loadHistory()
        }
    }
    
    private func exportHistory(format: ExportFormat) async {
        do {
            let url = try await viewModel.exportHistory(format: format)
            exportedFileURL = url
            showingShareSheet = true
        } catch {
            print("Erreur d'export: \(error)")
        }
    }
}

// MARK: - FilterBarView

struct FilterBarView: View {
    @Binding var selectedDateRange: DateRange
    @Binding var showingFilters: Bool
    let activeFiltersCount: Int
    
    var body: some View {
        HStack {
            // Sélecteur de période
            Menu {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Button(action: { selectedDateRange = range }) {
                        HStack {
                            Text(range.rawValue)
                            if selectedDateRange == range {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                    Text(selectedDateRange.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .font(.subheadline)
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Bouton filtres
            Button(action: { showingFilters.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filtres")
                    if activeFiltersCount > 0 {
                        Text("(\(activeFiltersCount))")
                            .fontWeight(.semibold)
                    }
                }
                .font(.subheadline)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - HistoryStatisticsView

struct HistoryStatisticsView: View {
    let statistics: HistoryStatistics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistiques du mois")
                .font(.headline)
            
            // Compteurs
            HStack(spacing: 16) {
                StatisticCard(
                    title: "Total",
                    value: "\(statistics.totalActions)",
                    icon: "chart.bar",
                    color: .blue
                )
                
                StatisticCard(
                    title: "Ajouts",
                    value: "\(statistics.addActions)",
                    icon: "plus.circle",
                    color: .green
                )
                
                StatisticCard(
                    title: "Retraits",
                    value: "\(statistics.removeActions)",
                    icon: "minus.circle",
                    color: .orange
                )
            }
            
            // Top médicaments
            if !statistics.topMedicines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Médicaments les plus actifs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(statistics.topMedicines.prefix(3), id: \.name) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                            Spacer()
                            Text("\(item.count) actions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - StatisticCard

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - HistoryListView

struct HistoryListView: View {
    let entries: [HistoryEntry]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(groupedEntries, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            HistoryRowView(entry: entry)
                            
                            if entry != group.entries.last {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    } header: {
                        HStack {
                            Text(group.date.formatted(date: .complete, time: .omitted))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(AppColors.background)
                    }
                }
            }
        }
    }
    
    private var groupedEntries: [(date: Date, entries: [HistoryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value) }
    }
}

// MARK: - HistoryRowView

struct HistoryRowView: View {
    let entry: HistoryEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icône
            Image(systemName: actionIcon)
                .font(.title3)
                .foregroundColor(actionColor)
                .frame(width: 40, height: 40)
                .background(actionColor.opacity(0.1))
                .clipShape(Circle())
            
            // Contenu
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.action)
                    .font(.headline)
                
                Text(entry.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var actionIcon: String {
        if entry.action.contains("Ajout") {
            return "plus.circle"
        } else if entry.action.contains("Retrait") {
            return "minus.circle"
        } else if entry.action.contains("Modification") {
            return "pencil.circle"
        } else if entry.action.contains("Suppression") {
            return "trash.circle"
        } else {
            return "info.circle"
        }
    }
    
    private var actionColor: Color {
        if entry.action.contains("Ajout") {
            return .green
        } else if entry.action.contains("Retrait") {
            return .orange
        } else if entry.action.contains("Modification") {
            return .blue
        } else if entry.action.contains("Suppression") {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - EmptyHistoryView

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucun historique")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Les actions effectuées apparaîtront ici")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - HistoryFiltersView

struct HistoryFiltersView: View {
    @Binding var selectedActionType: ActionType?
    @Binding var searchText: String
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type d'action") {
                    ForEach([ActionType?.none] + ActionType.allCases.map { ActionType?.some($0) }, id: \.self) { type in
                        HStack {
                            if let actionType = type {
                                Label(actionType.rawValue, systemImage: actionType.icon)
                                    .foregroundColor(actionType.color)
                            } else {
                                Text("Toutes les actions")
                            }
                            
                            Spacer()
                            
                            if selectedActionType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedActionType = type
                        }
                    }
                }
                
                Section("Recherche") {
                    TextField("Rechercher dans l'historique...", text: $searchText)
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Appliquer") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - HistoryExportOptionsView

struct HistoryExportOptionsView: View {
    let onExport: (ExportFormat) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Button(action: {
                    onExport(.csv)
                    dismiss()
                }) {
                    Label("Exporter en CSV", systemImage: "doc.text")
                }
                
                Button(action: {
                    onExport(.pdf)
                    dismiss()
                }) {
                    Label("Exporter en PDF", systemImage: "doc.richtext")
                }
                .disabled(true) // TODO: Implémenter l'export PDF
            }
            .navigationTitle("Format d'export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// ShareSheet est maintenant définie dans Components.swift

// MARK: - Previews

struct HistoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryDetailView()
    }
}