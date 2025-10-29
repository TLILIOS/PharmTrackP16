//
//  NetworkStatusBanner.swift
//  MediStock
//
//  Created by TLILI HAMDI on 28/10/2025.
//

import SwiftUI

/// Banner affichant l'état de la connexion réseau
/// Apparaît uniquement quand hors ligne ou en cours de synchronisation
struct NetworkStatusBanner: View {

    // MARK: - Properties

    let status: NetworkStatus
    let isSyncing: Bool

    // MARK: - Private Properties

    private var shouldShow: Bool {
        !status.isConnected || isSyncing
    }

    private var bannerColor: Color {
        if !status.isConnected {
            return .orange
        } else if isSyncing {
            return .blue
        } else {
            return .green
        }
    }

    private var iconName: String {
        if !status.isConnected {
            return "wifi.slash"
        } else if isSyncing {
            return "arrow.clockwise"
        } else {
            return "wifi"
        }
    }

    private var displayText: String {
        if !status.isConnected {
            return "Hors ligne - Modifications enregistrées localement"
        } else if isSyncing {
            return "Synchronisation en cours..."
        } else {
            return "Connecté"
        }
    }

    // MARK: - Body

    var body: some View {
        if shouldShow {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .medium))
                    .rotationEffect(.degrees(isSyncing ? 360 : 0))
                    .animation(
                        isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                        value: isSyncing
                    )

                Text(displayText)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(bannerColor)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: shouldShow)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(displayText)
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

// MARK: - Convenience Initializer

extension NetworkStatusBanner {
    /// Initializer simple pour affichage basique sans indicateur de sync
    init(status: NetworkStatus) {
        self.status = status
        self.isSyncing = false
    }
}

// MARK: - Preview

#Preview("Disconnected") {
    NetworkStatusBanner(status: .disconnected, isSyncing: false)
        .padding()
}

#Preview("Connected WiFi") {
    NetworkStatusBanner(status: .connected(.wifi), isSyncing: false)
        .padding()
}

#Preview("Syncing") {
    NetworkStatusBanner(status: .connected(.wifi), isSyncing: true)
        .padding()
}

#Preview("All States") {
    VStack(spacing: 20) {
        NetworkStatusBanner(status: .disconnected, isSyncing: false)
        NetworkStatusBanner(status: .connected(.wifi), isSyncing: true)
        NetworkStatusBanner(status: .connected(.cellular), isSyncing: false)
    }
    .padding()
}
