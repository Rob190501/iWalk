//
//  HealthData.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 06/01/25.
//

import Foundation
import HealthKit
#if canImport(CreateML)
import CreateML
#endif
import CoreML
import TabularData

class HealthService {
    private var healthStore: HKHealthStore? = HKHealthStore()
    
    
    
    func fetchHealthData(since years: Int, removeOutliers: Bool, tolerance: Double) async throws -> [HealthData] {
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
        let combinedData = combineData(steps: steps, exerciseMinutes: exerciseMinutes, calories: calories)
        
        return removeOutliers ? self.removeOutliers(from: combinedData/*, tolerance: tolerance*/) : combinedData
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
    
    
    
    /*private func removeOutliers(from data: [HealthData], tolerance: Double) -> [HealthData] {
        
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
    }*/
    
    private func removeOutliers(from data: [HealthData]) -> [HealthData] {
        // Filtra i record con calorie superiori a 30
        let filteredData = data.filter { $0.calories > 30 }

        // Calcola il rapporto calorie/passi per ogni record
        let kcalsPerStep = filteredData.map { Double($0.calories) / Double($0.steps) }

        // Calcola il primo e terzo quartile
        let sortedKcalsPerStep = kcalsPerStep.sorted()
        let q1 = percentile(sortedKcalsPerStep, percentile: 25)
        let q3 = percentile(sortedKcalsPerStep, percentile: 75)

        // Calcola l'IQR e i limiti per gli outlier
        let iqr = q3 - q1
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr

        // Filtra i dati per rimuovere gli outlier
        return filteredData.filter { record in
            let kcalsPerStep = Double(record.calories) / Double(record.steps)
            return kcalsPerStep >= lowerBound && kcalsPerStep <= upperBound
        }
    }

    private func percentile(_ data: [Double], percentile: Double) -> Double {
        let index = (percentile / 100.0) * Double(data.count - 1)
        let lower = data[Int(floor(index))]
        let upper = data[Int(ceil(index))]
        return lower + (upper - lower) * (index - floor(index))
    }
    
    
    /*private func removeOutliers(from data: [HealthData]) -> [HealthData] {
        // Filtra i record con calorie superiori a 30
        let filteredData = data.filter { $0.calories > 30 }

        // Calcola il rapporto calorie/passi e calorie/minuti di esercizio per ogni record
        let kcalsPerStep = filteredData.map { Double($0.calories) / Double($0.steps) }
        let kcalsPerExerciseMinute = filteredData.map { Double($0.calories) / Double($0.exerciseMinutes) }

        // Calcola i quartili per entrambi i rapporti
        let sortedKcalsPerStep = kcalsPerStep.sorted()
        let q1Step = percentile(sortedKcalsPerStep, percentile: 25)
        let q3Step = percentile(sortedKcalsPerStep, percentile: 75)

        let sortedKcalsPerExerciseMinute = kcalsPerExerciseMinute.sorted()
        let q1Exercise = percentile(sortedKcalsPerExerciseMinute, percentile: 25)
        let q3Exercise = percentile(sortedKcalsPerExerciseMinute, percentile: 75)

        // Calcola l'IQR e i limiti per gli outlier per entrambi i rapporti
        let iqrStep = q3Step - q1Step
        let lowerBoundStep = q1Step - 1.5 * iqrStep
        let upperBoundStep = q3Step + 1.5 * iqrStep

        let iqrExercise = q3Exercise - q1Exercise
        let lowerBoundExercise = q1Exercise - 1.5 * iqrExercise
        let upperBoundExercise = q3Exercise + 1.5 * iqrExercise

        // Filtra i dati per rimuovere gli outlier basati su entrambi i rapporti
        return filteredData.filter { record in
            let kcalsPerStep = Double(record.calories) / Double(record.steps)
            let kcalsPerExerciseMinute = Double(record.calories) / Double(record.exerciseMinutes)
            return (kcalsPerStep >= lowerBoundStep && kcalsPerStep <= upperBoundStep) &&
                   (kcalsPerExerciseMinute >= lowerBoundExercise && kcalsPerExerciseMinute <= upperBoundExercise)
        }
    }

    private func percentile(_ data: [Double], percentile: Double) -> Double {
        let index = (percentile / 100.0) * Double(data.count - 1)
        let lower = data[Int(floor(index))]
        let upper = data[Int(ceil(index))]
        return lower + (upper - lower) * (index - floor(index))
    }*/
    

    

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
    
    
    
    /*private func saveToCSV(data: [HealthData]) throws {
        // Percorso del file nella directory Documents
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CustomError.documentsFolderNotFound
        }
            
        let fileURL = documentsURL.appendingPathComponent("HealthData.csv")
        
        // Creazione del contenuto CSV
        var csvText = "Steps,ExerciseMinutes,Calories\n"
        
        for record in data {
            csvText.append("\(record.steps),\(record.exerciseMinutes),\(record.calories)\n")
        }
        
        // Scrittura del file
        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    
    
    private func createModel() async throws {
        #if canImport(CreateML)
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let csvURL = documentsDirectory.appendingPathComponent("HealthData.csv")
        let outputModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodel")
        let compiledModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodelc")
        
        // Verifica che il file esista
        guard fileManager.fileExists(atPath: csvURL.path) else {
            throw CustomError.csvNotFound
        }

        // Carica il file CSV in un DataFrame
        let dataFrame = try DataFrame(contentsOfCSVFile: csvURL)
        
        // Crea il modello di regressione
        let outputModel = try MLLinearRegressor(trainingData: dataFrame, targetColumn: "Steps")
        
        // Salva il modello nella cartella Documents
        try outputModel.write(to: outputModelURL)
        
        // Compila il modello
        let compiledModel = try await MLModel.compileModel(at: outputModelURL)
        
        // Salva il modello compilato nella cartella Documents, se ne esiste già uno lo elimina
        if fileManager.fileExists(atPath: compiledModelURL.path) {
            try fileManager.removeItem(at: compiledModelURL)
        }
        try fileManager.moveItem(at: compiledModel, to: compiledModelURL)
        #endif
    }
    
    
    
    func saveCSVandCreateModel(data: [HealthData]) async throws {
        try saveToCSV(data: data)
        try await createModel()
    }
    

    
    private func loadModel() throws -> MLModel {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let modelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodel")
        let compiledModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodelc")

        // Se il modello è già compilato, lo si carica direttamente
        if fileManager.fileExists(atPath: compiledModelURL.path) {
            return try MLModel(contentsOf: compiledModelURL)
        }

        // Altrimenti, lo si compila e lo si salva
        let compiledURL = try MLModel.compileModel(at: modelURL)
        // fare il fetch e poi il train

        try fileManager.moveItem(at: compiledURL, to: compiledModelURL)

        // Ora carico il modello compilato
        return try MLModel(contentsOf: compiledModelURL)
    }
    
    
    
    private func makePrediction(model: MLModel, exerciseMinutes: Int, calories: Int) throws -> Int {
        // Prepara i dati di input come dizionario
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "ExerciseMinutes": exerciseMinutes,
            "Calories": calories
        ])
        
        // Esegui la previsione
        let prediction = try model.prediction(from: input)
            
        // Recupera il risultato dalla colonna target (Steps)
        let steps = prediction.featureValue(for: "Steps")!.doubleValue
            
        return Int(steps)
    }
    
    

    func predictSteps(forCalories calories: Int) async throws -> Int {
        guard calories > 0 else {
            return 0
        }
        
        let model = try loadModel()
        
        let exerciseMinutes = try await fetchTodayExerciseMinutes()
            
        let predictedSteps = try makePrediction(model: model, exerciseMinutes: exerciseMinutes, calories: calories)
                    
        return predictedSteps
    }*/

}
