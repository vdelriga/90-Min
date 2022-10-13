//
//  Database.swift
//  90 Min
//
//  Created by Victor Manuel del Rio Garcia on 13/10/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

// 2
class FirestoreManager: ObservableObject {

    private let path: String = "Seasons"
    private let store = Firestore.firestore()
    @Published var currentMatchday: Int = 0
    
    
    init() {
        getSeason()
    }
    

    func addSeasonLaLiga(_ season: CurrentSeason) {
        do {
            // 6
            _ = try store.collection(path).document("LALIGA").setData(from: season)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func getSeason(){
        let docRef = store.collection(path).document("LALIGA")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    self.currentMatchday = data["currentMatchday"] as? Int ?? 0
                }
            }
        }
    }
    
    
    
    
}
