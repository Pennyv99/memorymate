//
//  MedEntryView.swift
//  MemoryMate
//

import SwiftUI

struct MedEntryView: View {
    @StateObject private var vm = MedicationVM()

    var body: some View {
        NavigationStack {
            List {
                Section("Choose how to enter") {
                    NavigationLink {
                        MedPhotoView(vm: vm)
                    } label: {
                        Label("Prescription photo", systemImage: "doc.text.viewfinder")
                    }

                    NavigationLink {
                        MedVoiceView(vm: vm)
                    } label: {
                        Label("Voice entry", systemImage: "mic.fill")
                    }
                }
            }
            .navigationTitle("Medications")
        }
    }
}
