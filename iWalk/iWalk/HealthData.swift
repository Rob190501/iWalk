//
//  HealthData.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import Foundation
import HealthKit

class HealthData: ObservableObject {
    @Published var data: [(date: Date, steps: Int, calories: Double)]
    private var healthStore: HKHealthStore?
    
    init() {
        data = []
        healthStore = HKHealthStore()
    }
    
    func fetchHealthData(completion: @escaping (String) -> Void) {
        guard let healthStore = healthStore else {
            DispatchQueue.main.async {
                completion("HealthStore non è inizializzato.")
            }
            return
        }
        
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
                        let steps = try await self.fetchDailyData(for: stepsType, unit: .count())
                        let calories = try await self.fetchDailyData(for: caloriesType, unit: .kilocalorie())
                        
                        // 3. Combina i dati
                        let combinedData = self.combineStepsAndCalories(steps: steps, calories: calories)
                        
                        // assegnamento dati recuperati
                        DispatchQueue.main.async { [weak self] in
                            self?.data = combinedData
                        }
                        
                    } catch {
                        // aggiornamento UI nel thread principale
                        DispatchQueue.main.async {
                            completion(error.localizedDescription)
                        }
                    }
                }
            } else if let error = error {
                DispatchQueue.main.async {
                    completion(error.localizedDescription)
                }
            }
        }
    }
    
    // Funzione per recuperare i dati giornalieri di un tipo specifico
    private func fetchDailyData(for type: HKQuantityType, unit: HKUnit) async throws -> [Date: Double] {
        guard let healthStore = healthStore else {
            return [:]
        }
        
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
    }
    
    
    func saveToCSV(completion: @escaping (String) -> Void) {
        // Percorso del file nella directory Documents
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            completion("Impossibile trovare la directory Documents.")
            return
        }
            
        let fileURL = documentsURL.appendingPathComponent("HealthData.csv")
        //let fileURL = documentsURL.appendingPathComponent("HealthData.csv")
            print("Percorso del file CSV: \(fileURL.path)")
        
        // Creazione del contenuto CSV
        var csvText = "Steps,Calories\n" // Header CSV
        
        for record in data {
            let csvLine = "\(record.steps),\(record.calories)\n"
            csvText.append(csvLine)
        }
        
        do {
            // Scrittura del file
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            
        } catch {
            completion("Errore durante il salvataggio del file: \(error.localizedDescription)")
        }
    }

}