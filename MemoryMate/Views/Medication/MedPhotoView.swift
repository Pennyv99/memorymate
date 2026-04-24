//
//  MedPhotoView.swift
//  MemoryMate
//

import PhotosUI
import SwiftUI
import UIKit

private enum PhotoPickError: LocalizedError {
    case couldNotLoadData
    case couldNotDecodeImage

    var errorDescription: String? {
        switch self {
        case .couldNotLoadData:
            return "Could not load the photo file. If it is in iCloud, open Photos and wait until it finishes downloading, then pick it again."
        case .couldNotDecodeImage:
            return "Could not open the selected image."
        }
    }
}

struct MedPhotoView: View {
    @ObservedObject var vm: MedicationVM
    @EnvironmentObject private var appError: AppErrorState

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var isReading = false
    @State private var extractedSummary: String?

    private let ocr = OCRService()

    var body: some View {
        Form {
            Section("Prescription photo") {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(image == nil ? "Select photo" : "Change photo", systemImage: "photo")
                }
                .onChange(of: pickerItem) { _, newValue in
                    Task { await loadImage(from: newValue) }
                }

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if pickerItem != nil {
                    ProgressView("Loading photo…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }

            if let extractedSummary {
                Section("Last recognition") {
                    Text(extractedSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section {
                Button {
                    Task { await runOCR() }
                } label: {
                    if isReading {
                        Label("Reading…", systemImage: "text.viewfinder")
                    } else {
                        Label("Read text from photo", systemImage: "text.viewfinder")
                    }
                }
                .disabled(image == nil || isReading)
            } footer: {
                if image == nil, pickerItem != nil {
                    Text("Still loading the image, or it failed to load. Check the error alert if one appeared.")
                } else if image == nil {
                    Text("Choose a photo first. The button stays disabled until the image is ready.")
                }
            }
        }
        .navigationTitle("Photo entry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                NavigationLink("Review") {
                    MedConfirmListView(vm: vm)
                }
            }
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else {
            image = nil
            extractedSummary = nil
            return
        }
        extractedSummary = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw PhotoPickError.couldNotLoadData
            }
            guard let uiImage = UIImage(data: data) else {
                throw PhotoPickError.couldNotDecodeImage
            }
            image = uiImage
        } catch {
            image = nil
            appError.present(error)
        }
    }

    private func runOCR() async {
        guard let image else { return }
        isReading = true
        defer { isReading = false }
        do {
            let text = try await ocr.recognizeText(from: image)
            vm.applyImportedMedications(from: text)
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                extractedSummary = "No text was recognized. Try a sharper photo, better lighting, or enter details manually on Review."
            } else {
                let preview = trimmed.count > 600 ? String(trimmed.prefix(600)) + "…" : trimmed
                extractedSummary = "Raw text (\(trimmed.count) chars):\n\(preview)"
            }
        } catch {
            extractedSummary = nil
            appError.present(error)
        }
    }
}
