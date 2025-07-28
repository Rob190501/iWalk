//
//  HealthData.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 10/03/25.
//

import Foundation
import TabularData

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

extension Array where Element == HealthData {
    
    func toDataFrame() -> DataFrame {
        guard !self.isEmpty else {
            return DataFrame()
        }
        
        let steps = self.map { $0.steps }
        let exerciseMinutes = self.map { $0.exerciseMinutes }
        let calories = self.map { $0.calories }
        
        var dataFrame = DataFrame()
        dataFrame.append(column: Column(name: "Steps", contents: steps))
        dataFrame.append(column: Column(name: "ExerciseMinutes", contents: exerciseMinutes))
        dataFrame.append(column: Column(name: "Calories", contents: calories))
        
        return dataFrame
    }
    
}
