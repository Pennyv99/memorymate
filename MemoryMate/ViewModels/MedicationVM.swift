//
//  MedicationVM.swift
//  MemoryMate
//

import Combine
import Foundation

enum MedicationImportError: LocalizedError {
    case emptyList
    case emptyDrugAtRows([Int])

    var errorDescription: String? {
        switch self {
        case .emptyList:
            return "Add at least one medication before saving."
        case .emptyDrugAtRows(let rows):
            let list = rows.map { String($0 + 1) }.joined(separator: ", ")
            return "Drug name is required on row(s): \(list)."
        }
    }
}

@MainActor
final class MedicationVM: ObservableObject {
    /// Parsed / edited medications before batch upload (no cloud — only Pi HTTP).
    @Published var importItems: [MedicationRequest] = []

    func applyImportedMedications(from ocrOrSpeechText: String) {
        let parsed = MedicationParser().parseMany(from: ocrOrSpeechText)
        importItems = parsed.map {
            MedicationRequest(
                drug: $0.drug,
                dose: $0.dose,
                times: $0.times,
                condition: $0.condition
            )
        }
        if importItems.isEmpty {
            let fallbackCondition = MedicationParser.extractConditionForDisplay(from: ocrOrSpeechText)
            importItems = [
                MedicationRequest(drug: "", dose: "", times: [], condition: fallbackCondition),
            ]
        }
    }

    func appendEmptyImportItem() {
        let sharedCondition = importItems.first?.condition ?? ""
        importItems.append(MedicationRequest(drug: "", dose: "", times: [], condition: sharedCondition))
    }

    func deleteImportItems(_ offsets: IndexSet) {
        var copy = importItems
        for i in offsets.sorted(by: >) {
            guard copy.indices.contains(i) else { continue }
            copy.remove(at: i)
        }
        importItems = copy
    }

    func replaceImportItem(at index: Int, with item: MedicationRequest) {
        guard importItems.indices.contains(index) else { return }
        importItems[index] = item
    }

    func saveAllImported() async throws {
        guard !importItems.isEmpty else { throw MedicationImportError.emptyList }

        let emptyRows = importItems.enumerated()
            .filter { $0.element.drug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map(\.offset)
        guard emptyRows.isEmpty else {
            throw MedicationImportError.emptyDrugAtRows(emptyRows)
        }

        struct Created: Decodable {
            let id: Int
        }

        for var item in importItems {
            item.drug = item.drug.trimmingCharacters(in: .whitespacesAndNewlines)
            item.dose = item.dose.trimmingCharacters(in: .whitespacesAndNewlines)
            item.condition = item.condition.trimmingCharacters(in: .whitespacesAndNewlines)
            item.times = item.times.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            let _: Created = try await APIService.shared.post("/add-medication", body: item)
        }
    }

    func resetImportSession() {
        importItems = []
    }

    /// One blank row for voice capture (no bulk parser — avoids dumping everything into drug name).
    func prepareVoiceSessionIfNeeded() {
        if importItems.isEmpty {
            importItems = [MedicationRequest(drug: "", dose: "", times: [], condition: "")]
        }
    }

    func applyVoiceTranscript(_ text: String, to field: MedicationVoiceCaptureField, itemIndex: Int = 0) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard importItems.indices.contains(itemIndex) else { return }
        var row = importItems[itemIndex]
        switch field {
        case .drugName:
            row.drug = trimmed
        case .dose:
            row.dose = trimmed
        case .condition:
            row.condition = trimmed
        }
        replaceImportItem(at: itemIndex, with: row)
    }
}
