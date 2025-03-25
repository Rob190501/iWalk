//
//  HealthDataStorage.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 24/03/25.
//

import Foundation
import Combine

class HealthDataStorage: ObservableObject {
    @Published var healthData: [HealthData] = [] {
        didSet {
            if let encoded = try? JSONEncoder().encode(healthData) {
                UserDefaults.standard.set(encoded, forKey: "healthData")
            }
        }
    }
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: "healthData"),
           let decoded = try? JSONDecoder().decode([HealthData].self, from: savedData) {
            self.healthData = decoded
        }
    }
}
