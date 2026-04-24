//
//  Medication.swift
//  MemoryMate
//

import Foundation

struct Medication: Identifiable, Codable, Hashable {
    let id: Int
    let drug: String
    let dose: String
    let times: [String]
    let condition: String
}

struct MedicationRequest: Codable, Hashable {
    var drug: String
    var dose: String
    var times: [String]
    var condition: String
}
