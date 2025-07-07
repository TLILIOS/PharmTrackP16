import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @State private var searchText = ""
    @State private var isRefreshing = false
    @State private var showingExportOptions = false
    
    // Filtres
    @State private var selectedMedicine: Medicine?
    @State private var selectedTimeRange: TimeRange = .all
    @State private var selectedActionType: ActionType = .all
    
    // Animation properties
    @State private var headerOffset: CGFloat = -20
    @State private var headerOpacity: Double = 0
    @State private var listOpacity: Double = 0
    
    init(historyViewModel: HistoryViewModel) {
        self._viewModel = StateObject(wrappedValue: historyViewModel)
    }

    var body: some View {
        ZStack {
                Color.backgroundApp.opacity(0.1).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HistoryHeaderView(
                        searchText: $searchText,
                        selectedMedicine: $selectedMedicine,
                        selectedTimeRange: $selectedTimeRange,
                        selectedActionType: $selectedActionType,
                        medicines: viewModel.medicines,
                        headerOffset: headerOffset,
                        headerOpacity: headerOpacity,
                        onFilterChange: applyFilters,
                        onExport: { showingExportOptions = true }
                    )
                    
                    HistoryContentView(
                        isLoading: viewModel.isLoading,
                        filteredHistory: filteredHistory,
                        medicines: viewModel.medicines,
                        searchText: searchText,
                        selectedMedicine: selectedMedicine,
                        selectedTimeRange: selectedTimeRange,
                        selectedActionType: selectedActionType,
                        listOpacity: listOpacity,
                        onRefresh: refreshHistory
                    )
            }
            .navigationTitle("Historique")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ResetFiltersButton(
                        isDisabled: isFiltersEmpty,
                        action: resetFilters
                    )
                }
            }
            
            HistoryErrorView(
                state: viewModel.state,
                onDismiss: viewModel.resetState
            )
        }
        .sheet(isPresented: $showingExportOptions) {
            HistoryExportSheet(
                filteredHistory: filteredHistory,
                viewModel: viewModel,
                isPresented: $showingExportOptions
            )
        }
        .onAppear {
            Task {
                await loadData()
                startAnimations()
            }
        }
    }
}

// MARK: - Helper Properties and Methods
extension HistoryView {
    var filteredHistory: [HistoryEntry] {
        HistoryFilter.apply(
            to: viewModel.history,
            searchText: searchText,
            selectedMedicine: selectedMedicine,
            selectedTimeRange: selectedTimeRange,
            selectedActionType: selectedActionType,
            medicines: viewModel.medicines
        )
    }
    
    var isFiltersEmpty: Bool {
        searchText.isEmpty && 
        selectedMedicine == nil && 
        selectedTimeRange == .all && 
        selectedActionType == .all
    }
    
    private func loadData() async {
        await viewModel.fetchMedicines()
        await viewModel.fetchHistory()
    }
    
    private func refreshHistory() async {
        isRefreshing = true
        await viewModel.fetchHistory()
        isRefreshing = false
    }
    
    private func applyFilters() {
        // Logic for filter changes if needed
    }
    
    private func resetFilters() {
        withAnimation {
            searchText = ""
            selectedMedicine = nil
            selectedTimeRange = .all
            selectedActionType = .all
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            headerOffset = 0
            headerOpacity = 1
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            listOpacity = 1
        }
    }
}

// MARK: - Enums
extension HistoryView {
    enum TimeRange: String, CaseIterable, Identifiable {
        case all = "Toutes les dates"
        case today = "Aujourd'hui"
        case week = "Cette semaine"
        case month = "Ce mois"
        case year = "Cette année"
        
        var id: String { self.rawValue }
    }
    
    enum ActionType: String, CaseIterable, Identifiable {
        case all = "Toutes les actions"
        case add = "Ajouts"
        case remove = "Retraits"
        case update = "Mises à jour"
        
        var id: String { self.rawValue }
    }
}

// MARK: - Header View
struct HistoryHeaderView: View {
    @Binding var searchText: String
    @Binding var selectedMedicine: Medicine?
    @Binding var selectedTimeRange: HistoryView.TimeRange
    @Binding var selectedActionType: HistoryView.ActionType
    
    let medicines: [Medicine]
    let headerOffset: CGFloat
    let headerOpacity: Double
    let onFilterChange: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            HistorySearchBar(searchText: $searchText)
            HistoryFilterBar(
                selectedMedicine: $selectedMedicine,
                selectedTimeRange: $selectedTimeRange,
                selectedActionType: $selectedActionType,
                medicines: medicines,
                onFilterChange: onFilterChange,
                onExport: onExport
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .background(Color(.systemBackground))
        .offset(y: headerOffset)
        .opacity(headerOpacity)
    }
}

// MARK: - Search Bar
struct HistorySearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Rechercher dans l'historique...", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Filter Bar
struct HistoryFilterBar: View {
    @Binding var selectedMedicine: Medicine?
    @Binding var selectedTimeRange: HistoryView.TimeRange
    @Binding var selectedActionType: HistoryView.ActionType
    
    let medicines: [Medicine]
    let onFilterChange: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                TimeRangeFilter(
                    selectedTimeRange: $selectedTimeRange,
                    onFilterChange: onFilterChange
                )
                
                ActionTypeFilter(
                    selectedActionType: $selectedActionType,
                    onFilterChange: onFilterChange
                )
                
                MedicineFilter(
                    selectedMedicine: $selectedMedicine,
                    medicines: medicines,
                    onFilterChange: onFilterChange
                )
                
                ExportButton(action: onExport)
            }
            .padding(.vertical, 5)
        }
    }
}

// MARK: - Individual Filter Components
struct TimeRangeFilter: View {
    @Binding var selectedTimeRange: HistoryView.TimeRange
    let onFilterChange: () -> Void
    
    var body: some View {
        Menu {
            ForEach(HistoryView.TimeRange.allCases) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                        onFilterChange()
                    }
                }) {
                    HStack {
                        Text(range.rawValue)
                        if selectedTimeRange == range {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterLabel(
                icon: "calendar",
                text: selectedTimeRange.rawValue
            )
        }
    }
}

struct ActionTypeFilter: View {
    @Binding var selectedActionType: HistoryView.ActionType
    let onFilterChange: () -> Void
    
    var body: some View {
        Menu {
            ForEach(HistoryView.ActionType.allCases) { action in
                Button(action: {
                    withAnimation {
                        selectedActionType = action
                        onFilterChange()
                    }
                }) {
                    HStack {
                        Text(action.rawValue)
                        if selectedActionType == action {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterLabel(
                icon: "arrow.up.arrow.down",
                text: selectedActionType.rawValue
            )
        }
    }
}

struct MedicineFilter: View {
    @Binding var selectedMedicine: Medicine?
    let medicines: [Medicine]
    let onFilterChange: () -> Void
    
    var body: some View {
        Menu {
            Button(action: {
                withAnimation {
                    selectedMedicine = nil
                    onFilterChange()
                }
            }) {
                HStack {
                    Text("Tous les médicaments")
                    if selectedMedicine == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Divider()
            
            ForEach(medicines) { medicine in
                Button(action: {
                    withAnimation {
                        selectedMedicine = medicine
                        onFilterChange()
                    }
                }) {
                    HStack {
                        Text(medicine.name)
                        if selectedMedicine?.id == medicine.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            FilterLabel(
                icon: "pills",
                text: selectedMedicine?.name ?? "Tous les médicaments"
            )
        }
    }
}

// MARK: - Reusable Components
struct FilterLabel: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .foregroundColor(.primary)
        .cornerRadius(15)
    }
}

struct ExportButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("Exporter")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentApp.opacity(0.2))
            .foregroundColor(.accentApp)
            .cornerRadius(15)
        }
    }
}

struct ResetFiltersButton: View {
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(isDisabled)
    }
}

// MARK: - Content View
struct HistoryContentView: View {
    let isLoading: Bool
    let filteredHistory: [HistoryEntry]
    let medicines: [Medicine]
    let searchText: String
    let selectedMedicine: Medicine?
    let selectedTimeRange: HistoryView.TimeRange
    let selectedActionType: HistoryView.ActionType
    let listOpacity: Double
    let onRefresh: () async -> Void
    
    var body: some View {
        Group {
            if isLoading {
                HistoryLoadingView()
            } else if filteredHistory.isEmpty {
                HistoryEmptyView(
                    hasFilters: hasActiveFilters,
                    searchText: searchText
                )
            } else {
                HistoryListView(
                    entries: filteredHistory,
                    medicines: medicines,
                    listOpacity: listOpacity,
                    onRefresh: onRefresh
                )
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || 
        selectedMedicine != nil || 
        selectedTimeRange != .all || 
        selectedActionType != .all
    }
}

// MARK: - State Views
struct HistoryLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView("Chargement de l'historique...")
            Spacer()
        }
    }
}

struct HistoryEmptyView: View {
    let hasFilters: Bool
    let searchText: String
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 70))
                    .foregroundColor(.gray.opacity(0.8))
                
                Text(hasFilters ? "Aucun résultat pour ces filtres" : "Aucun historique")
                    .font(.headline)
                
                Text(hasFilters ? "Essayez de modifier vos critères de recherche" : "L'historique des opérations s'affichera ici")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding()
            Spacer()
        }
    }
}

struct HistoryListView: View {
    let entries: [HistoryEntry]
    let medicines: [Medicine]
    let listOpacity: Double
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    HistoryEntryRow(
                        entry: entry,
                        medicineName: getMedicineName(for: entry.medicineId)
                    )
                    .opacity(listOpacity)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .refreshable {
            await onRefresh()
        }
    }
    
    private func getMedicineName(for id: String) -> String {
        medicines.first(where: { $0.id == id })?.name ?? "Médicament inconnu"
    }
}

// MARK: - Error View
struct HistoryErrorView: View {
    let state: HistoryViewState
    let onDismiss: () -> Void
    
    var body: some View {
        Group {
            if case .error(let message) = state {
                VStack {
                    Spacer()
                    MessageView(message: message, type: .error, dismissAction: onDismiss)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: state)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Export Sheet
struct HistoryExportSheet: View {
    let filteredHistory: [HistoryEntry]
    let viewModel: HistoryViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Format d'export")) {
                    ExportFormatButton(
                        icon: "doc.richtext",
                        title: "PDF",
                        color: .red
                    ) {
                        Task {
                            await viewModel.exportHistory(format: .pdf, entries: filteredHistory)
                            isPresented = false
                        }
                    }
                    
                    ExportFormatButton(
                        icon: "tablecells",
                        title: "CSV (Excel)",
                        color: .green
                    ) {
                        Task {
                            await viewModel.exportHistory(format: .csv, entries: filteredHistory)
                            isPresented = false
                        }
                    }
                }
                
                Section(header: Text("Options")) {
                    ExportFormatButton(
                        icon: "xmark.circle",
                        title: "Annuler",
                        color: .gray
                    ) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Exporter l'historique")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

struct ExportFormatButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
            }
        }
    }
}

// MARK: - Filter Logic
struct HistoryFilter {
    static func apply(
        to history: [HistoryEntry],
        searchText: String,
        selectedMedicine: Medicine?,
        selectedTimeRange: HistoryView.TimeRange,
        selectedActionType: HistoryView.ActionType,
        medicines: [Medicine]
    ) -> [HistoryEntry] {
        history.filter { entry in
            medicineFilter(entry, selectedMedicine) &&
            timeRangeFilter(entry, selectedTimeRange) &&
            actionTypeFilter(entry, selectedActionType) &&
            searchFilter(entry, searchText, medicines)
        }
    }
    
    private static func medicineFilter(_ entry: HistoryEntry, _ selectedMedicine: Medicine?) -> Bool {
        guard let selectedMedicine = selectedMedicine else { return true }
        return entry.medicineId == selectedMedicine.id
    }
    
    private static func timeRangeFilter(_ entry: HistoryEntry, _ selectedTimeRange: HistoryView.TimeRange) -> Bool {
        guard selectedTimeRange != .all else { return true }
        
        let now = Date()
        let calendar = Calendar.current
        
        let startDate: Date = {
            switch selectedTimeRange {
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            case .month:
                return calendar.dateInterval(of: .month, for: now)?.start ?? now
            case .year:
                return calendar.dateInterval(of: .year, for: now)?.start ?? now
            case .all:
                return Date.distantPast
            }
        }()
        
        return entry.timestamp >= startDate
    }
    
    private static func actionTypeFilter(_ entry: HistoryEntry, _ selectedActionType: HistoryView.ActionType) -> Bool {
        guard selectedActionType != .all else { return true }
        
        let actionLowercase = entry.action.lowercased()
        
        switch selectedActionType {
        case .add:
            return actionLowercase.contains("ajout") || actionLowercase.contains("ajouté")
        case .remove:
            return actionLowercase.contains("retrait") || 
                   actionLowercase.contains("suppression") || 
                   actionLowercase.contains("supprimé")
        case .update:
            return actionLowercase.contains("mise à jour") || 
                   actionLowercase.contains("modifié") || 
                   actionLowercase.contains("ajusté")
        case .all:
            return true
        }
    }
    
    private static func searchFilter(_ entry: HistoryEntry, _ searchText: String, _ medicines: [Medicine]) -> Bool {
        guard !searchText.isEmpty else { return true }
        
        let lowercaseSearch = searchText.lowercased()
        let medicineName = medicines.first(where: { $0.id == entry.medicineId })?.name.lowercased() ?? ""
        
        return entry.action.lowercased().contains(lowercaseSearch) ||
               entry.details.lowercased().contains(lowercaseSearch) ||
               medicineName.contains(lowercaseSearch)
    }
}

// MARK: - Entry Row (kept same as original)
struct HistoryEntryRow: View {
    let entry: HistoryEntry
    let medicineName: String
    
    private var actionIcon: String {
        let actionLowercase = entry.action.lowercased()
        
        if actionLowercase.contains("ajout") || actionLowercase.contains("ajouté") {
            return "plus"
        } else if actionLowercase.contains("retrait") || actionLowercase.contains("suppression") || actionLowercase.contains("supprimé") {
            return "minus"
        } else if actionLowercase.contains("mise à jour") || actionLowercase.contains("modifié") || actionLowercase.contains("ajusté") {
            return "arrow.2.circlepath"
        } else {
            return "clock.arrow.circlepath"
        }
    }
    
    private var actionColor: Color {
        let actionLowercase = entry.action.lowercased()
        
        if actionLowercase.contains("ajout") || actionLowercase.contains("ajouté") {
            return .green
        } else if actionLowercase.contains("retrait") || actionLowercase.contains("suppression") || actionLowercase.contains("supprimé") {
            return .red
        } else if actionLowercase.contains("mise à jour") || actionLowercase.contains("modifié") || actionLowercase.contains("ajusté") {
            return .blue
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(actionColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: actionIcon)
                        .font(.system(size: 16))
                        .foregroundColor(actionColor)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(medicineName)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(formatDate(entry.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.action)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(entry.details)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    let mockViewModel = HistoryViewModel(
        getHistoryUseCase: MockGetHistoryUseCase(),
        getMedicinesUseCase: MockGetMedicinesUseCase(),
        exportHistoryUseCase: MockExportHistoryUseCase()
    )
    
    HistoryView(historyViewModel: mockViewModel)
}
