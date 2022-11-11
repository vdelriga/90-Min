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

struct HomeWC: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @Environment(\.scenePhase) var scenePhase
    @State private var matches = [MatchWC]()
    @State private var matchesSeason = [MatchWC]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @State private var newMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    @State private var focus = 0
    @State private var  resultOpenActivity = ""
    let maxMatchDay = 7
    var body: some View {
            ZStack{
               // SwiftUIBannerAd(adPosition: .bottom, adUnitId:Constants.BannerId)
                VStack{
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    HStack{
                        if (newMatchday > 1){
                            Button {
                                newMatchday = newMatchday - 1
                                jornada = getMatchDay(newMatchDay: newMatchday)
                                if newMatchday == currentMatchday{
                                    Task{
                                        getMatchdayMatchesWC()
                                    }
                                }else{
                                    loadMatchDay(matchday:newMatchday)
                                }
                            }label:{
                                Image(systemName:"chevron.backward")
                                    .foregroundColor(.red)
                            }
                            .padding(.leading)
                        }
                        Spacer()
                        if !jornada.isEmpty {
                            Text(NSLocalizedString("matchDayText",comment:"") + jornada)
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        Spacer()
                        if (newMatchday < maxMatchDay){
                            Button{
                                newMatchday = newMatchday + 1
                                jornada = getMatchDay(newMatchDay: newMatchday)
                                if newMatchday == currentMatchday{
                                    getMatchdayMatchesWC()
                                }else{
                                    loadMatchDay(matchday: newMatchday)
                                }
                            }label:{
                                Image(systemName:"chevron.right")
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing)
                        }
                        
                    }
                   
                    ZStack{
                        Image("qatar")
                            .resizable()
                            .frame(width: 350, height: 350)
                            .blur(radius:3)
                        ScrollViewReader { proxy in
                        if #available(iOS 15.0, *) {
                            List(matches, id: \.id) { item in
                                VStack(alignment: .leading) {
                                    HStack{
                                        VStack(alignment: .center,spacing:4){
                                            Image(String(item.homeTeam.id ?? 0))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50)
                                                .hoverEffect(/*@START_MENU_TOKEN@*/.automatic/*@END_MENU_TOKEN@*/)
                                            Text(item.homeTeam.shortName ?? "-")
                                                .font(.headline)
                                                .lineLimit(2)
                                            
                                        }.frame(width: 111.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
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
                                                .lineLimit(/*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                                            
                                        }
                                        Spacer()
                                        VStack(alignment:.center){
                                            Image(String(item.awayTeam.id ?? 0))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                                .hoverEffect(/*@START_MENU_TOKEN@*/.automatic/*@END_MENU_TOKEN@*/)
                                            
                                            Text(item.awayTeam.shortName ?? "-")
                                                .font(.headline)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                            
                                            
                                        }.frame(width: 111.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                                    }
                                }.onTapGesture{
                                    result = startActivity(match: item)
                                    showToast.toggle()
                                }
                            }.toast(isPresenting:$showToast){
                                AlertToast(type: result ?.complete(.green):.error(.red),title:resultOpenActivity)
                            }
                            .padding(.bottom)
                            .refreshable{
                                getMatchdayMatchesWC()
                            }.onReceive(self.observer.$enteredForeground) { _ in
                                    Task {
                                        getCurrentMatchdayWC()
                                        getSeasonMatchesWC()
                                        //await getCurrentMatchdayWCDatabase()
                                        //await loadDataSeasonWC()
                                    }
                            }
                            .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                            .onChange(of:scenePhase){newPhase in
                                if newPhase == .background{
                                    focus = 0
                                }else if newPhase == .inactive{
                                    focus = 0
                                }else if newPhase == .active{
                                    focus = getFocus()
                                }
                                
                            }
                            .onChange(of:focus){value in
                                withAnimation {
                                    proxy.scrollTo(value,anchor:.center)
                                }

                                }
                            }
                            
                        }
                    }
                }
                SwiftUIBannerAd(adPosition: .bottom, adUnitId:Constants.BannerId)
                
            }.onReceive(firestoreManager.$currentWCMatchday) { matchday in
                if(matchday != 0){
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.matchdayWCTimestamp.addingTimeInterval(21600000)
                    if now  < expiredTime {
                        jornada = getMatchDay(newMatchDay: matchday)
                        currentMatchday = matchday
                        newMatchday = matchday
                        getMatchdayMatchesWC()
                    }else{
                        Task{
                            await getCurrentMatchdayWCDatabase()
                        }
                    }
                }
            }
            .onReceive(firestoreManager.$seasonWCMatches) { matches in
                let now = Date.now
                //se añade la fecha de expiración en segundos(6h)
                let expiredTime = firestoreManager.seasonWCMatchesTimestamp.addingTimeInterval(21600)
                if now  < expiredTime {
                    matchesSeason = matches.matches
                }else{
                    Task{
                        await loadDataSeasonWC()
                    }
                }
            }
            .onReceive(firestoreManager.$matchdayMatchesWC) { matchdayMatches in
                if matchdayMatches.matches.count > 0 {
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.matchdayMatchesWCTimestamp.addingTimeInterval(10)
                    if now  < expiredTime {
                        print("Información de partidos cacheada")
                        matches = matchdayMatches.matches
                    }else{
                        Task{
                            await loadDataWC()
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
            }else if match.stage == "LAST_16" && matchday == 4{
                matches.append(match)
            }else if match.stage == "QUARTER_FINALS" && matchday == 5{
                matches.append(match)
            }else if match.stage == "SEMI_FINALS" && matchday == 6{
                matches.append(match)
            }else if match.stage == "FINAL" && matchday == 7{
                matches.append(match)
            }
        }
    }
    
    func loadDataSeasonWC() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/WC/matches")
        else {
            print("Invalid URL")
            return
            }
        var request = URLRequest(url: url)
        request.setValue("b0212e6976094d3aa404ec2c3b6705be", forHTTPHeaderField: "X-Auth-Token")
        do {
            let (data, _) = try await URLSession.shared.data(for:request)

            if let decodedResponse =
                try? JSONDecoder().decode(MatchesWC.self, from: data){
                matchesSeason = decodedResponse.matches
                firestoreManager.addSeasonMatchesWC(decodedResponse)
                firestoreManager.updateSeasonMatchesWC()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    func loadDataWC() async {
        var urlString = ""
        switch (currentMatchday){
        case 1,2,3: urlString = "https://api.football-data.org/v4/competitions/WC/matches?matchday=" + jornada
        case 4: urlString = "https://api.football-data.org/v4/competitions/WC/matches?stage=" + "LAST_16"
        case 5: urlString = "https://api.football-data.org/v4/competitions/WC/matches?stage=" + "QUARTER_FINALS"
        case 6: urlString = "https://api.football-data.org/v4/competitions/WC/matches?stage=" + "SEMI_FINALS"
        case 7: urlString = "https://api.football-data.org/v4/competitions/WC/matches?stage=" + "FINAL"
        default:urlString = ""

        }
        guard let url = URL(string: urlString)
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
                try? JSONDecoder().decode(MatchesWC.self, from: data){
                matches = decodedResponse.matches
                firestoreManager.addMatchdayMatchesWC(decodedResponse)
                firestoreManager.updateMatchdayMatchesWC()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    func getCurrentMatchdayWC(){
        firestoreManager.getSeasonWC()

    }
    
    func getSeasonMatchesWC(){
        firestoreManager.getSeasonMatchesWC()

    }
    
    func getMatchdayMatchesWC(){
        firestoreManager.getMatchdayMatchesWC()
    }
    
    func getCurrentMatchdayWCDatabase() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/WC")
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
                firestoreManager.addSeasonWC(decodedResponse.currentSeason)
                firestoreManager.updateSeasonWC()
                Task {
                    getMatchdayMatchesWC()
                    //await loadDataWC()
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
    
    
    func startActivity(match: MatchWC)->Bool{
        if #available(iOS 16.1, *) {
            if !existActivity(id:match.id) && (match.status == "IN_PLAY" || match.status=="PAUSED"||match.status == "TIMED"){
                let initialContentState = MatchAttributes.ContentState(status:match.status, scoreHomeHalfTime: match.score.halfTime.home,scoreAwayHalfTime: match.score.halfTime.away,scoreHomeFullTime: match.score.fullTime.home,scoreAwayFullTime: match.score.fullTime.away)
                let activityAttributes = MatchAttributes(id: match.id, utcDate: match.utcDate, matchday: match.matchday ?? 0, idHome: match.homeTeam.id ?? 0, nameHome: match.homeTeam.name ?? "_", shortNameHome: match.homeTeam.shortName ?? "-", tlaHome: match.homeTeam.tla ?? "", crestHome: match.homeTeam.crest ?? "", idAway: match.awayTeam.id ?? 0, nameAway: match.awayTeam.name ?? "_", shortNameAway: match.awayTeam.shortName ?? "-", tlaAway: match.awayTeam.tla ?? "", crestAway: match.awayTeam.crest ?? "")
                let now = Date.now.addingTimeInterval(3600)
                let dateFormatter = ISO8601DateFormatter()
                let matchTime = dateFormatter.date(from:match.utcDate)!
                if now > matchTime
                {
                    if ActivityAuthorizationInfo().areActivitiesEnabled {
                        do{
                            let act =  try Activity<MatchAttributes>.request(attributes:activityAttributes,contentState: initialContentState,pushType: .token)
                            Task {
                                for await data in act.pushTokenUpdates {
                                    let myToken = data.map {String(format: "%02x", $0)}.joined()
                                    firestoreManager.addMatchToken(matchId: match.id, token: Token(token: myToken))
                                }
                            }
                        }catch (let error){
                            print("Error creando la actividad en directo \(error.localizedDescription)")
                        }
                        /*Messaging.messaging().subscribe(toTopic: String(match.id)) { error in
                         print("Subscribed to Match: \(match.id)")
                         }*/
                    }else{
                        resultOpenActivity = NSLocalizedString("LANoActiveKey", comment: "")
                        return false
                    } //OK Actividad en directo
                    resultOpenActivity = NSLocalizedString("addingMatchtoLockScreenOK", comment: "")
                    return true
                }else{ //Demasiado temprano
                    resultOpenActivity = NSLocalizedString("LAEarlyKey", comment: "")
                    return false
                }
            }else{ //Si partido no ha finalizado o ya existe
                resultOpenActivity = NSLocalizedString("LAStatusKey", comment: "")
                return false
            }
        } //Si no es IOS16.1
            resultOpenActivity = NSLocalizedString("LAUpgradeKey", comment: "")
            return false
    }
    
    func getMatchDay(newMatchDay:Int)->String{
        if newMatchDay <= 3 {
            return String(newMatchDay)
        }else{
            switch newMatchDay {
            case 4: return NSLocalizedString("last16Key",comment:"")
            case 5: return NSLocalizedString("quarterFinalsKey",comment:"")
            case 6: return NSLocalizedString("semiFinalsKey",comment:"")
            case 7: return NSLocalizedString("finalKey",comment:"")
            default: return ""
            }
        }
    }
    
    func getFocus()->Int{
        if matches.isEmpty {
            return 0
        }else{
            focus = matches.first!.id
            var found = false
            for match in matches {
                if (match.status == "TIMED" || match.status == "IN_PLAY" ) && !found{
                    found = true
                    focus = match.id
                }
            }
            return focus
        }
        
    }
    
    func getStatus(halfTime: childScore, fullTime: childScore,status:String,match:MatchWC)->String{
        switch status {
        case "TIMED":
            if focus == 0 {
                focus = match.id
            }
            return ""
        case "IN_PLAY":
            if focus == 0 {
                focus = match.id
            }
            if halfTime.home == nil{
                return NSLocalizedString("firstHalfKey",comment:"")
                }else
                {
                    return NSLocalizedString("secondHalfKey",comment:"")
                }
            
        case "PAUSED" :
            return NSLocalizedString("pausedKey",comment:"")
        case "FINISHED":  return NSLocalizedString("finishedKey",comment:"")
        default: return ""
            
        }
    }
    
}

struct HomeWC_Previews: PreviewProvider {
    static var previews: some View {
        HomeWC()
            .previewDevice("iPhone 14 Pro")
            .environmentObject(FirestoreManager())
       
    }
}

