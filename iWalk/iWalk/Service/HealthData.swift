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

class HealthData: ObservableObject {
    @Published var data: [(date: Date, steps: Int, calories: Int)]
    private var healthStore: HKHealthStore?
    
    init() {
        data = []
        healthStore = HKHealthStore()
    }
    
    func fetchHealthData(since years: Int) throws {
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
                    DispatchQueue.main.async {
                        self.data = self.combineStepsAndCalories(steps: steps, calories: calories)
                    }
                }
            }
        }
    }
    
    // Funzione per recuperare i dati giornalieri di un tipo specifico
    private func fetchDailyData(for type: HKQuantityType, unit: HKUnit, since years: Int) async throws -> [Date: Double] {
        guard let healthStore else {
            throw CustomError.healthStoreNotInitialized
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: years * -1, to: Date())!
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
                if let error {
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
    
    private func combineStepsAndCalories(steps: [Date: Double], calories: [Date: Double]) -> [(date: Date, steps: Int, calories: Int)] {
        var combinedData: [(date: Date, steps: Int, calories: Int)] = []
        
        let allDates = Set(steps.keys).union(calories.keys)
        
        for date in allDates {
            if let dailySteps = steps[date], let dailyCalories = calories[date] {
                if dailyCalories >= 1 {
                    combinedData.append((date: date, steps: Int(dailySteps), calories: Int(dailyCalories)))
                }
            }
        }
        
        return combinedData.sorted {
            return $0.date < $1.date
        }
    }
    
    func saveToCSV() throws {
        // Percorso del file nella directory Documents
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CustomError.documentsFolderNotFound
        }
            
        let fileURL = documentsURL.appendingPathComponent("HealthData.csv")
        
        // Creazione del contenuto CSV
        var csvText = "Steps,Calories\n" // Header CSV
        
        for record in data {
            let csvLine = "\(record.steps),\(record.calories)\n"
            csvText.append(csvLine)
        }
        
        // Scrittura del file
        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    func createModel() async throws {
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
    
    func saveCSVandCreateModel() throws {
        try saveToCSV()
        Task {
            try await createModel()
        }
    }
    

    func loadModel() throws -> MLModel {
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

    
    
    
    func makePrediction(model: MLModel, calories: Int) throws -> Int {
        // Prepara i dati di input come dizionario
        let input = try MLDictionaryFeatureProvider(dictionary: ["Calories": calories])
            
        // Esegui la previsione
        let prediction = try model.prediction(from: input)
            
        // Recupera il risultato dalla colonna target (Steps)
        let steps = prediction.featureValue(for: "Steps")!.doubleValue
            
        return Int(steps)
    }

    func predictSteps(forCalories calories: Int) throws -> Int {
        let model = try loadModel()
            
        let predictedSteps = try makePrediction(model: model, calories: calories)
                    
        return predictedSteps
    }

    


}
