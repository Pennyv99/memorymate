//
//  MedVoiceView.swift
//  MemoryMate
//

import SwiftUI

struct MedVoiceView: View {
    @ObservedObject var vm: MedicationVM
    @StateObject private var speech = SpeechService()
    @EnvironmentObject private var appError: AppErrorState

    @State private var selectedField: MedicationVoiceCaptureField = .drugName
    @State private var lastAppliedHint: String?

    private var previewRow: MedicationRequest {
        guard vm.importItems.indices.contains(0) else {
            return MedicationRequest(drug: "", dose: "", times: [], condition: "")
        }
        return vm.importItems[0]
    }

    var body: some View {
        ZStack {
            MedicationFormTheme.pageGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                Text("Record each field separately so text does not all land in the drug name.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)

                MMSectionTitle(text: "Target field")
                MMGlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedField.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(MedicationVoiceCaptureField.allCases) { field in
                                    MMChoiceChip(
                                        title: field.rawValue,
                                        isSelected: selectedField == field
                                    ) {
                                        selectedField = field
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                MMSectionTitle(text: "Microphone")
                MMGlassCard {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(
                                    speech.isRecording
                                        ? Color.red.opacity(0.15)
                                        : MedicationFormTheme.accent.opacity(0.12)
                                )
                                .frame(width: 120, height: 120)
                            Circle()
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [MedicationFormTheme.accent, MedicationFormTheme.violet],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: speech.isRecording ? 4 : 3
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(speech.isRecording ? 1.04 : 1)
                                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: speech.isRecording)

                            Button {
                                if speech.isRecording {
                                    speech.stopRecording()
                                    applyTranscript()
                                } else {
                                    do {
                                        try speech.startRecording()
                                        lastAppliedHint = nil
                                    } catch {
                                        appError.present(error)
                                    }
                                }
                            } label: {
                                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(speech.isRecording ? Color.red : Color.white)
                                    .frame(width: 76, height: 76)
                                    .background {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: speech.isRecording
                                                        ? [Color.red.opacity(0.85), Color.red.opacity(0.55)]
                                                        : [MedicationFormTheme.accent, MedicationFormTheme.violet],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(speech.isRecording ? "Stop and apply to \(selectedField.rawValue)" : "Start recording")
                        }

                        Text(speech.isRecording ? "Listening… tap stop when finished." : "Tap the mic, speak, then tap stop to fill \(selectedField.rawValue).")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }

                if !speech.transcript.isEmpty {
                    MMSectionTitle(text: "Live transcript")
                    MMGlassCard {
                        Text(speech.transcript)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }

                if let hint = lastAppliedHint {
                    Text(hint)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MedicationFormTheme.accentDeep)
                        .padding(.horizontal, 4)
                }

                MMSectionTitle(text: "Live preview")
                MMGlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        previewLine("Drug", previewRow.drug)
                        previewLine("Dose", previewRow.dose)
                        previewLine("Condition", previewRow.condition)
                    }
                }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Voice entry")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                NavigationLink("Review") {
                    MedConfirmListView(vm: vm)
                }
            }
        }
        .onAppear {
            vm.prepareVoiceSessionIfNeeded()
        }
        .onDisappear {
            if speech.isRecording {
                speech.stopRecording()
            }
        }
    }

    @ViewBuilder
    private func previewLine(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
            Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }

    private func applyTranscript() {
        let text = speech.transcript
        vm.applyVoiceTranscript(text, to: selectedField, itemIndex: 0)
        lastAppliedHint = "Applied to \(selectedField.rawValue)."
    }
}
