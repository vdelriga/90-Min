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
    @Published var currentCLMatchday: Int = 0
    @Published var currentWCMatchday: Int = 0
    @Published var matchdayTimestamp: Date = Date.now
    @Published var matchdayCLTimestamp: Date = Date.now
    @Published var matchdayWCTimestamp: Date = Date.now
    @Published var seasonMatchesTimestamp: Date = Date.now
    @Published var seasonMatches:Matches = Matches(matches:[])
    @Published var matchdayMatchesTimestamp: Date = Date.now
    @Published var matchdayMatches:Matches = Matches(matches:[])
    @Published var standingsTimestamp: Date = Date.now
    @Published var standings:Standing = Standing(standings: [])
    @Published var standingsCLTimestamp: Date = Date.now
    @Published var standingsCL:StandingCL = StandingCL(standings: [])
    @Published var seasonCLMatchesTimestamp: Date = Date.now
    @Published var seasonCLMatches:Matches = Matches(matches:[])
    @Published var matchdayMatchesCLTimestamp: Date = Date.now
    @Published var matchdayMatchesCL:Matches = Matches(matches:[])
    @Published var seasonWCMatchesTimestamp: Date = Date.now
    @Published var seasonWCMatches:MatchesWC = MatchesWC(matches:[])
    @Published var matchdayMatchesWCTimestamp: Date = Date.now
    @Published var matchdayMatchesWC:MatchesWC = MatchesWC(matches:[])
    @Published var standingsWC:StandingCL = StandingCL(standings: [])
    @Published var standingsWCTimestamp: Date = Date.now
    
    
    //función que almacena los tokens de las Live activities
    func addMatchToken(matchId: Int, token:Token) {
        do {
            // 6
            _ = try store.collection(String(matchId)).document(token.token).setData(from: token)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    
    
    //------------------------- funciones para obtener el día de jornada de la liga ---------------------------------------------------
    
    
    func addSeasonLaLiga(_ season: CurrentSeason) {
        do {
            _ = try store.collection(path).document("LALIGA").setData(from: season)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonLaLiga(){
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
    
    func updateSeasonMatches(){
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
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.seasonMatchesTimestamp = timestamp.dateValue()
                }
                do{
                    self.seasonMatches = try document.data(as: Matches.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener todos los partidos de la jornada ---------------------------------------------------
    func addMatchdayMatches(_ matchdayMatches: Matches) {
        do {
            // 6
            _ = try store.collection(path).document("PARTIDOSJORNADA").setData(from: matchdayMatches)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateMatchdayMatches(){
        store.collection(path).document("PARTIDOSJORNADA").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getMatchdayMatches(){
        let docRef = store.collection(path).document("PARTIDOSJORNADA")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    if let timestamp = data["lastUpdated"] as? Timestamp{
                        self.matchdayMatchesTimestamp = timestamp.dateValue()
                    }else{
                        let now = Date()
                        self.matchdayMatchesTimestamp = Calendar.current.date(byAdding: .second, value: -11, to: now)!
                    }
                }
                do{
                    self.matchdayMatches = try document.data(as: Matches.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener clasificación de la Liga ---------------------------------------------------
    func addStandings(_ standings: Standing) {
        do {
            // 6
            _ = try store.collection(path).document("CLASIFICACIONLIGA").setData(from: standings)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateStandings(){
        store.collection(path).document("CLASIFICACIONLIGA").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getStandings(){
        let docRef = store.collection(path).document("CLASIFICACIONLIGA")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.standingsTimestamp = timestamp.dateValue()
                }
                do{
                    self.standings = try document.data(as: Standing.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener clasificación de la Champions ---------------------------------------------------
    func addStandingsCL(_ standings: StandingCL) {
        do {
            // 6
            _ = try store.collection(path).document("CLASIFICACIONCL").setData(from: standings)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateStandingsCL(){
        store.collection(path).document("CLASIFICACIONCL").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getStandingsCL(){
        let docRef = store.collection(path).document("CLASIFICACIONCL")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.standingsCLTimestamp = timestamp.dateValue()
                }
                do{
                    self.standingsCL = try document.data(as: StandingCL.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener el día de jornada de Champions ---------------------------------------------------
    
    
    func addSeasonCL(_ season: CurrentSeason) {
        do {
            // 6
            _ = try store.collection(path).document("CL").setData(from: season)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonCL(){
        store.collection(path).document("CL").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func getSeasonCL(){
        let docRef = store.collection(path).document("CL")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.matchdayCLTimestamp = timestamp.dateValue()
                    self.currentCLMatchday = data["currentMatchday"] as? Int ?? 0
                    print("La fecha de actualización es\(self.matchdayTimestamp)")
                }
            }
        }
    }
    
    //------------------------- funciones para obtener todos los partidos de la champions ---------------------------------------------------
    func addSeasonCLMatches(_ matchesSeason: Matches) {
        do {
            // 6
            _ = try store.collection(path).document("CLPARTIDOS").setData(from: matchesSeason)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonCLMatches(){
        store.collection(path).document("CLPARTIDOS").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getSeasonCLMatches(){
        let docRef = store.collection(path).document("CLPARTIDOS")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.seasonCLMatchesTimestamp = timestamp.dateValue()
                }
                do{
                    self.seasonCLMatches = try document.data(as: Matches.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    //------------------------- funciones para obtener todos los partidos de la jornadaCL ---------------------------------------------------
    func addMatchdayMatchesCL(_ matchdayMatches: Matches) {
        do {
            // 6
            _ = try store.collection(path).document("PARTIDOSJORNADACL").setData(from: matchdayMatches)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateMatchdayMatchesCL(){
        store.collection(path).document("PARTIDOSJORNADACL").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getMatchdayMatchesCL(){
        let docRef = store.collection(path).document("PARTIDOSJORNADACL")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.matchdayMatchesCLTimestamp = timestamp.dateValue()
                }
                do{
                    self.matchdayMatchesCL = try document.data(as: Matches.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener el día de jornada del Mundial ---------------------------------------------------
    
    
    func addSeasonWC(_ season: CurrentSeason) {
        do {
            // 6
            _ = try store.collection(path).document("WC").setData(from: season)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonWC(){
        store.collection(path).document("WC").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func getSeasonWC(){
        let docRef = store.collection(path).document("WC")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    if let timestamp = data["lastUpdated"] as? Timestamp{
                        self.matchdayWCTimestamp = timestamp.dateValue()
                    }else{
                        let now = Date()
                        self.matchdayWCTimestamp = Calendar.current.date(byAdding: .second, value: -21601, to: now)!
                    }
                    self.currentWCMatchday = data["currentMatchday"] as? Int ?? 0
                    print("La fecha de actualización es\(self.matchdayTimestamp)")
                }
            }
        }
    }
    
    //------------------------- funciones para obtener todos los partidos del Mundial ---------------------------------------------------
    func addSeasonMatchesWC(_ matchesSeason: MatchesWC) {
        do {
            // 6
            _ = try store.collection(path).document("WCPARTIDOS").setData(from: matchesSeason)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateSeasonMatchesWC(){
        store.collection(path).document("WCPARTIDOS").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getSeasonMatchesWC(){
        let docRef = store.collection(path).document("WCPARTIDOS")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    if let timestamp = data["lastUpdated"] as? Timestamp{
                        self.seasonWCMatchesTimestamp = timestamp.dateValue()
                    }else{
                        let now = Date()
                        self.seasonWCMatchesTimestamp = Calendar.current.date(byAdding: .second, value: -21601, to: now)!
                    }
                }
                do{
                    self.seasonWCMatches = try document.data(as: MatchesWC.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    //------------------------- funciones para obtener todos los partidos de la jornada del mundial ---------------------------------------------------
    func addMatchdayMatchesWC(_ matchdayMatches: MatchesWC) {
        do {
            // 6
            _ = try store.collection(path).document("WCPARTIDOSJORNADA").setData(from: matchdayMatches)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateMatchdayMatchesWC(){
        store.collection(path).document("WCPARTIDOSJORNADA").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getMatchdayMatchesWC(){
        let docRef = store.collection(path).document("WCPARTIDOSJORNADA")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    if let timestamp = data["lastUpdated"] as? Timestamp{
                        self.matchdayMatchesWCTimestamp = timestamp.dateValue()
                    }else{
                        let now = Date()
                        self.matchdayMatchesWCTimestamp = Calendar.current.date(byAdding: .second, value: -11, to: now)!
                    }
                }
                do{
                    self.matchdayMatchesWC = try document.data(as: MatchesWC.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    
    //------------------------- funciones para obtener clasificación del Mundial ---------------------------------------------------
    
    
    func addStandingsWC(_ standings: StandingCL) {
        do {
            // 6
            _ = try store.collection(path).document("CLASIFICACIONWC").setData(from: standings)
        } catch {
            fatalError("Unable to add card: \(error.localizedDescription).")
        }
    }
    
    func updateStandingsWC(){
        store.collection(path).document("CLASIFICACIONWC").updateData([
            "lastUpdated": FieldValue.serverTimestamp(),
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getStandingsWC(){
        let docRef = store.collection(path).document("CLASIFICACIONWC")
        docRef.getDocument { document, error in
            guard error == nil else {
                print("error", error ?? "")
                return
            }
            if let document = document, document.exists {
                let data = document.data()
                if let data = data{
                    let timestamp = data["lastUpdated"] as! Timestamp
                    self.standingsWCTimestamp = timestamp.dateValue()
                }
                do{
                    self.standingsWC = try document.data(as: StandingCL.self)
                }catch{
                    print("Se ha producido un error cargando los partidos de BBDD")
                }
                
            }
        }
    }
    
    
    
    
}
