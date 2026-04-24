//
//  Person.swift
//  MemoryMate
//

import Foundation

struct Person: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let relation: String
}
