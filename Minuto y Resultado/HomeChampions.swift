//
//  ContentView.swift
//  Minuto y Resultado
//
//  Created by Victor Manuel Del Rio Garcia on 17/9/22.
//

import SwiftUI
import UIKit
import ActivityKit
import AlertToast
import Firebase

struct HomeChampions: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var matches = [Match]()
    @State private var matchesSeason = [Match]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    let maxMatchDay = 6
    var body: some View {
        VStack{
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            HStack{
                if (Int(jornada) ?? 0 > 1){
                    Button {
                        let newMatchday = (Int(jornada) ?? 1) - 1
                        jornada = String(newMatchday)
                        if jornada == String(currentMatchday){
                            Task{
                                //await loadData()
                                getMatchdayMatchesCL()
                            }
                        }else{
                            loadMatchDay(matchday: Int(jornada) ?? 0)
                        }
                    }label:{
                        Image(systemName:"chevron.backward")
                            .foregroundColor(.red)
                    }
                    .padding(.leading)
                }
                Spacer()
                if !jornada.isEmpty {
                    Text("Jornada:" + jornada)
                        .font(.headline)
                        .foregroundColor(.red)
                }
                Spacer()
                if (Int(jornada) ?? 0 < maxMatchDay){
                    Button{
                        let newMatchday = (Int(jornada) ?? 1) + 1
                        jornada = String(newMatchday)
                        if jornada == String(currentMatchday){
                            Task{
                                getMatchdayMatchesCL()
                            }
                        }else{
                            loadMatchDay(matchday: Int(jornada) ?? 0)
                        }
                    }label:{
                        Image(systemName:"chevron.right")
                            .foregroundColor(.red)
                    }
                    .padding(.trailing)
                }
                
            }
            ZStack{
                Image("CL")
                    .resizable()
                    .frame(width: 330, height: 330)
                    .blur(radius:3)
                if #available(iOS 15.0, *) {
                    List(matches, id: \.id) { item in
                        VStack(alignment: .leading) {
                            HStack{
                                VStack(alignment: .center,spacing:4){
                                    Image(String(item.homeTeam.id))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                    
                                    Text(item.homeTeam.shortName)
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                }.frame(width: 113.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                                Spacer()
                                VStack{
                                    Text(getMatchDate(stringDate: item.utcDate))
                                        .font(.caption)
                                    Text(getMatchTime(stringDate: item.utcDate))
                                        .font(.caption)
                                    Text(getScore(halfTime:item.score.halfTime, fullTime:item.score.fullTime))
                                        .font(.largeTitle)
                                    Text(getStatus(halfTime:item.score.halfTime,fullTime:item.score.fullTime,status:item.status,match:item))
                                        .font(.caption)
                                    
                                }
                                Spacer()
                                VStack{
                                    Image(String(item.awayTeam.id))
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                    
                                    Text(item.awayTeam.shortName)
                                        .font(.headline)
                                        .lineLimit(2)
                                }.frame(width: 113.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                            }
                        }.onTapGesture{
                            result = startActivity(match: item)
                            showToast.toggle()
                        }
                    }.toast(isPresenting:$showToast){
                        AlertToast(type: result ?.complete(.green):.error(.red),title:result ? "Partido añadido a tu pantalla de inicio.":"El partido ya ha finalizado o ya se ha programado.")
                    }
                    .padding(.bottom)
                    .refreshable{
                        getMatchdayMatchesCL()
                    }.onReceive(self.observer.$enteredForeground) { _ in
                        Task {
                            getCurrentMatchdayDatabase()
                            getSeasonCLMatches()
                        }
                    }
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                } else {
                    // Fallback on earlier versions
                }
                SwiftUIBannerAd(adPosition: .bottom, adUnitId:Constants.BannerId)
                
            }.onReceive(firestoreManager.$currentCLMatchday) { matchday in
                if(matchday != 0){
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.matchdayCLTimestamp.addingTimeInterval(21600)
                    if now  < expiredTime {
                        jornada = String(matchday)
                        currentMatchday = matchday
                        getMatchdayMatchesCL()
                    }else{
                        Task{
                            await getCurrentMatchday()
                        }
                    }
                }
            }.onReceive(firestoreManager.$seasonCLMatches) { matches in
                let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.seasonCLMatchesTimestamp.addingTimeInterval(21600)
                    if now  < expiredTime {
                        matchesSeason = matches.matches
                    }else{
                        Task{
                            await loadDataSeason()
                        }
                    }
            }.onReceive(firestoreManager.$matchdayMatchesCL) { matchdayMatches in
                if matchdayMatches.matches.count > 0 {
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.matchdayMatchesCLTimestamp.addingTimeInterval(10)
                    if now  < expiredTime {
                        print("Información de partidos cacheada")
                        matches = matchdayMatches.matches
                    }else{
                        Task{
                            await loadData()
                        }
                    }
                }
            }
            
        }

    }
    func getMatchdayMatchesCL(){
        firestoreManager.getMatchdayMatchesCL()
    }
    
    func getCurrentMatchdayDatabase(){
        firestoreManager.getSeasonCL()

    }
    
    func getSeasonCLMatches(){
        firestoreManager.getSeasonCLMatches()
    }
    
    
    func getMatchTime(stringDate: String)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "es_ES")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from:stringDate)
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter.string(from: date!)
    }
    func getMatchDate(stringDate: String)->String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "es_ES")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from:stringDate)
        dateFormatter.dateFormat = "dd-MM-yyyy"
        return dateFormatter.string(from: date!)
    }
    
    func getScore(halfTime: childScore, fullTime: childScore)->String{
        if let awayScore = fullTime.away, let homeScore = fullTime.home {
            return String(homeScore) + ":" + String(awayScore)
        }else
        {
            if let awayScore = halfTime.away, let homeScore = halfTime.home{
                return String(homeScore) + ":" + String(awayScore)
            }else
            {
                return "- : -"
            }
        }
    }
    
    
    func loadData() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/CL/matches?matchday=" + jornada + "&stage=GROUP_STAGE")
        else {
            print("Invalid URL")
            return
            }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)

            if let decodedResponse =
                try? JSONDecoder().decode(Matches.self, from: data){
                matches = decodedResponse.matches
                firestoreManager.addMatchdayMatchesCL(decodedResponse)
                firestoreManager.updateMatchdayMatchesCL()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    func loadDataSeason() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/CL/matches?stage=GROUP_STAGE")
        else {
            print("Invalid URL")
            return
            }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)

            if let decodedResponse =
                try? JSONDecoder().decode(Matches.self, from: data){
                matchesSeason = decodedResponse.matches
                firestoreManager.addSeasonCLMatches(decodedResponse)
                firestoreManager.updateSeasonCLMatches()
               
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    func loadMatchDay(matchday: Int){
        self.matches.removeAll()
        for match in matchesSeason{
            if match.matchday == matchday{
                matches.append(match)
            }
        }
    }
    
    func getCurrentMatchday() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/CL")
        else {
            print("Invalid URL")
            return
            }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)

            if let decodedResponse =
                try? JSONDecoder().decode(Season.self, from: data){
                currentMatchday = decodedResponse.currentSeason.currentMatchday
                jornada = String(decodedResponse.currentSeason.currentMatchday)
                firestoreManager.addSeasonCL(decodedResponse.currentSeason)
                firestoreManager.updateSeasonCL()
                Task {
                    await loadData()
                }
                
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    
    @available(iOS 16.1, *)
    func existActivity(id: Int) -> Bool{
        for activity in Activity<MatchAttributes>.activities {
            if activity.attributes.id == id && activity.activityState == .active{
                return true
            }
                
        }
        return false
    }
    
    
    func startActivity(match: Match)->Bool{
        if #available(iOS 16.1, *) {
            if !existActivity(id:match.id) && (match.status == "IN_PLAY" || match.status=="PAUSED"||match.status == "TIMED"){
                let initialContentState = MatchAttributes.ContentState(status: match.status, scoreHomeFullTime: match.score.fullTime.home, scoreAwayFullTime: match.score.fullTime.away)
                let activityAttributes = MatchAttributes(id: match.id, utcDate: match.utcDate, matchday: match.matchday, idHome: match.homeTeam.id, nameHome: match.homeTeam.name, shortNameHome: match.homeTeam.shortName, tlaHome: match.homeTeam.tla, crestHome: match.homeTeam.crest, idAway: match.awayTeam.id, nameAway: match.awayTeam.name, shortNameAway: match.awayTeam.shortName, tlaAway: match.awayTeam.tla, crestAway: match.awayTeam.crest)
                Task{
                    do{
                        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                              print("Activities are not enabled!")
                              return
                            }

                        let _ =  try Activity.request(attributes:activityAttributes,contentState: initialContentState)
                         Messaging.messaging().subscribe(toTopic: String(match.id)) { error in
                             print("Subscribed to Match: \(match.id)")
                         }
                    }
                }
                return true
            }else{
                return false
            }
        }
        return false
        
    }
    
    
    func getStatus(halfTime: childScore, fullTime: childScore,status:String,match:Match)->String{
        switch status {
        case "IN_PLAY":
            if halfTime.home == nil{
                    return "1ª PARTE"
                }else
                {
                    return "2ª PARTE"
                }
            
        case "PAUSED" :
            return "DESCANSO"
        case "FINISHED":  return "FINALIZADO"
        default: return ""
            
        }
    }
    
}


struct HomeChampions_Previews: PreviewProvider {
    static var previews: some View {
            HomeChampions()
       
    }
}
