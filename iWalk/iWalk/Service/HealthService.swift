//
//  HealthData.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import Foundation
import HealthKit

class HealthService {
    
    static var shared = HealthService()
    private var healthStore: HKHealthStore?
    
    
    
    private init() {
        healthStore = HKHealthStore()
    }
    
    
    
    func fetchHealthData(since years: Int, removeOutliers: Bool, tolerance: Double, generateSyntheticData: Bool, records: Double) async throws -> [HealthData] {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }

        // Definizione dei tipi di dati da leggere
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let readTypes: Set = [stepsType, exerciseTimeType, caloriesType]

        // 1. Richiedi autorizzazione
        let success: Bool = try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }

        // Controlla se l'autorizzazione è stata concessa
        if !success {
            throw CustomError.HKAuthorizationFailed
        }

        // 2. Recupera i dati
        let steps = try await fetchDailyData(for: stepsType, unit: .count(), since: years)
        let exerciseMinutes = try await fetchDailyData(for: exerciseTimeType, unit: .minute(), since: years)
        let calories = try await fetchDailyData(for: caloriesType, unit: .kilocalorie(), since: years)
        
        // 3. Combina i dati ed eventualmente rimuove gli outlier
        var combinedData = combineData(steps: steps, exerciseMinutes: exerciseMinutes, calories: calories)
        
        if removeOutliers {
            combinedData = self.removeOutliers(from: combinedData, tolerance: tolerance)
            
            if generateSyntheticData {
                combinedData += self.generateSyntheticData(from: combinedData, count: Int(records * Double(combinedData.count)))
            }
        }
        
        return combinedData
    }
    
    
    private func fetchDailyData(for type: HKQuantityType, unit: HKUnit, since years: Int) async throws -> [Date: Int] {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -years, to: Date())!
        let today = calendar.startOfDay(for: Date())
        
        let query = HKStatisticsCollectionQuery(
            quantityType: type,
            quantitySamplePredicate: HKQuery.predicateForSamples(withStart: startDate, end: nil),
            options: .cumulativeSum,
            anchorDate: today,
            intervalComponents: DateComponents(day: 1)
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                var dailyData: [Date: Int] = [:]
                
                results?.enumerateStatistics(from: startDate, to: today) { stats, _ in
                    let date = calendar.startOfDay(for: stats.startDate)
                    dailyData[date] = Int(stats.sumQuantity()?.doubleValue(for: unit) ?? 0)
                }
                
                continuation.resume(returning: dailyData)
            }
            
            healthStore.execute(query)
        }
    }
    
    
    
    private func removeOutliers(from data: [HealthData], tolerance: Double) -> [HealthData] {
        let tempData = data.filter { record in
            record.calories > 30
        }
        
        var kcalsPerStep = 0.0
        for record in tempData {
            kcalsPerStep += Double(record.calories) / Double(record.steps)
        }
        kcalsPerStep /= Double(tempData.count)
        
        let lowerBound = kcalsPerStep - tolerance
        let upperBound = kcalsPerStep + tolerance
        
        return tempData.filter { record in
            let kcalsPerStep = Double(record.calories) / Double(record.steps)
            return kcalsPerStep >= lowerBound && kcalsPerStep <= upperBound
        }
    }
    
    func generateSyntheticData(from realData: [HealthData], count: Int) -> [HealthData] {
        guard !realData.isEmpty else {
            return []
        }
        
        var syntheticData: [HealthData] = []
        
        for _ in 0..<count {
            // Record casuale
            let randomIndex = Int.random(in: 0..<realData.count)
            let realRecord = realData[randomIndex]
            
            // Calcola variazione casuale (entro +-15%)
            let variation = Double.random(in: 0.85...1.15)
            
            // Applica le variazioni
            let syntheticSteps = Int(Double(realRecord.steps) * variation)
            let syntheticExercise = Int(Double(realRecord.exerciseMinutes) * variation)
            let syntheticCalories = Int(Double(realRecord.calories) * variation)
            
            // Crea il nuovo record
            let syntheticRecord = HealthData(
                date: Date(),
                steps: syntheticSteps,
                exerciseMinutes: syntheticExercise,
                calories: syntheticCalories
            )
            syntheticData.append(syntheticRecord)
        }
        
        return syntheticData
    }
    
    
    func fetchTodaySteps() async throws -> Int {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        return try await fetchTodayData(for: stepType, unit: .count())
    }
    
    func fetchTodayExerciseMinutes() async throws -> Int {
        let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        return try await fetchTodayData(for: exerciseTimeType, unit: .minute())
    }
    
    private func fetchTodayData(for type: HKQuantityType, unit: HKUnit) async throws -> Int {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                
                continuation.resume(returning: Int(sum.doubleValue(for: unit)))
            }
            
            healthStore.execute(query)
        }
    }
    
    private func combineData(steps: [Date: Int], exerciseMinutes: [Date: Int], calories: [Date: Int]) -> [HealthData] {
        var combinedData: [HealthData] = []
        
        let allDates = Set(steps.keys).union(calories.keys)
        
        for date in allDates {
            if let dailySteps = steps[date], let dailyMinutes = exerciseMinutes[date], let dailyCalories = calories[date] {
                combinedData.append(HealthData(date: date, steps: dailySteps, exerciseMinutes: dailyMinutes, calories: dailyCalories))
            }
        }
        
        return combinedData.sorted {
            return $0.date < $1.date
        }
    }
    
}
