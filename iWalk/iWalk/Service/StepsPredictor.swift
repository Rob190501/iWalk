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
            throw CustomError.documentsFolderNotFound
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
    
    
    
    private func makePrediction(exerciseMinutes: Int, calories: Int) throws -> Int {
        guard let model else {
            throw CustomError.modelNotInitialized
        }
        
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
        
        let hs = HealthService()
        
        let exerciseMinutes = try await hs.fetchTodayExerciseMinutes()
        
        let predictedSteps = try makePrediction(exerciseMinutes: exerciseMinutes, calories: calories)
        
        return predictedSteps
    }
    
}
