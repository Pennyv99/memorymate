//
//  SettingsVM.swift
//  MemoryMate
//

import Combine
import Foundation

@MainActor
final class SettingsVM: ObservableObject {
    @Published var piIP: String {
        didSet { UserDefaults.standard.set(piIP, forKey: "piIP") }
    }

    @Published private(set) var connectionStatus: ConnectionStatus = .untested

    enum ConnectionStatus {
        case untested
        case checking
        case online
        case offline
    }

    init() {
        self.piIP = UserDefaults.standard.string(forKey: "piIP") ?? ""
    }

    func testConnection() async {
        connectionStatus = .checking
        do {
            let _: [String: String] = try await APIService.shared.get("/health")
            connectionStatus = .online
        } catch {
            connectionStatus = .offline
        }
    }
}
