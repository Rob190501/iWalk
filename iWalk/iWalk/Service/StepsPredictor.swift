//
//  StepsPredictor.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 13/03/25.
//

import Foundation
import CoreML
import TabularData
#if canImport(CreateML)
import CreateML
#endif


class StepsPredictor {
    
    static let shared = StepsPredictor()
    private var model: MLModel?
    
    private init() {
        model = loadModel()
    }
    
    
    
    private func getDocumentsDirectory() throws -> URL {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CustomError.documentsDirectoryNotFound
        }
        
        return documentsDirectory
    }
    
    private func loadModel() -> MLModel? {
        do {
            let documentsDirectory = try getDocumentsDirectory()
            let compiledModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodelc")
            
            return try MLModel(contentsOf: compiledModelURL)
        } catch {
            return nil
        }
    }
    
    
    
    func saveCSVandCreateModel(data: [HealthData]) async throws {
        try saveToCSV(data: data)
        try await createModel()
        
        model = loadModel()
        
        let storage = HealthDataStorage()
        storage.healthData = data
    }
    
    private func saveToCSV(data: [HealthData]) throws {
        // Percorso del file nella directory Documents
        let documentsDirectory = try getDocumentsDirectory()
        
        let fileURL = documentsDirectory.appendingPathComponent("HealthData.csv")
        
        // Creazione del contenuto CSV
        var csvText = "Steps,ExerciseMinutes,Calories\n"
        
        for record in data {
            csvText.append("\(record.steps),\(record.exerciseMinutes),\(record.calories)\n")
        }
        
        // Scrittura del file
        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
    }
        
    #if canImport(CreateML)
    private func createTempModel(data: [HealthData]) async throws -> MLLinearRegressor {
        
        let tempModel = try MLLinearRegressor(trainingData: data.toDataFrame(), targetColumn: "Steps")
        return tempModel
        
    }
    #endif
    
    func modelImputation(from realData: [HealthData], count: Int) async throws -> [HealthData] {
        #if canImport(CreateML)
        guard !realData.isEmpty else {
            return []
        }
        
        var syntheticData: [HealthData] = []
        
        let regressor = try await createTempModel(data: realData)
        
        for _ in 0..<count {
            // Record casuale
            let randomIndex = Int.random(in: 0..<realData.count)
            let realRecord = realData[randomIndex]
            
            // Calcola variazione casuale (entro +-15%)
            let variation = Double.random(in: 0.85...1.15)
            
            // Applica le variazioni
            let syntheticExercise = Int(Double(realRecord.exerciseMinutes) * variation)
            let syntheticCalories = Int(Double(realRecord.calories) * variation)
            
            let syntheticRecord = HealthData(
                date: Date(),
                steps: try makePrediction(exerciseMinutes: syntheticExercise, calories: syntheticCalories, model: regressor.model),
                exerciseMinutes: syntheticExercise,
                calories: syntheticCalories
            )
            syntheticData.append(syntheticRecord)
        }
        
        return syntheticData
        #endif
        return []
    }
    
    
    private func createModel() async throws {
        #if canImport(CreateML)
        let fileManager = FileManager.default
        let documentsDirectory = try getDocumentsDirectory()
        let csvURL = documentsDirectory.appendingPathComponent("HealthData.csv")
        
        // Verifica che il file esista
        guard fileManager.fileExists(atPath: csvURL.path) else {
            throw CustomError.csvNotFound
        }
        
        let outputModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodel")
        let compiledModelURL = documentsDirectory.appendingPathComponent("StepsPredictor.mlmodelc")
        
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
    
    func kFoldValidation(data: [HealthData], k: Int) async throws -> Int {
        #if canImport(CreateML)
        guard !data.isEmpty else {
            return 0
        }
        
        let totalRows = data.count
        let foldSize = totalRows / k
        var errors: [Int] = []
        
        let shuffledData = data.shuffled()
        
        for i in 0..<k {
            // Calcolare gli indici per il testSet del fold corrente
            let start = i * foldSize
            let end = min(start + foldSize, totalRows)
            
            // Creare il test set per il fold corrente
            let testSet = Array(shuffledData[start..<end])
            
            // Creare il training set rimuovendo le righe del test set
            var trainingData: [HealthData] = []
            trainingData.append(contentsOf: shuffledData[0..<start])
            trainingData.append(contentsOf: shuffledData[end..<totalRows])
                                     
            
            /*var trainingSet = DataFrame()
            // Aggiungi le colonne una per una, convertendo gli array in formati accettati
            trainingSet.append(column: Column(name: "Steps", contents: trainingData.map { Double($0.steps) }))
            trainingSet.append(column: Column(name: "ExerciseMinutes", contents: trainingData.map { Double($0.exerciseMinutes) }))
            trainingSet.append(column: Column(name: "Calories", contents: trainingData.map { Double($0.calories) }))
             
            // Addestrare il modello
            let regressor = try MLLinearRegressor(trainingData: trainingSet, targetColumn: "Steps")*/
            
            let regressor = try await createTempModel(data: trainingData)
            
            // Calcolo errore medio assoluto (MAE) sul fold
            errors.append(try MAE(data: testSet, model: regressor.model))
        }
        
        // Calcolare l'errore medio su tutti i fold
        return Int(errors.reduce(0, +) / errors.count)
        #endif
        
        #if DEBUG
        return 0
        #endif
    }
    
    func MAE(data: [HealthData], model: MLModel? = nil) throws -> Int{
        var sum = 0
        
        for record in data {
            let predictedSteps = try makePrediction(exerciseMinutes: record.exerciseMinutes, calories: record.calories, model: model)
            let absoluteError = abs(predictedSteps - record.steps)
            sum += absoluteError
        }
        
        return Int(sum / data.count)
    }
    
    
    
    func predictSteps(forCalories calories: Int) async throws -> Int {
        guard calories > 0 else {
            return 0
        }
        
        let exerciseMinutes = try await HealthService.shared.fetchTodayExerciseMinutes()
        
        let predictedSteps = try makePrediction(exerciseMinutes: exerciseMinutes, calories: calories)
        
        return predictedSteps
    }
    
    func predictSteps(forCalories calories: Int, forMinutes excerciseMinutes: Int) throws -> Int {
        print("kcal : \(calories) exc: \(excerciseMinutes)")
        
        guard calories > 0 && excerciseMinutes >= 0 else {
            return 0
        }
        
        let predictedSteps = try makePrediction(exerciseMinutes: excerciseMinutes, calories: calories)
        
        return predictedSteps
    }
    
    private func makePrediction(exerciseMinutes: Int, calories: Int, model: MLModel? = nil) throws -> Int {
        let modelToUse = model ?? self.model
        
        guard let modelToUse else {
            throw CustomError.modelNotInitialized
        }
        
        // Prepara i dati di input come dizionario
        let input = try MLDictionaryFeatureProvider(dictionary: [
            "ExerciseMinutes": exerciseMinutes,
            "Calories": calories
        ])
        
        // Esegui la previsione
        let prediction = try modelToUse.prediction(from: input)
        
        // Recupera il risultato dalla colonna target (Steps)
        let steps = prediction.featureValue(for: "Steps")!.doubleValue
        
        return Int(steps)
    }
    
}
