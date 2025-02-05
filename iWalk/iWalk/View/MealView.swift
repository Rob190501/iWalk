//
//  MealView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import SwiftUI
import SwiftData


struct MealView: View {
    @Query private var meals: [Meal]
    
    private let sampleBreakfast = Meal(mealTime: .breakfast, details: "", kcal: 0)
    
    private let sampleMorningSnack = Meal(mealTime: .morningSnack, details: "", kcal: 0)
    
    private let sampleLunch = Meal(mealTime: .lunch, details: "", kcal: 0)
    
    private let sampleAfternoonSnack = Meal(mealTime: .afternoonSnack, details: "", kcal: 0)
    
    private let sampleDinner = Meal(mealTime: .dinner, details: "", kcal: 0)
    
    @StateObject private var gpt = GPT()
    
    var body: some View {
        
        NavigationStack {
            ScrollView {
                Spacer()
                
                MealField(label: "Colazione",
                          meal: meals.filter { $0.mealTime == MealTime.breakfast.rawValue }.first ?? sampleBreakfast,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Snack mattutino",
                          meal: meals.filter { $0.mealTime == MealTime.morningSnack.rawValue }.first ?? sampleMorningSnack,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Pranzo",
                          meal: meals.filter { $0.mealTime == MealTime.lunch.rawValue }.first ?? sampleLunch,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Snack pomeridiano",
                          meal: meals.filter { $0.mealTime == MealTime.afternoonSnack.rawValue }.first ?? sampleAfternoonSnack,
                          gpt: gpt)
                
                CustomDivider()
                
                MealField(label: "Cena",
                          meal: meals.filter { $0.mealTime == MealTime.dinner.rawValue }.last ?? sampleDinner,
                          gpt: gpt)
            }
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .customToolbar(icon: "carrot", title: "Pasti") {
                Text("Totale: \(meals.reduce(0) { $0 + $1.kcal }) kcal")
            }
        }
        
    }
}



#Preview {
    MealView()
        .modelContainer(for: Meal.self, inMemory: true)
}
