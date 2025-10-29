//
//  NetworkStatus.swift
//  MediStock
//
//  Created by TLILI HAMDI on 28/10/2025.
//

import Foundation
import Network

/// Représente l'état de la connexion réseau
enum NetworkStatus: Equatable {
    case connected(ConnectionType)
    case disconnected

    /// Type de connexion réseau
    enum ConnectionType: Equatable {
        case wifi
        case cellular
        case wired
        case other

        init(from interfaceType: NWInterface.InterfaceType) {
            switch interfaceType {
            case .wifi:
                self = .wifi
            case .cellular:
                self = .cellular
            case .wiredEthernet:
                self = .wired
            case .loopback, .other:
                self = .other
            @unknown default:
                self = .other
            }
        }
    }

    /// Indique si l'appareil est connecté au réseau
    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }

    /// Description lisible de l'état réseau
    var displayText: String {
        switch self {
        case .connected(let type):
            switch type {
            case .wifi:
                return "Connecté (Wi-Fi)"
            case .cellular:
                return "Connecté (Cellulaire)"
            case .wired:
                return "Connecté (Ethernet)"
            case .other:
                return "Connecté"
            }
        case .disconnected:
            return "Hors ligne"
        }
    }
}
