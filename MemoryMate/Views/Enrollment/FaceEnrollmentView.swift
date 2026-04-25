//
//  FaceEnrollmentView.swift
//  MemoryMate
//

import PhotosUI
import SwiftUI
import UIKit

struct FaceEnrollmentView: View {
    @StateObject private var vm = FaceEnrollmentVM()
    @State private var showCamera = false
    @State private var cameraCapture: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section("Photos (1–5)") {
                    if vm.maxGallerySlots > 0 {
                        HStack {
                            Spacer(minLength: 0)
                            PhotosPicker(
                                selection: $vm.selectedItems,
                                maxSelectionCount: min(5, vm.maxGallerySlots),
                                matching: .images
                            ) {
                                Label("Select photos", systemImage: "photo.on.rectangle")
                            }
                            Spacer(minLength: 0)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    } else {
                        Text("Library picks are full (5 photos). Remove a camera photo to add from the library.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        HStack {
                            Spacer(minLength: 0)
                            Button {
                                guard vm.images.count < 5 else { return }
                                showCamera = true
                            } label: {
                                Label("Take photo", systemImage: "camera.fill")
                            }
                            .disabled(vm.images.count >= 5)
                            Spacer(minLength: 0)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
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

                    if !vm.images.isEmpty {
                        Text("\(vm.images.count) photo(s) — at least one clear face.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            .fullScreenCover(isPresented: $showCamera) {
                CameraImagePicker(image: $cameraCapture)
                    .ignoresSafeArea()
            }
            .onChange(of: vm.selectedItems) { _, _ in
                Task { await vm.syncPickerSelectionWithCap() }
            }
            .onChange(of: vm.cameraImages.count) { _, _ in
                Task { await vm.syncPickerSelectionWithCap() }
            }
            .onChange(of: cameraCapture) { _, new in
                if let new {
                    vm.appendCameraImage(new)
                    cameraCapture = nil
                }
            }
            .task {
                await vm.syncPickerSelectionWithCap()
            }
        }
    }
}
