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

struct Home: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    @State private var matches = [Match]()
    @State private var matchesSeason = [Match]()
    @State private var liveMatches = [Match]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    @State private var focus = 0
    @State private var  resultOpenActivity = ""
    @State private var  backImage = ""
    public static var defaults:Defaults = Defaults()
    @State private var selectedLeague = Home.defaults.getLeague()
    let maxMatchDay = 38
    var body: some View {

            ZStack{
                VStack{
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Picker("Favorite League", selection: $selectedLeague, content: {
                        VStack {
                            Image("laliga")
                        }.tag(0)
                        VStack{
                            Image("PL")
                        }.tag(1)
                        VStack{
                            Image("BL1")
                        }.tag(2)
                        VStack{
                            Image("SA1")
                        }.tag(3)
                        VStack{
                            Text("Prueba")
                        }.tag(4)

                    }).pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedLeague) { newValue in
                            Task{
                                Home.defaults.setLeague(league:newValue)
                                matches.removeAll()
                                getCurrentMatchdayDatabase(league:selectedLeague)
                                getSeasonMatches(league:selectedLeague)
                            }
                        }
                    
                    HStack{
                        if (Int(jornada) ?? 0 > 1){
                            Button {
                                let newMatchday = (Int(jornada) ?? 1) - 1
                                jornada = String(newMatchday)
                                if jornada == String(currentMatchday){
                                    Task{
                                        getLiveMatches()
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
                            Text(NSLocalizedString("matchDayText",comment:"") + jornada)
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        Spacer()
                        if (Int(jornada) ?? 0 < maxMatchDay){
                            Button{
                                let newMatchday = (Int(jornada) ?? 1) + 1
                                jornada = String(newMatchday)
                                if jornada == String(currentMatchday){
                                    getLiveMatches()
                                }else{
                                    loadMatchDay(matchday: Int(jornada) ?? 0)
                                }
                            }label:{
                                Image(systemName:"chevron.right")
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing)
                        }
                        
                    }.background(Color(UIColor.systemGray6))
                   
                    ZStack{
                        
                        if selectedLeague == 0 {
                            Image("PD")
                                .resizable()
                                .frame(width: 350, height: 350)
                            .blur(radius:4)
                        } else if selectedLeague == 1 {
                            Image("PLBACK")
                                .resizable()
                                .frame(width: 350, height: 350)
                            .blur(radius:4)
                        }else if selectedLeague == 2 {
                            Image("BL")
                                .resizable()
                                .frame(width: 350, height: 350)
                            .blur(radius:4)
                        }
                        else if selectedLeague == 3 {
                            Image("SA")
                                .resizable()
                                .frame(width: 350, height: 350)
                            .blur(radius:4)
                        }
                        ScrollViewReader { proxy in
                        if #available(iOS 15.0, *) {
                            List(matches, id: \.id) { item in
                                VStack(alignment: .leading) {
                                    HStack{
                                        VStack(alignment: .center,spacing:4){
                                            Image(String(item.homeTeam.id ?? 0))
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                            
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
                                            
                                            Text(item.awayTeam.shortName ?? "-")
                                                .font(.headline)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                            
                                            
                                        }.frame(width: 111.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                                    }
                                }.listRowBackground(Color(UIColor.systemGray6))
                                .onTapGesture{
                                    result = startActivity(match: item)
                                    showToast.toggle()
                                }
                            }
                            .toast(isPresenting:$showToast){
                                AlertToast(type: result ?.complete(.green):.error(.red),title:resultOpenActivity)
                            }
                            .padding(.bottom)
                            .refreshable{
                                getLiveMatches()
                            }.onReceive(self.observer.$enteredForeground) { _ in
                                    Task {
                                        getCurrentMatchdayDatabase(league: selectedLeague)
                                        getSeasonMatches(league:selectedLeague)
                                        //Bloque para iniciar proceso de revisión
                                        let counter = Home.defaults.getCounter()
                                        Home.defaults.setCounter(count: counter + 1)
                                        let review = Home.defaults.getReview()
                                        if counter+1 >= 5 && !review {
                                            Home.defaults.setReview(mark:true)
                                            Home.defaults.setDate(date: Date.now)
                                            requestReview()
                                        }
                                         //await getCurrentMatchday(league:selectedLeague)
                                         //await loadDataSeason(league:selectedLeague)
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
                
            }.onReceive(firestoreManager.$currentMatchday) { matchday in
                if(matchday != 0){
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.matchdayTimestamp.addingTimeInterval(21600)
                    if now  < expiredTime {
                        jornada = String(matchday)
                        currentMatchday = matchday
                        getLiveMatches()
                    }else{
                        Task{
                            await getCurrentMatchday(league:selectedLeague)
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
                        await loadDataSeason(league:selectedLeague)
                    }
                }
            }
            .onReceive(firestoreManager.$liveMatches) { matchdayMatches in
                if matchdayMatches.matches.count > 0 {
                    let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.liveMatchesTimestamp.addingTimeInterval(10)
                    if now  < expiredTime {
                        print("Información de partidos cacheada")
                        liveMatches = matchdayMatches.matches
                        updateMatchdayMatches(matchday:Int(jornada) ?? 0)
                    }else{
                        Task{
                            await loadData()
                        }
                    }
                }
            }.background(Color(UIColor.systemGray6))
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
    
    func replaceMatches(matches: [Match], replacementMatches: [Match]) -> [Match] {
        var newMatches: [Match] = []
        for match in matches {
            var foundMatch: Match?
            for replacementMatch in replacementMatches {
                if match.id == replacementMatch.id {
                    foundMatch = replacementMatch
                    break
                }
            }
            if let foundMatch = foundMatch {
                newMatches.append(foundMatch)
            } else {
                newMatches.append(match)
            }
        }
        return newMatches
    }
    
    
    func updateMatchdayMatches(matchday:Int){
        self.matches.removeAll()
        for match in matchesSeason{
            if match.matchday == matchday{
                matches.append(match)
            }
        }
        matches = replaceMatches(matches:matches,replacementMatches: liveMatches)
    }
    
    func loadDataSeason(league:Int) async {
        var url: String = ""
        switch(league){
        case 0:url = "https://api.football-data.org/v4/competitions/PD/matches"
        case 1:url = "https://api.football-data.org/v4/competitions/PL/matches"
        case 2:url = "https://api.football-data.org/v4/competitions/BL1/matches"
        case 3:url = "https://api.football-data.org/v4/competitions/SA/matches"
        case 4:url = "https://api.football-data.org/v4/competitions/ELC/matches"
        default: url = "https://api.football-data.org/v4/competitions/PD/matches"
        }
        guard let url = URL(string: url)
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
                firestoreManager.addSeasonMatches(decodedResponse,league:league)
                firestoreManager.updateSeasonMatches(league:league)
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    
    func loadData() async {
        guard let url = URL(string: "https://api.football-data.org/v4/matches")
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
                liveMatches = decodedResponse.matches
                firestoreManager.addLiveMatches(decodedResponse)
                firestoreManager.updateLiveMatches()
                updateMatchdayMatches(matchday:Int(jornada) ?? 0)
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    func getCurrentMatchdayDatabase(league:Int){
        firestoreManager.getSeason(league:league)

    }
    
    func getSeasonMatches(league:Int){
        firestoreManager.getSeasonMatches(league:league)

    }
    
    func getLiveMatches(){
        firestoreManager.getLiveMatches()
    }
    
    func getCurrentMatchday(league:Int) async {
        var url: String = ""
        switch(league){
        case 0:url = "https://api.football-data.org/v4/competitions/PD"
        case 1:url = "https://api.football-data.org/v4/competitions/PL"
        case 2:url = "https://api.football-data.org/v4/competitions/BL1"
        case 3:url = "https://api.football-data.org/v4/competitions/SA"
        case 4:url = "https://api.football-data.org/v4/competitions/ELC"
        default: url = "https://api.football-data.org/v4/competitions/PD"
        }
        guard let url = URL(string: url)
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
                firestoreManager.addSeasonLaLiga(decodedResponse.currentSeason,league:league)
                firestoreManager.updateSeasonLaLiga(league:league)
                Task {
                    getLiveMatches()
                    //await loadData()
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
            if !existActivity(id:match.id) && (match.status == "IN_PLAY" || match.status=="PAUSED"||match.status == "TIMED"||match.status == "SCHEDULED"){
                let initialContentState = MatchAttributes.ContentState(status:match.status, scoreHomeHalfTime: match.score.halfTime.home,scoreAwayHalfTime: match.score.halfTime.away,scoreHomeFullTime: match.score.fullTime.home,scoreAwayFullTime: match.score.fullTime.away)
                let activityAttributes = MatchAttributes(id: match.id, utcDate: match.utcDate, matchday: match.matchday ?? 0, idHome: match.homeTeam.id ?? 0, nameHome: match.homeTeam.name ?? "_", shortNameHome: match.homeTeam.shortName ?? "-", tlaHome: match.homeTeam.tla ?? "", crestHome: match.homeTeam.crest ?? "", idAway: match.awayTeam.id ?? 0, nameAway: match.awayTeam.name ?? "_", shortNameAway: match.awayTeam.shortName ?? "-", tlaAway: match.awayTeam.tla ?? "", crestAway: match.awayTeam.crest ?? "")
                let now = Date.now.addingTimeInterval(3600000)
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
    
    func getStatus(halfTime: childScore, fullTime: childScore,status:String,match:Match)->String{
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

func getPart(halfTime: childScore, fullTime: childScore,status:String)->String{
    switch status {
    case "IN_PLAY":
        if halfTime.home == nil{
                return NSLocalizedString("firstHalfKey", comment: "")
            }else
            {
                return "secondHalfKey"
            }
        
    case "PAUSED" :  return NSLocalizedString("pausedKey",comment:"")
    case "FINISHED":  return NSLocalizedString("finishedKey",comment:"")
    default: return ""
        
    }
}



struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .previewDevice("iPhone 14 Pro")
            .environmentObject(FirestoreManager())
       
    }
}
