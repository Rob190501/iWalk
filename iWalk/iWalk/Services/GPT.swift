//
//  GPT.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 10/01/25.
//

import OpenAI
import Foundation
import SwiftDotenv

class GPT: ObservableObject {
    let openAI: OpenAI
    
    init() {
        openAI = OpenAI(apiToken: GPT.loadAPIToken())
    }
    
    private static func loadAPIToken() -> String {
        // Trova il file .env nel bundle
        guard let filePath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("File .env non trovato.")
            return ""
        }
        
        // Carica il file .env e restituisci il token
        do {
            try Dotenv.configure(atPath: filePath)
            return Dotenv["OPENAI_API_KEY"]?.stringValue ?? ""
        } catch {
            print("Errore nel caricamento del file .env: \(error.localizedDescription)")
            return ""
        }
    }
    
    func getKcal(of food: String) async throws -> Int {
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: "Rispondi solo con il numero intero totale delle calorie degli alimenti forniti, senza aggiungere mai del testo, di nessun tipo. Se non ci sono alimenti validi o sei incerto, rispondi con 0.")!,
                .init(role: .user, content: food)!
            ],
            model: .gpt3_5Turbo
        )
        
        let result = try await openAI.chats(query: query)
        
        if let choice = result.choices.first,
           let message = choice.message.content?.string {
            return Int(message) ?? 0
        } else {
            return -1
        }
    }
    
    
}
