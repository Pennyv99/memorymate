//
//  FaceEnrollmentView.swift
//  MemoryMate
//

import PhotosUI
import SwiftUI

struct FaceEnrollmentView: View {
    @StateObject private var vm = FaceEnrollmentVM()

    var body: some View {
        NavigationStack {
            Form {
                Section("Photos (3–5)") {
                    PhotosPicker(
                        selection: $vm.selectedItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Select Photos", systemImage: "photo.on.rectangle")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(vm.images.enumerated()), id: \.offset) { _, img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .frame(height: vm.images.isEmpty ? 0 : 88)
                }

                Section("Identity") {
                    TextField("Name", text: $vm.name)
                    TextField("Relation (e.g. Daughter)", text: $vm.relation)
                }
            }
            .navigationTitle("Enroll Person")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink("Continue") {
                        FaceConfirmView(vm: vm)
                    }
                    .disabled(!vm.isReady)
                }
            }
        }
    }
}
