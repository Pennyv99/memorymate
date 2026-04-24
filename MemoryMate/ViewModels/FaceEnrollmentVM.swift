//
//  FaceEnrollmentVM.swift
//  MemoryMate
//

import Combine
import Foundation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class FaceEnrollmentVM: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet { Task { await loadImages() } }
    }

    @Published private(set) var images: [UIImage] = []
    @Published var name = ""
    @Published var relation = ""

    var isReady: Bool {
        (3...5).contains(images.count) && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadImages() async {
        var loaded: [UIImage] = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        images = loaded
    }

    func enroll() async throws {
        try await APIService.shared.enrollFace(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            relation: relation.trimmingCharacters(in: .whitespacesAndNewlines),
            images: images
        )
    }

    func reset() {
        selectedItems = []
        images = []
        name = ""
        relation = ""
    }
}
