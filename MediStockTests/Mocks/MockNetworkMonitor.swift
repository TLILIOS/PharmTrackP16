//
//  MockNetworkMonitor.swift
//  MediStockTests
//
//  Created by TLILI HAMDI on 28/10/2025.
//

import Foundation
import Combine
@testable import MediStock

/// Mock du NetworkMonitor pour les tests
@MainActor
class MockNetworkMonitor: NetworkMonitorProtocol, ObservableObject {

    // MARK: - Published Properties

    @Published var status: NetworkStatus
    @Published var isConnected: Bool

    // MARK: - Test Configuration

    /// Permet de simuler des changements d'état réseau dans les tests
    func simulateNetworkChange(to newStatus: NetworkStatus) {
        // Déclencher objectWillChange AVANT de modifier les propriétés
        // pour que les observers soient notifiés correctement
        objectWillChange.send()

        // Mettre à jour les propriétés @Published
        // Ceci déclenchera automatiquement une seconde notification via @Published
        self.status = newStatus
        self.isConnected = newStatus.isConnected

        // Pour les tests synchrones, forcer la mise à jour immédiate
        // en donnant un petit délai pour que la chaîne Combine se propage
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001))
    }

    /// Simule une connexion réseau
    func simulateConnection(type: NetworkStatus.ConnectionType = .wifi) {
        simulateNetworkChange(to: .connected(type))
    }

    /// Simule une déconnexion réseau
    func simulateDisconnection() {
        simulateNetworkChange(to: .disconnected)
    }

    // MARK: - Initialization

    init(initialStatus: NetworkStatus = .connected(.wifi)) {
        self.status = initialStatus
        self.isConnected = initialStatus.isConnected
    }

    // MARK: - NetworkMonitorProtocol

    func startMonitoring() {
        // Mock: ne fait rien
    }

    func stopMonitoring() {
        // Mock: ne fait rien
    }
}

// MARK: - Test Helpers

extension MockNetworkMonitor {
    /// Crée un mock avec état connecté
    static func connected(_ type: NetworkStatus.ConnectionType = .wifi) -> MockNetworkMonitor {
        MockNetworkMonitor(initialStatus: .connected(type))
    }

    /// Crée un mock avec état déconnecté
    static func disconnected() -> MockNetworkMonitor {
        MockNetworkMonitor(initialStatus: .disconnected)
    }
}
