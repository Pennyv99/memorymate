//
//  DashboardView.swift
//  MemoryMate
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appError: AppErrorState
    @State private var people: [Person] = []
    @State private var medications: [Medication] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                Section("Summary") {
                    LabeledContent("People", value: "\(people.count)")
                    LabeledContent("Medications", value: "\(medications.count)")
                }

                Section("People") {
                    NavigationLink("View all people") {
                        PeopleListView(people: people, reload: { await load() })
                            .navigationTitle("People")
                    }
                }

                Section("Medications") {
                    NavigationLink("View all medications") {
                        MedicationListView(medications: medications, reload: { await load() })
                            .navigationTitle("Medications")
                    }
                }
            }
            .navigationTitle("Home")
            .refreshable { await load() }
            .overlay {
                if isLoading && people.isEmpty && medications.isEmpty {
                    ProgressView()
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let faces: [Person] = APIService.shared.get("/faces")
            async let meds: [Medication] = APIService.shared.get("/medications")
            (people, medications) = try await (faces, meds)
        } catch {
            appError.present(error)
        }
    }
}
