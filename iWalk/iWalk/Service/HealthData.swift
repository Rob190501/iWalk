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

class HealthData {
    private var healthStore: HKHealthStore? = HKHealthStore()
    
    
    
    /*func fetchHealthData(since years: Int, removeOutliers: Bool) throws -> [(date: Date, steps: Int, calories: Int)] {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }
        
        // Definizione dei tipi di dati da leggere
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let readTypes: Set = [stepsType, caloriesType]
        
        // 1. Richiedi autorizzazione
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if success {
                Task {
                    // 2. Recupera i dati
                    let steps = try await self.fetchDailyData(for: stepsType, unit: .count(), since: years)
                    let calories = try await self.fetchDailyData(for: caloriesType, unit: .kilocalorie(), since: years)
                    
                    // 3. Combina ed assegna i dati recuperati
                    //DispatchQueue.main.async {
                        if(removeOutliers) {
                            return self.removeOutliers(from: self.combineStepsAndCalories(steps: steps, calories: calories))
                        }
                        else {
                            return self.combineStepsAndCalories(steps: steps, calories: calories)
                        }
                    //}
                }
            }
        }
    }*/
    
    func fetchHealthData(since years: Int, removeOutliers: Bool, tolerance: Double) async throws -> [(date: Date, steps: Int, calories: Int)] {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }

        // Definizione dei tipi di dati da leggere
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let readTypes: Set = [stepsType, caloriesType]

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
        let calories = try await fetchDailyData(for: caloriesType, unit: .kilocalorie(), since: years)

        // 3. Combina i dati ed eventualmente rimuove gli outlier
        let combinedData = combineStepsAndCalories(steps: steps, calories: calories)
        
        return removeOutliers ? self.removeOutliers(from: combinedData, tolerance: tolerance) : combinedData
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
    
    
    
    private func removeOutliers(from data: [(date: Date, steps: Int, calories: Int)], tolerance: Double) -> [(date: Date, steps: Int, calories: Int)] {
        
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

    

    func fetchTodaySteps() async throws -> Int {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: nil)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            healthStore.execute(query)
        }
    }


    
    private func combineStepsAndCalories(steps: [Date: Int], calories: [Date: Int]) -> [(date: Date, steps: Int, calories: Int)] {
        var combinedData: [(date: Date, steps: Int, calories: Int)] = []
        
        let allDates = Set(steps.keys).union(calories.keys)
        
        for date in allDates {
            if let dailySteps = steps[date], let dailyCalories = calories[date] {
                combinedData.append((date: date, steps: dailySteps, calories: dailyCalories))
            }
        }
        
        return combinedData.sorted {
            return $0.date < $1.date
        }
    }
    
    
    
    private func saveToCSV(data: [(date: Date, steps: Int, calories: Int)]) throws {
        // Percorso del file nella directory Documents
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CustomError.documentsFolderNotFound
        }
            
        let fileURL = documentsURL.appendingPathComponent("HealthData.csv")
        
        // Creazione del contenuto CSV
        var csvText = "Steps,Calories\n"
        
        for record in data {
            csvText.append("\(record.steps),\(record.calories)\n")
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
    
    
    
    func saveCSVandCreateModel(data: [(date: Date, steps: Int, calories: Int)]) async throws {
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
    
    
    
    private func makePrediction(model: MLModel, calories: Int) throws -> Int {
        // Prepara i dati di input come dizionario
        let input = try MLDictionaryFeatureProvider(dictionary: ["Calories": calories])
            
        // Esegui la previsione
        let prediction = try model.prediction(from: input)
            
        // Recupera il risultato dalla colonna target (Steps)
        let steps = prediction.featureValue(for: "Steps")!.doubleValue
            
        return Int(steps)
    }
    
    

    func predictSteps(forCalories calories: Int) throws -> Int {
        guard calories > 0 else {
            return 0
        }
        
        let model = try loadModel()
            
        let predictedSteps = try makePrediction(model: model, calories: calories)
                    
        return predictedSteps
    }

}
