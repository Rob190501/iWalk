//
//  GPT.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 10/01/25.
//

import OpenAI
import Foundation
import SwiftDotenv

class CalorieBot {
    static let shared = CalorieBot()
    private let openAI: OpenAI
    
    private init() {
        openAI = OpenAI(apiToken: CalorieBot.loadAPIToken())
    }
    
    private static func loadAPIToken() -> String {
        guard let filePath = Bundle.main.path(forResource: ".env", ofType: nil) else {
            return ""
        }
        
        do {
            try Dotenv.configure(atPath: filePath)
            return Dotenv["OPENAI_API_KEY"]?.stringValue ?? ""
        } catch {
            return ""
        }
    }
    
    func getKcal(of food: String) async throws -> Int {
        let query = ChatQuery(
            messages: [
                .init(role: .system, content: "Rispondi solo con il numero intero totale delle calorie degli alimenti forniti, senza aggiungere mai del testo di nessun tipo. Se non ci sono alimenti validi o sei incerto rispondi con 0")!,
                .init(role: .user, content: food)!
            ],
            model: .gpt3_5Turbo
        )
        
        let result = try await openAI.chats(query: query)
        
        guard let choice = result.choices.first, let message = choice.message.content?.string else {
            throw CustomError.noResponse
        }
        
        return Int(message) ?? 0
    }
    
}
