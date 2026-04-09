//
//  NetworkMonitor.swift
//  MediStock
//
//  Created by TLILI HAMDI on 28/10/2025.
//

import Foundation
import Network
import Combine

/// Service de monitoring de la connectivité réseau
/// Utilise NWPathMonitor pour détecter les changements d'état réseau en temps réel
@MainActor
final class NetworkMonitor: ObservableObject {

    // MARK: - Published Properties

    /// État actuel de la connexion réseau
    @Published private(set) var status: NetworkStatus = .disconnected

    /// Indique si l'appareil est actuellement connecté
    @Published private(set) var isConnected: Bool = false

    // MARK: - Private Properties

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.medistock.networkmonitor")
    nonisolated(unsafe) private var isMonitoring = false

    // MARK: - Initialization

    init() {
        self.monitor = NWPathMonitor()
        setupMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Démarre le monitoring réseau
    func startMonitoring() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateStatus(from: path)
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    /// Arrête le monitoring réseau
    nonisolated func stopMonitoring() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false
    }

    // MARK: - Private Methods

    /// Configure le monitoring automatique au démarrage
    private func setupMonitoring() {
        startMonitoring()
    }

    /// Met à jour l'état réseau en fonction du path
    private func updateStatus(from path: NWPath) {
        let newIsConnected = path.status == .satisfied

        // Déterminer le type de connexion
        let newStatus: NetworkStatus
        if newIsConnected {
            // Identifier le type d'interface utilisé
            let connectionType: NetworkStatus.ConnectionType
            if path.usesInterfaceType(.wifi) {
                connectionType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                connectionType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                connectionType = .wired
            } else {
                connectionType = .other
            }
            newStatus = .connected(connectionType)
        } else {
            newStatus = .disconnected
        }

        // Mettre à jour les propriétés uniquement si changement
        if self.status != newStatus {
            self.status = newStatus
            self.isConnected = newIsConnected

            // Logger le changement d'état
            logStatusChange(newStatus)
        }
    }

    /// Log les changements d'état réseau pour analytics
    private func logStatusChange(_ newStatus: NetworkStatus) {
        switch newStatus {
        case .connected(let type):
            FirebaseService.shared.logEvent(
                name: "network_connected",
                parameters: ["connection_type": String(describing: type)]
            )
        case .disconnected:
            FirebaseService.shared.logEvent(
                name: "network_disconnected",
                parameters: [:]
            )
        }
    }
}

// MARK: - NetworkMonitor Protocol

/// Protocole pour faciliter les tests et l'injection de dépendances
@MainActor
protocol NetworkMonitorProtocol: AnyObject {
    var status: NetworkStatus { get }
    var isConnected: Bool { get }
    var objectWillChange: ObservableObjectPublisher { get }
    func startMonitoring()
    func stopMonitoring()
}

extension NetworkMonitor: NetworkMonitorProtocol {}
