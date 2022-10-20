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

extension Date {
    func localDate() -> Date {
        let nowUTC = Date()
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: nowUTC))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: nowUTC) else {return Date()}

        return localDate
    }
}

struct Home: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var matches = [Match]()
    @State private var matchesSeason = [Match]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    let maxMatchDay = 38
    var body: some View {
        ZStack{
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
                                    getMatchdayMatches()
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
                                getMatchdayMatches()
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
                    
                    Image("PD")
                        .resizable()
                        .frame(width: 350, height: 350)
                        .blur(radius:8)
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
                            getMatchdayMatches()
                        }.onReceive(self.observer.$enteredForeground) { _ in
                            Task {
                                getCurrentMatchdayDatabase()
                                getSeasonMatches()
                            }
                        }
                        .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    } else {
                        // Fallback on earlier versions
                    }
                    
                    
                }
            }
            SwiftUIBannerAd(adPosition: .bottom, adUnitId: "ca-app-pub-3940256099942544/2934735716")

        }.onReceive(firestoreManager.$currentMatchday) { matchday in
            if(matchday != 0){
                let now = Date.now
                //se añade la fecha de expiración en segundos(6h)
                let expiredTime = firestoreManager.matchdayTimestamp.addingTimeInterval(21600)
                if now  < expiredTime {
                    jornada = String(matchday)
                    currentMatchday = matchday
                    getMatchdayMatches()
                }else{
                    Task{
                        await getCurrentMatchday()
                    }
                }
            }
        }
        .onReceive(firestoreManager.$seasonMatches) { matches in
            let now = Date.now
                //se añade la fecha de expiración en segundos(6h)
                let expiredTime = firestoreManager.seasonMatchesTimestamp.addingTimeInterval(21600)
                if now  < expiredTime {
                    matchesSeason = matches.matches
                }else{
                    Task{
                        await loadDataSeason()
                    }
                }
        }
        .onReceive(firestoreManager.$matchdayMatches) { matchdayMatches in
            if matchdayMatches.matches.count > 0 {
                let now = Date.now
                //se añade la fecha de expiración en segundos(6h)
                let expiredTime = firestoreManager.matchdayMatchesTimestamp.addingTimeInterval(10)
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
    func placeOrder() { }
    func adjustOrder() { }
    
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
    
    
    func loadMatchDay(matchday: Int){
        self.matches.removeAll()
        for match in matchesSeason{
            if match.matchday == matchday{
                matches.append(match)
            }
        }
    }
    
    func loadDataSeason() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/PD/matches")
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
                firestoreManager.addSeasonMatches(decodedResponse)
                firestoreManager.updateSeasonMatches()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    func loadData() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/PD/matches?matchday=" + jornada)
        else {
            print("Invalid URL")
            return
            }
        var request = URLRequest(url: url)
        print(url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)

            if let decodedResponse =
                try? JSONDecoder().decode(Matches.self, from: data){
                matches = decodedResponse.matches
                firestoreManager.addMatchdayMatches(decodedResponse)
                firestoreManager.updateMatchdayMatches()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    func getCurrentMatchdayDatabase(){
        firestoreManager.getSeason()

    }
    
    func getSeasonMatches(){
        firestoreManager.getSeasonMatches()

    }
    
    func getMatchdayMatches(){
        firestoreManager.getMatchdayMatches()
    }
    
    func getCurrentMatchday() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/PD")
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
                jornada = String(decodedResponse.currentSeason.currentMatchday)
                currentMatchday = decodedResponse.currentSeason.currentMatchday
                firestoreManager.addSeasonLaLiga(decodedResponse.currentSeason)
                firestoreManager.updateSeasonLaLiga()
                Task {
                    getMatchdayMatches()
                }
                
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    @available(iOS 16.1, *)
    func existActivity(id: Int) -> Bool{
        for activity in ActivityManager.matchActivities {
            if activity.id == id && activity.matchActivity.activityState == .active{
                return true
            }
                
        }
        return false
    }
    
    func killActivitiesFake(){
        if #available(iOS 16.1, *) {
            let finalMatchStatus = MatchAttributes.ContentState(status: "FINISHED", scoreHomeFullTime: 0, scoreAwayFullTime: 0)
            Task {
                for activity in ActivityManager.matchActivities {
                    await activity.matchActivity.end(using:finalMatchStatus, dismissalPolicy: .default)
                }
                print("Se paran todas las actividades")
            }
        }
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

                            let activity = MatchActivity(matchAct: try Activity.request(attributes:activityAttributes,contentState: initialContentState), idActivity: match.id)
                            ActivityManager.matchActivities.append(activity)
                    }
                }
                return true
            }else{
                return false
            }
        }
        return false
        
    }
    
    func startActivityFake(){
        if #available(iOS 16.1, *) {
            if !existActivity(id:matches[activityCounter].id){
                let initialContentState = MatchAttributes.ContentState(status: "IN_PLAY", scoreHomeFullTime: 0, scoreAwayFullTime: 0)
                let activityAttributes = MatchAttributes(id: matches[activityCounter].id, utcDate: matches[activityCounter].utcDate, matchday: matches[activityCounter].matchday, idHome: matches[activityCounter].homeTeam.id, nameHome: matches[activityCounter].homeTeam.name, shortNameHome: matches[activityCounter].homeTeam.shortName, tlaHome: matches[activityCounter].homeTeam.tla, crestHome: matches[activityCounter].homeTeam.crest, idAway: matches[activityCounter].awayTeam.id, nameAway: matches[activityCounter].awayTeam.name, shortNameAway: matches[activityCounter].awayTeam.shortName, tlaAway: matches[activityCounter].awayTeam.tla, crestAway: matches[activityCounter].awayTeam.crest)
                Task{
                    do{
                        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                              print("Activities are not enabled!")
                              return
                            }

                            let activity = MatchActivity(matchAct: try Activity.request(attributes:activityAttributes,contentState: initialContentState), idActivity: matches[0].id)
                            ActivityManager.matchActivities.append(activity)
                        
                            
                    }
                    print("Comienza el partido")
                }
                activityCounter += 1
            }
        }
        
    }
    func getStatus(halfTime: childScore, fullTime: childScore,status:String,match:Match)->String{
        switch status {
        case "IN_PLAY":
           // startActivity(match: match)
            if halfTime.home == nil{
                    return "1ª PARTE"
                }else
                {
                    return "2ª PARTE"
                }
            
        case "PAUSED" :
          //  startActivity(match: match)
            return "DESCANSO"
        case "FINISHED":  return "FINALIZADO"
        default: return ""
            
        }
    }
    
}

func getPart(halfTime: childScore, fullTime: childScore,status:String)->String{
    switch status {
    case "IN_PLAY":
        if halfTime.home == nil{
                return "1ª PARTE"
            }else
            {
                return "2ª PARTE"
            }
        
    case "PAUSED" :  return "DESCANSO"
    case "FINISHED":  return "FINALIZADO"
    default: return ""
        
    }
}



struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .environmentObject(FirestoreManager())
       
    }
}
