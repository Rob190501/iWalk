//
//  CustomError.swift
//  iWalk
//
//  Created by Roberto Ambrosino on 29/01/25.
//

import Foundation

enum CustomError: LocalizedError {
    
    case healthStoreNotInitialized
    
    case emptyFetchError
    
    case documentsFolderNotFound
    
    case csvNotFound
    
    case HKAuthorizationFailed
    
    case custom(message: String)

    case modelNotInitialized
    
    
    var errorDescription: String {
        switch self {
            
        case .healthStoreNotInitialized:
            return "HealthStore non è inizializzato"
        
        case .emptyFetchError:
            return "Nessun dato trovato"
            
        case .documentsFolderNotFound:
            return "Impossibile trovare la directory Documents"
            
        case .csvNotFound:
            return "Impossibile trovare il file .csv"
            
        case .HKAuthorizationFailed:
            return "È necessario consentire l'accesso ai dati sanitari"
            
        case .modelNotInitialized:
            return "Modello non inizializzato"
        
        case .custom(let message):
            return message
        }
    }
}
