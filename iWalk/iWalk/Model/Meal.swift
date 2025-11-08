//
//  Meal.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 11/01/25.
//
import Foundation
import SwiftData
import SwiftUI

@Model
class Meal {
    @Attribute(.unique) var mealTime: String
    var details: String
    var kcal: Int
    
    init(mealTime: MealTime, details: String, kcal: Int) {
        self.mealTime = mealTime.rawValue
        self.details = details
        self.kcal = kcal
    }
    
    init(mealTime: String, details: String, kcal: Int) {
        self.mealTime = mealTime
        self.details = details
        self.kcal = kcal
    }
}

enum MealTime: String, Codable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
}
