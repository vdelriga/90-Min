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
    @Published var matchdayTimestamp: Date = Date.now
    @Published var seasonMatchesTimestamp: Date = Date.now
    @Published var seasonMatches:Matches = Matches(matches:[])
    
    
    
    //------------------------- funciones para obtener el día de jornada de la liga ---------------------------------------------------
    
    
    func addSeasonLaLiga(_ season: CurrentSeason) {
        do {
            // 6
            _ = try store.collection(path).document("LALIGA").setData(from: season)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonLaLiga(_ season: CurrentSeason){
        store.collection(path).document("LALIGA").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
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
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.matchdayTimestamp = timestamp.dateValue()
                    self.currentMatchday = data["currentMatchday"] as? Int ?? 0
                    print("La fecha de actualización es\(self.matchdayTimestamp)")
                }
            }
        }
    }
    
    //------------------------- funciones para obtener todos los partidos de la liga ---------------------------------------------------
    func addSeasonMatches(_ matchesSeason: Matches) {
        do {
            // 6
            _ = try store.collection(path).document("LALIGAPARTIDOS").setData(from: matchesSeason)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonMatches(_ matchesSeason: Matches){
        store.collection(path).document("LALIGAPARTIDOS").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getSeasonMatches(){
        let docRef = store.collection(path).document("LALIGAPARTIDOS")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                do{
                    self.seasonMatches = try document.data(as: Matches.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    
    
    
    
    
    
}
