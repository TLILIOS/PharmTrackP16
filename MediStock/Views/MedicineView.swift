import SwiftUI

// MARK: - Vue Médicaments corrigée utilisant MVVM

struct MedicineListView: View {
    @EnvironmentObject var medicineViewModel: MedicineListViewModel
    @EnvironmentObject var aisleViewModel: AisleListViewModel
    @State private var showingAddForm = false
    @State private var showingSearchView = false
    @State private var addButtonRotation: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                content
                    .padding(.top, 10)
                
                // Header avec ombre
                headerShadow
            }
            .navigationTitle("Médicaments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            addButtonRotation += 90
                        }
                        showingAddForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            .rotationEffect(.degrees(addButtonRotation))
                    }
                }
            }
                .sheet(isPresented: $showingAddForm) {
                    NavigationStack {
                        MedicineFormView(medicine: nil)
                            .environmentObject(medicineViewModel)
                            .environmentObject(aisleViewModel)
                    }
                }
                .navigationDestination(for: MedicineDestination.self) { destination in
                    switch destination {
                    case .add:
                        MedicineFormView(medicine: nil)
                            .environmentObject(medicineViewModel)
                            .environmentObject(aisleViewModel)
                    case .detail(let medicine):
                        MedicineDetailView(medicine: medicine)
                            .environmentObject(medicineViewModel)
                            .environmentObject(aisleViewModel)
                    case .edit(let medicine):
                        MedicineFormView(medicine: medicine)
                            .environmentObject(medicineViewModel)
                            .environmentObject(aisleViewModel)
                    case .adjustStock(let medicine):
                        StockAdjustmentView(medicine: medicine)
                            .environmentObject(medicineViewModel)
                    }
                }
                .onAppear {
                    // S'assurer que les données sont chargées
                    if medicineViewModel.isEmpty && !medicineViewModel.isLoading {
                        Task {
                            await medicineViewModel.loadMedicines()
                            await aisleViewModel.loadAisles()
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if medicineViewModel.isLoading && medicineViewModel.isEmpty {
            loadingView
        } else if medicineViewModel.isEmpty {
            emptyView
        } else {
            medicinesList
        }
    }
    
    private var loadingView: some View {
        ProgressView("Chargement des médicaments...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Illustration moderne
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pills.circle")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                Text("Aucun médicament")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                
                Text("Commencez à gérer votre inventaire\nen ajoutant votre premier médicament")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    addButtonRotation += 90
                }
                showingAddForm = true
            }) {
                Label("Ajouter un médicament", systemImage: "plus.circle.fill")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
            
            Spacer()
        }
        .padding()
    }
    
    private var medicinesList: some View {
        ScrollView {
            VStack(spacing: 0) {
                searchAndFilterBar

                // Nombre de résultats avec transition
                if !medicineViewModel.searchText.isEmpty || medicineViewModel.selectedAisleId != nil {
                    HStack {
                        Text("\(medicineViewModel.filteredMedicines.count) résultat(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                }

                // Liste des médicaments
                LazyVStack(spacing: 12) {
                    ForEach(medicineViewModel.filteredMedicines) { medicine in
                        NavigationLink(value: MedicineDestination.detail(medicine)) {
                            ModernMedicineCard(medicine: medicine)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            // Pagination
                            if medicine.id == medicineViewModel.filteredMedicines.last?.id {
                                Task {
                                    await medicineViewModel.loadMoreMedicines()
                                }
                            }
                        }
                    }

                    // Indicateur de chargement pour pagination
                    if medicineViewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
        }
        .refreshable {
            await medicineViewModel.loadMedicines()
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Barre de recherche modernisée
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.systemGray))
                
                TextField("Rechercher un médicament...", text: $medicineViewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))

                if !medicineViewModel.searchText.isEmpty {
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            medicineViewModel.searchText = ""
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.systemGray2))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray5), lineWidth: 0.5)
            )
            
            // Filtre par rayon
            if !aisleViewModel.aisles.isEmpty {
                Picker("Rayon", selection: $medicineViewModel.selectedAisleId) {
                    Text("Tous les rayons").tag(String?.none)
                    ForEach(aisleViewModel.aisles) { aisle in
                        Label(aisle.name, systemImage: aisle.icon)
                            .tag(String?.some(aisle.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var headerShadow: some View {
        GeometryReader { geometry in
            VStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground).opacity(0.9),
                        Color(UIColor.systemBackground).opacity(0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 10)
                .blur(radius: 2)
                
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Carte de médicament moderne

struct ModernMedicineCard: View {
    let medicine: Medicine
    @EnvironmentObject var aisleViewModel: AisleListViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône du type de médicament
            medicineIcon
            
            // Informations principales
            VStack(alignment: .leading, spacing: 6) {
                Text(medicine.name)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let dosage = medicine.dosage {
                    Text(dosage)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Rayon
                if let aisle = aisleViewModel.aisles.first(where: { $0.id == medicine.aisleId }) {
                    HStack(spacing: 4) {
                        Image(systemName: aisle.icon)
                            .font(.system(size: 12))
                        Text(aisle.name)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(aisle.color.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Badge de stock et quantité
            VStack(alignment: .trailing, spacing: 8) {
                ModernStockBadge(status: medicine.stockStatus)
                
                HStack(spacing: 2) {
                    Text("\(medicine.currentQuantity)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("/")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("\(medicine.maxQuantity)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medicine.name), \(medicine.currentQuantity) sur \(medicine.maxQuantity) unités, état du stock: \(medicine.stockStatus.label)")
    }
    
    @ViewBuilder
    private var medicineIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(medicine.stockStatus.statusColor.opacity(0.1))
                .frame(width: 48, height: 48)
            
            Image(systemName: "pills.fill")
                .font(.system(size: 24))
                .foregroundColor(medicine.stockStatus.statusColor)
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5)
    }
}

// MARK: - Badge de stock moderne

struct ModernStockBadge: View {
    let status: StockStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.statusColor)
                .frame(width: 6, height: 6)
            
            Text(status.shortLabel)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(status.statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.statusColor.opacity(0.15))
        )
    }
}

extension StockStatus {
    var shortLabel: String {
        switch self {
        case .normal: return "Normal"
        case .warning: return "Faible"
        case .critical: return "Critique"
        }
    }
}