import SwiftUI

struct CriticalStockView: View {
    @Environment(\.viewModelCreator) private var viewModelCreator
    @ObservedObject var dashboardViewModel: DashboardViewModel
    @State private var isRefreshing = false
    @State private var selectedMedicine: Medicine?
    @State private var showingMedicineDetail = false
    @State private var showingAdjustStock = false
    @State private var medicineForAdjustment: Medicine?
    
    // Animation properties
    @State private var listItemsOpacity: [String: Double] = [:]
    @State private var listItemsOffset: [String: CGFloat] = [:]
    
    init(dashboardViewModel: DashboardViewModel) {
        self.dashboardViewModel = dashboardViewModel
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack {
                if dashboardViewModel.state == .loading {
                    Spacer()
                    ProgressView("Chargement des stocks critiques...")
                    Spacer()
                } else if dashboardViewModel.criticalStockMedicines.isEmpty {
                    CriticalStockEmptyView()
                } else {
                    criticalStockList
                }
            }
            .navigationTitle("Stocks critiques")
            .navigationBarTitleDisplayMode(.large)
            
            // Message de succès/erreur
            if case .error(let message) = dashboardViewModel.state {
                VStack {
                    Spacer()
                    
                    MessageView(message: message, type: .error) {
                        dashboardViewModel.resetState()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: dashboardViewModel.state)
                .zIndex(1)
            }
        }
        .onAppear {
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .refreshable {
            await performRefresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))) { _ in
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded"))) { _ in
            Task {
                await dashboardViewModel.fetchData()
                animateListItems()
            }
        }
        .sheet(isPresented: $showingMedicineDetail) {
            if let medicine = selectedMedicine {
                NavigationStack {
                    MedicineDetailView(
                        medicineId: medicine.id,
                        viewModel: viewModelCreator.createMedicineDetailViewModel(medicine: medicine)
                    )
                }
            }
        }
        .sheet(isPresented: $showingAdjustStock) {
            if let medicine = medicineForAdjustment {
                NavigationStack {
                    AdjustStockView(
                        medicineId: medicine.id,
                        viewModel: viewModelCreator.createAdjustStockViewModel(
                            medicineId: medicine.id,
                            medicine: medicine
                        )
                    )
                }
            }
        }
    }
    
    private var criticalStockList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(dashboardViewModel.criticalStockMedicines, id: \.id) { medicine in
                    CriticalStockMedicineRow(medicine: medicine) {
                    // Navigation vers les détails du médicament via sheet
                    selectedMedicine = medicine
                    showingMedicineDetail = true
                } onAdjustStock: {
                    // Affichage direct de la vue d'ajustement du stock en sheet
                    medicineForAdjustment = medicine
                    showingAdjustStock = true
                }
                .onTapGesture {
                    selectedMedicine = medicine
                    showingMedicineDetail = true
                }
                    .opacity(listItemsOpacity[medicine.id] ?? 0)
                    .offset(y: listItemsOffset[medicine.id] ?? 50)
                    .animation(
                        .easeOut(duration: 0.6).delay(0.1),
                        value: listItemsOpacity[medicine.id]
                    )
                }
            }
            .padding()
        }
    }
    
    private func animateListItems() {
        for (index, medicine) in dashboardViewModel.criticalStockMedicines.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                listItemsOpacity[medicine.id] = 1.0
                listItemsOffset[medicine.id] = 0
            }
        }
    }
    
    private func performRefresh() async {
        isRefreshing = true
        await dashboardViewModel.fetchData()
        isRefreshing = false
    }
}

struct CriticalStockMedicineRow: View {
    let medicine: Medicine
    let onTap: () -> Void
    let onAdjustStock: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    
                    Text("/ \(medicine.maxQuantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Barre de progression
            ProgressView(value: Double(max(0, min(medicine.currentQuantity, medicine.maxQuantity))), total: Double(max(1, medicine.maxQuantity)))
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Seuil critique: \(medicine.criticalThreshold)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: onAdjustStock) {
                    Label("Ajuster", systemImage: "plus.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentApp)
                        .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        // Navigation gérée par NavigationLink wrapper
    }
}

struct CriticalStockEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Aucun stock critique")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tous vos médicaments ont des stocks suffisants.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}


#Preview {
    NavigationView {
        CriticalStockView(dashboardViewModel: DashboardViewModel(
            getUserUseCase: MockGetUserUseCase(),
            getMedicinesUseCase: MockGetMedicinesUseCase(),
            getAislesUseCase: MockGetAislesUseCase(),
            getRecentHistoryUseCase: MockGetRecentHistoryUseCase()
        ))
    }
}
