//
//  HealthData.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 10/03/25.
//

import Foundation

struct HealthData: Codable {
    var date: Date
    var steps: Int
    var exerciseMinutes: Int
    var calories: Int
}

extension HealthData: Identifiable {
    var id: String {
        "\(date.timeIntervalSince1970)_\(UUID().uuidString)"
    }
}
