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
import StoreKit





struct HomeWC: View {
    @State private var sheetTeamPresented = false
    @State private var sheetYoutubePresented = false
    @State public var teamId: Int = 0
    @EnvironmentObject var firestoreManager: FirestoreManager
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    @State private var matches = [MatchWC]()
    @State private var videosDict: [String: String] = [:]
    @State private var matchesSeason = [MatchWC]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @State private var newMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    @State private var focus = 0
    @State private var videoID: String = ""
    @State private var  resultOpenActivity = ""
    public static var defaults:Defaults = Defaults()
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
                        if !jornada.isEmpty && newMatchday<4 {
                            Text(NSLocalizedString("matchDayText",comment:"") + jornada)
                                .font(.headline)
                                .foregroundColor(.red)
                        }else if newMatchday >= 4{
                            Text(jornada)
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
                        Image("backQatar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .blur(radius:2)
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
                                         .onTapGesture{
                                             teamId = item.homeTeam.id ?? 0
                                             sheetTeamPresented.toggle()
                                             }
                                        Spacer()
                                        VStack{
                                            if let _ = videosDict[String(item.id)]{
                                                    Image(systemName: "video")
                                                        .foregroundColor(.black)
                                                    Text("resumenKey")
                                                        .foregroundColor(.black)
                                            }else{
                                                Text(getMatchDate(stringDate: item.utcDate))
                                                    .font(.caption)
                                                Text(getMatchTime(stringDate: item.utcDate))
                                                    .font(.caption)
                                            }
                                            Text(getScore(halfTime:item.score.halfTime, fullTime:item.score.fullTime))
                                                .font(.largeTitle)
                                            Text(getStatus(halfTime:item.score.halfTime,fullTime:item.score.fullTime,status:item.status,match:item))
                                                .font(.caption)
                                                .lineLimit(/*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                                            
                                        }.onTapGesture{
                                            if let _ = videosDict[String(item.id)]{
                                                videoID = videosDict[String(item.id)] ?? ""
                                                sheetYoutubePresented.toggle()
                                            }else{
                                                result = startActivity(match: item)
                                                showToast.toggle()
                                            }
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
                                         .onTapGesture{
                                                teamId = item.awayTeam.id ?? 0
                                                sheetTeamPresented.toggle()
                                                }
                                    }
                                }.listRowBackground(Color(UIColor.systemGray6))
                                 /*.onTapGesture{
                                    result = startActivity(match: item)
                                    showToast.toggle()
                                 }*/
                                 .contextMenu {
                                     Button(action: {
                                         result = startActivity(match: item)
                                         showToast.toggle()
                                     }, label: {
                                         Image(systemName: "plus.circle")
                                         Text("AddLA")
                                     })
                                     Button(action: {
                                         teamId = item.homeTeam.id ?? 0
                                         sheetTeamPresented.toggle()
                                     }, label: {
                                         Image(systemName: "info.circle")
                                         Text(item.homeTeam.name ?? "")
                                     })
                                     Button(action: {
                                         teamId = item.awayTeam.id ?? 0
                                         sheetTeamPresented.toggle()
                                     }, label: {
                                         Image(systemName: "info.circle")
                                         Text(item.awayTeam.name ?? "")
                                     })
                                     if let _ = videosDict[String(item.id)]{
                                         Button(action: {
                                             videoID = videosDict[String(item.id)] ?? ""
                                             sheetYoutubePresented.toggle()
                                         }, label: {
                                             Image(systemName: "video")
                                             Text("resumenKey")
                                         })
                                     }
                                 }
                            }.sheet(isPresented:$sheetTeamPresented){
                                if sheetTeamPresented{
                                    TeamView(teamId: $teamId)
                                        
                                }
                               }
                            .sheet(isPresented:$sheetYoutubePresented){
                                if sheetYoutubePresented{
                                    YoutubeView(videoID: videoID)
                                        .frame(minHeight:0,maxHeight:UIScreen.main.bounds.height * 0.3)
                                        .cornerRadius(5)
                                        .padding(.horizontal,5)
                                }
                               }
                            .toast(isPresenting:$showToast){
                                AlertToast(type: result ?.complete(.green):.error(.red),title:resultOpenActivity)
                            }
                            .padding(.bottom)
                            .refreshable{
                                getMatchdayMatchesWC()
                            }.onReceive(self.observer.$enteredForeground) { _ in
                                    Task {
                                        getCurrentMatchdayWC()
                                        getSeasonMatchesWC()
                                        getVideosWC()
                                        let counter = HomeWC.defaults.getCounter()
                                        let review = HomeWC.defaults.getReview()
                                        HomeWC.defaults.setCounter(count: counter + 1)
                                        if counter+1 >= 5 && !review {
                                            HomeWC.defaults.setReview(mark:true)
                                            HomeWC.defaults.setDate(date: Date.now)
                                            requestReview()
                                        }
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
                
            }.onReceive(firestoreManager.$videos){videos in
                if let videosYT = videos{
                    for document in videosYT.documents {
                        self.videosDict[document.documentID] = document["videoID"] as? String
                    }
                }
            }
            .onReceive(firestoreManager.$currentWCMatchday) { matchday in
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
    
    func getVideosWC(){
        firestoreManager.getVideosWC()

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
            if !existActivity(id:match.id) && (match.status == "IN_PLAY" || match.status=="PAUSED"||match.status == "TIMED"||match.status == "SCHEDULED"){
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

