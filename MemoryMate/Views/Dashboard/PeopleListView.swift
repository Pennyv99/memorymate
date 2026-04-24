//
//  PeopleListView.swift
//  MemoryMate
//

import SwiftUI

struct PeopleListView: View {
    let people: [Person]
    let reload: () async -> Void

    @EnvironmentObject private var appError: AppErrorState

    var body: some View {
        List {
            ForEach(people) { person in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.name)
                            .font(.headline)
                        Text(person.relation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                Task {
                    for index in offsets {
                        let person = people[index]
                        do {
                            try await APIService.shared.delete("/faces/\(person.id)")
                            await reload()
                        } catch {
                            appError.present(error)
                        }
                    }
                }
            }
        }
        .overlay {
            if people.isEmpty {
                ContentUnavailableView(
                    "No people yet",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Enroll someone from the People tab.")
                )
            }
        }
        .refreshable { await reload() }
    }
}
