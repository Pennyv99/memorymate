//
//  FaceConfirmView.swift
//  MemoryMate
//

import SwiftUI

struct FaceConfirmView: View {
    @ObservedObject var vm: FaceEnrollmentVM
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appError: AppErrorState

    @State private var isSaving = false

    var body: some View {
        Form {
            Section("Photos") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(vm.images.enumerated()), id: \.offset) { _, img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            Section("Identity") {
                LabeledContent("Name", value: vm.name)
                LabeledContent("Relation", value: vm.relation.isEmpty ? "—" : vm.relation)
            }
        }
        .navigationTitle("Confirm")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving || vm.images.isEmpty)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await vm.enroll()
            vm.reset()
            dismiss()
        } catch {
            appError.present(error)
        }
    }
}
