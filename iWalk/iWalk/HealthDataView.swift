//
//  HealthDataView.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//


import SwiftUI
import HealthKit

struct HealthDataView: View {
    //@State private var healthData: [(date: Date, steps: Int, calories: Double)] = []
    @State private var errorMessage: String?
    @ObservedObject private var healthData = HealthData()
    
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack {
            if let errorMessage = errorMessage {
                Text("Errore: \(errorMessage)")
                    .foregroundColor(.red)
            } else if healthData.data.isEmpty {
                Text("Nessun dato disponibile")
                    .foregroundColor(.gray)
                
                Button {
                    healthData.fetchHealthData(completion: printError)
                } label: {
                    Text("Fetch")
                }
                
            } else {
                Button {
                    healthData.saveToCSV(completion: printError)
                } label: {
                    Text("Salva")
                }
                
                
                Button {
                    healthData.trainModel()
                } label: {
                    Text("Allena")
                }
                
                Button {
                    healthData.predictSteps(forCalories: 700.0)
                } label: {
                    Text("Prevedi")
                }
                
                List(healthData.data, id: \.date) { record in
                    HStack {
                        Text(formatDate(date: record.date))
                        Spacer()
                        Text("\(record.steps) passi")
                        Spacer()
                        Text("\(record.calories, specifier: "%.2f") kcal")
                    }
                }
            }
        }
    }
    
    /*func fetchHealthData() {
        // Definizione dei tipi di dati da leggere
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let readTypes: Set = [stepsType, caloriesType]
        
        // 1. Richiedi autorizzazione
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if success {
                Task {
                    do {
                        // 2. Recupera i dati
                        let steps = try await fetchDailyData(for: stepsType, unit: .count())
                        let calories = try await fetchDailyData(for: caloriesType, unit: .kilocalorie())
                        
                        // 3. Combina i dati
                        let combinedData = await combineStepsAndCalories(steps: steps, calories: calories)
                        
                        // aggiornamento UI nel thread principale
                        DispatchQueue.main.async {
                            self.healthData = combinedData
                        }
                    } catch {
                        // aggiornamento UI nel thread principale
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // Funzione per recuperare i dati giornalieri di un tipo specifico
    private func fetchDailyData(for type: HKQuantityType, unit: HKUnit) async throws -> [Date: Double] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -2, to: Date())!
        let endDate = Date()
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let interval = DateComponents(day: 1)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.cumulativeSum],
                anchorDate: calendar.startOfDay(for: startDate),
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var dailyData: [Date: Double] = [:]
                if let statsCollection = results {
                    statsCollection.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                        if let quantity = stats.sumQuantity() {
                            let date = stats.startDate
                            dailyData[date] = quantity.doubleValue(for: unit)
                        }
                    }
                }
                continuation.resume(returning: dailyData)
            }
            
            healthStore.execute(query)
        }
    }
    
    // Funzione per combinare i dati di passi e calorie
    private func combineStepsAndCalories(steps: [Date: Double], calories: [Date: Double]) -> [(date: Date, steps: Int, calories: Double)] {
        var combinedData: [(date: Date, steps: Int, calories: Double)] = []
        
        let allDates = Set(steps.keys).union(calories.keys)
        
        for date in allDates {
            if let stepCount = steps[date], let calorieCount = calories[date] {
                combinedData.append((date: date, steps: Int(stepCount), calories: calorieCount))
            }
        }
        
        return combinedData.sorted {
            return $0.date < $1.date
        }
    }*/
    
    func formatDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"  // Imposta il formato desiderato
        return dateFormatter.string(from: date)
    }
    
    func printError(errorMessage: String) {
        self.errorMessage = errorMessage
    }
}
