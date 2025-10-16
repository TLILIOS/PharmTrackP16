import SwiftUI

struct ModernHistoryView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @EnvironmentObject var medicineViewModel: MedicineListViewModel
    @State private var expandedEntries: Set<String> = []
    @State private var searchText = ""
    @Namespace private var animation

    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    var filteredHistory: [StockHistory] {
        let filtered = historyViewModel.filteredHistory

        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { entry in
                getMedicineName(for: entry).localizedCaseInsensitiveContains(searchText) ||
                (entry.reason?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if historyViewModel.isLoading && historyViewModel.stockHistory.isEmpty {
                ProgressView()
                    .scaleEffect(1.2)
            } else if filteredHistory.isEmpty && !searchText.isEmpty {
                emptySearchState
            } else if filteredHistory.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                        // Search Bar
                        if !historyViewModel.stockHistory.isEmpty {
                            searchBar
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                        }
                        
                        // Filters
                        filterSection
                            .padding(.bottom, 10)
                        
                        // Timeline
                        ForEach(groupedHistory, id: \.key) { date, entries in
                            Section {
                                ForEach(entries) { entry in
                                    ModernHistoryRow(
                                        entry: entry,
                                        medicineName: getMedicineName(for: entry),
                                        isExpanded: expandedEntries.contains(entry.id),
                                        onTap: {
                                            toggleExpansion(for: entry)
                                        }
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.8).combined(with: .opacity)
                                    ))
                                }
                            } header: {
                                sectionHeader(for: date)
                            }
                        }
                        
                        // Bottom padding
                        Color.clear
                            .frame(height: 100)
                    }
                }
                .refreshable {
                    await refreshHistory()
                }
            }
        }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.large)
        .task {
            // Toujours recharger l'historique pour avoir les données fraîches
            await historyViewModel.loadHistory()
            // Charger les médicaments seulement si nécessaire
            if medicineViewModel.medicines.isEmpty {
                await medicineViewModel.loadMedicines()
            }
        }
        .animation(.spring(response: 0.3), value: historyViewModel.filterType)
        .animation(.spring(response: 0.3), value: searchText)
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Rechercher dans l'historique...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HistoryViewModel.FilterType.allCases) { type in
                    ModernFilterPill(
                        type: type,
                        isSelected: historyViewModel.filterType == type,
                        count: getCount(for: type),
                        namespace: animation
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            historyViewModel.filterType = type
                            impactFeedback.impactOccurred()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func sectionHeader(for date: Date) -> some View {
        HStack {
            Text(formatSectionDate(date))
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(groupedHistory.first(where: { $0.key == date })?.value.count ?? 0) entrées")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            Color(.systemGroupedBackground)
                .opacity(0.95)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text("Aucun historique")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("L'historique des mouvements de stock apparaîtra ici")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("Aucun résultat")
                .font(.headline)
            
            Text("Essayez avec d'autres mots-clés")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var groupedHistory: [(key: Date, value: [StockHistory])] {
        let grouped = Dictionary(grouping: filteredHistory) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Aujourd'hui"
        } else if calendar.isDateInYesterday(date) {
            return "Hier"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.locale = Locale(identifier: "fr_FR")
            return formatter.string(from: date)
        }
    }
    
    private func getMedicineName(for entry: StockHistory) -> String {
        medicineViewModel.medicines.first { $0.id == entry.medicineId }?.name ?? "Médicament supprimé"
    }

    private func getCount(for type: HistoryViewModel.FilterType) -> Int {
        switch type {
        case .all:
            return historyViewModel.stockHistory.count
        case .adjustments:
            return historyViewModel.stockHistory.filter { $0.type == .adjustment }.count
        case .additions:
            return historyViewModel.stockHistory.filter { $0.type == .addition }.count
        case .deletions:
            return historyViewModel.stockHistory.filter { $0.type == .deletion }.count
        }
    }
    
    private func toggleExpansion(for entry: StockHistory) {
        withAnimation(.spring(response: 0.3)) {
            if expandedEntries.contains(entry.id) {
                expandedEntries.remove(entry.id)
            } else {
                expandedEntries.insert(entry.id)
            }
        }
        impactFeedback.impactOccurred()
    }
    
    private func refreshHistory() async {
        await historyViewModel.loadHistory()
        await medicineViewModel.loadMedicines()
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Views

struct ModernFilterPill: View {
    let type: HistoryViewModel.FilterType
    let isSelected: Bool
    let count: Int
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.callout)
                
                Text(type.rawValue)
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : type.color.opacity(0.2))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(type.color)
                            .matchedGeometryEffect(id: "filter", in: namespace)
                    } else {
                        Capsule()
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct ModernHistoryRow: View {
    let entry: StockHistory
    let medicineName: String
    let isExpanded: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // Type indicator
                    ZStack {
                        Circle()
                            .fill(entry.type.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: entry.type.icon)
                            .font(.title3)
                            .foregroundColor(entry.type.color)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicineName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(entry.type.label)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if entry.type == .adjustment {
                                HStack(spacing: 4) {
                                    Text("\(entry.previousQuantity)")
                                        .foregroundColor(.secondary)
                                    Image(systemName: "arrow.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(entry.newQuantity)")
                                        .fontWeight(.semibold)
                                        .foregroundColor(entry.change > 0 ? .green : .red)
                                }
                                .font(.caption)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Time and chevron
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTime(entry.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if entry.reason != nil {
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded content
            if isExpanded, let reason = entry.reason {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Raison", systemImage: "text.quote")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(reason)
                            .font(.callout)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Label("Utilisateur \(entry.userId)", systemImage: "person.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatFullDate(entry.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    )
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// MARK: - Extensions

extension StockHistory.HistoryType {
    var icon: String {
        switch self {
        case .adjustment: return "arrow.up.arrow.down.circle.fill"
        case .addition: return "plus.circle.fill"
        case .deletion: return "trash.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .adjustment: return .blue
        case .addition: return .green
        case .deletion: return .red
        }
    }
    
    var label: String {
        switch self {
        case .adjustment: return "Ajustement de stock"
        case .addition: return "Médicament ajouté"
        case .deletion: return "Médicament supprimé"
        }
    }
}

// MARK: - Mock Data

extension StockHistory {
    static var mockData: [StockHistory] {
        [
            StockHistory(
                id: "1",
                medicineId: "med1",
                userId: "user1",
                type: .adjustment,
                date: Date(),
                change: -5,
                previousQuantity: 50,
                newQuantity: 45,
                reason: "Délivrance sur ordonnance"
            ),
            StockHistory(
                id: "2",
                medicineId: "med2",
                userId: "user2",
                type: .addition,
                date: Date().addingTimeInterval(-3600),
                change: 100,
                previousQuantity: 0,
                newQuantity: 100,
                reason: "Nouveau médicament ajouté au stock"
            ),
            StockHistory(
                id: "3",
                medicineId: "med3",
                userId: "user3",
                type: .deletion,
                date: Date().addingTimeInterval(-86400),
                change: -5,
                previousQuantity: 5,
                newQuantity: 0,
                reason: "Médicament expiré - Destruction conforme"
            )
        ]
    }
}

// MARK: - Preview

struct ModernHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ModernHistoryView()
                .environmentObject(AppState())
        }
    }
}