//
//  NetworkMonitorTests.swift
//  MediStockTests
//
//  Created by TLILI HAMDI on 28/10/2025.
//

import XCTest
@testable import MediStock

@MainActor
final class NetworkMonitorTests: XCTestCase {

    // MARK: - NetworkStatus Tests

    func testNetworkStatusConnected() {
        // Given
        let wifiStatus = NetworkStatus.connected(.wifi)
        let cellularStatus = NetworkStatus.connected(.cellular)
        let disconnectedStatus = NetworkStatus.disconnected

        // Then
        XCTAssertTrue(wifiStatus.isConnected)
        XCTAssertTrue(cellularStatus.isConnected)
        XCTAssertFalse(disconnectedStatus.isConnected)
    }

    func testNetworkStatusDisplayText() {
        // Given
        let wifiStatus = NetworkStatus.connected(.wifi)
        let cellularStatus = NetworkStatus.connected(.cellular)
        let wiredStatus = NetworkStatus.connected(.wired)
        let disconnectedStatus = NetworkStatus.disconnected

        // Then
        XCTAssertEqual(wifiStatus.displayText, "Connecté (Wi-Fi)")
        XCTAssertEqual(cellularStatus.displayText, "Connecté (Cellulaire)")
        XCTAssertEqual(wiredStatus.displayText, "Connecté (Ethernet)")
        XCTAssertEqual(disconnectedStatus.displayText, "Hors ligne")
    }

    func testNetworkStatusEquality() {
        // Given
        let wifi1 = NetworkStatus.connected(.wifi)
        let wifi2 = NetworkStatus.connected(.wifi)
        let cellular = NetworkStatus.connected(.cellular)
        let disconnected1 = NetworkStatus.disconnected
        let disconnected2 = NetworkStatus.disconnected

        // Then
        XCTAssertEqual(wifi1, wifi2)
        XCTAssertNotEqual(wifi1, cellular)
        XCTAssertEqual(disconnected1, disconnected2)
        XCTAssertNotEqual(wifi1, disconnected1)
    }

    // MARK: - MockNetworkMonitor Tests

    func testMockNetworkMonitorInitialState() {
        // Given
        let connectedMock = MockNetworkMonitor(initialStatus: .connected(.wifi))
        let disconnectedMock = MockNetworkMonitor(initialStatus: .disconnected)

        // Then
        XCTAssertTrue(connectedMock.isConnected)
        XCTAssertEqual(connectedMock.status, .connected(.wifi))

        XCTAssertFalse(disconnectedMock.isConnected)
        XCTAssertEqual(disconnectedMock.status, .disconnected)
    }

    func testMockNetworkMonitorSimulateConnection() {
        // Given
        let mock = MockNetworkMonitor(initialStatus: .disconnected)
        XCTAssertFalse(mock.isConnected)

        // When
        mock.simulateConnection(type: .wifi)

        // Then
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.status, .connected(.wifi))
    }

    func testMockNetworkMonitorSimulateDisconnection() {
        // Given
        let mock = MockNetworkMonitor(initialStatus: .connected(.wifi))
        XCTAssertTrue(mock.isConnected)

        // When
        mock.simulateDisconnection()

        // Then
        XCTAssertFalse(mock.isConnected)
        XCTAssertEqual(mock.status, .disconnected)
    }

    func testMockNetworkMonitorSimulateNetworkChange() {
        // Given
        let mock = MockNetworkMonitor(initialStatus: .connected(.wifi))

        // When - Change to cellular
        mock.simulateNetworkChange(to: .connected(.cellular))

        // Then
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.status, .connected(.cellular))

        // When - Change to disconnected
        mock.simulateNetworkChange(to: .disconnected)

        // Then
        XCTAssertFalse(mock.isConnected)
        XCTAssertEqual(mock.status, .disconnected)
    }

    func testMockNetworkMonitorFactoryMethods() {
        // Given
        let connectedMock = MockNetworkMonitor.connected(.wifi)
        let disconnectedMock = MockNetworkMonitor.disconnected()

        // Then
        XCTAssertTrue(connectedMock.isConnected)
        XCTAssertEqual(connectedMock.status, .connected(.wifi))

        XCTAssertFalse(disconnectedMock.isConnected)
        XCTAssertEqual(disconnectedMock.status, .disconnected)
    }

    // MARK: - Integration Tests

    func testNetworkMonitorProtocolConformance() {
        // Given
        let mock = MockNetworkMonitor()

        // When/Then - Should conform to protocol
        XCTAssertNoThrow(mock.startMonitoring())
        XCTAssertNoThrow(mock.stopMonitoring())
    }

    func testNetworkStatusObservation() async {
        // Given
        let mock = MockNetworkMonitor(initialStatus: .disconnected)
        let expectation = XCTestExpectation(description: "Status change observed")

        // When
        Task {
            // Observer le changement
            if mock.status == .disconnected {
                mock.simulateConnection(type: .wifi)
            }

            if mock.status == .connected(.wifi) {
                expectation.fulfill()
            }
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.status, .connected(.wifi))
    }

    // MARK: - Edge Cases

    func testMultipleNetworkChanges() {
        // Given
        let mock = MockNetworkMonitor(initialStatus: .disconnected)

        // When - Multiple rapid changes
        mock.simulateConnection(type: .wifi)
        XCTAssertTrue(mock.isConnected)

        mock.simulateDisconnection()
        XCTAssertFalse(mock.isConnected)

        mock.simulateConnection(type: .cellular)
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.status, .connected(.cellular))

        mock.simulateConnection(type: .wifi)
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.status, .connected(.wifi))
    }

    func testNetworkConnectionTypes() {
        // Given
        let mock = MockNetworkMonitor()

        // Test all connection types
        let types: [NetworkStatus.ConnectionType] = [.wifi, .cellular, .wired, .other]

        for type in types {
            // When
            mock.simulateConnection(type: type)

            // Then
            XCTAssertTrue(mock.isConnected)
            XCTAssertEqual(mock.status, .connected(type))
        }
    }
}
