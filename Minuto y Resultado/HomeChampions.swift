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
    @State private var sheetYoutubePresented = false
    @State private var sheetTeamPresented = false
    @State public var teamId: Int = 0
    @State private var videoID: String = ""
    @State private var videosDict: [String: String] = [:]
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var matches = [MatchWC]()
    @State private var matchesSeason = [MatchWC]()
    @State private var jornada = ""
    @State private var currentMatchday = 0
    @ObservedObject var observer = Observer()
    @State var activityCounter = 0
    @State private var showToast = false
    @State private var result = false
    @State private var focus = 0
    let maxMatchDay = 10
    @State private var  resultOpenActivity = ""
    @State private var newMatchday = 0
    
    
    var body: some View {
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
                                //await loadData()
                                getMatchdayMatchesCL()
                            }
                        }else{
                            loadMatchDay(matchday: newMatchday)
                        }
                    }label:{
                        Image(systemName:"chevron.backward")
                            .foregroundColor(.red)
                    }
                    .padding(.leading)
                }
                Spacer()
                if !jornada.isEmpty && newMatchday<7{
                    
                    Text(NSLocalizedString("matchDayText",comment:"") + jornada)
                        .font(.headline)
                        .foregroundColor(.red)
                }else if newMatchday >= 7{
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
                            Task{
                                getMatchdayMatchesCL()
                            }
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
                Image("CL")
                    .resizable()
                    .frame(width: 330, height: 330)
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
                                            .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                        
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
                                                Text("resumenKey")

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
                                    }
                                    .onTapGesture{
                                        if let _ = videosDict[String(item.id)]{
                                            videoID = videosDict[String(item.id)] ?? ""
                                            if let url = URL(string: videoID) {
                                                if UIApplication.shared.canOpenURL(url){
                                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                                }else{
                                                    sheetYoutubePresented.toggle()
                                                }
                                            }
                                        }else{
                                            result = startActivity(match: item)
                                            showToast.toggle()
                                        }
                                     }
                                    Spacer()
                                    VStack{
                                        Image(String(item.awayTeam.id ?? 0))
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/)
                                        
                                        Text(item.awayTeam.shortName ?? "-")
                                            .font(.headline)
                                            .lineLimit(2)
                                    }.frame(width: 111.0, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/)
                                     .onTapGesture{
                                                  teamId = item.awayTeam.id ?? 0
                                                  sheetTeamPresented.toggle()
                                                  }
                                }
                            }.listRowBackground(Color(UIColor.systemGray6))
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
                                   VStack{
                                       Image("logo")
                                           .resizable()
                                           .aspectRatio(contentMode: .fit)
                                       Spacer()
                                       YoutubeView(videoID: videoID)
                                           .frame(minHeight:0,maxHeight:UIScreen.main.bounds.height * 0.27)
                                           .cornerRadius(5)
                                           .padding(.horizontal,5)
                                       Spacer()
                                   }
                               }
                        }.toast(isPresenting:$showToast){
                            AlertToast(type: result ?.complete(.green):.error(.red),title:resultOpenActivity)
                        }
                        .padding(.bottom)
                        .refreshable{
                            getCurrentMatchdayDatabase()
                            getMatchdayMatchesCL()
                        }.onReceive(self.observer.$enteredForeground) { _ in
                            Task {
                                getVideosWC()
                                getCurrentMatchdayDatabase()
                                getSeasonCLMatches()
                                //await loadDataSeason()
                                //await loadData()
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
                SwiftUIBannerAd(adPosition: .bottom, adUnitId:Constants.BannerId)
                
            }.onReceive(firestoreManager.$videos){videos in
                if let videosYT = videos{
                    for document in videosYT.documents {
                        self.videosDict[document.documentID] = document["videoID"] as? String
                    }
                }
            }
            .onReceive(firestoreManager.$currentCLMatchday) { matchday in
                if(matchday != 0){
                    //let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    //let expiredTime = firestoreManager.matchdayCLTimestamp.addingTimeInterval(21600)
                    //if now  < expiredTime {
                        jornada = getMatchDay(newMatchDay: matchday)
                        currentMatchday = matchday
                        newMatchday = matchday
                        getSeasonCLMatches()
                    //}else{
                      //  Task{
                      //      await getCurrentMatchday()
                      //  }
                   // }
                }
            }.onReceive(firestoreManager.$seasonCLMatches) { matches in
                let now = Date.now
                    //se añade la fecha de expiración en segundos(6h)
                    let expiredTime = firestoreManager.seasonCLMatchesTimestamp.addingTimeInterval(21600)
                    if now  < expiredTime {
                        matchesSeason = matches.matches
                        getMatchdayMatchesCL()
                        
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
            }.background(Color(UIColor.systemGray6))
            
        }.background(Color(UIColor.systemGray6))

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
        var urlString = ""
        switch (currentMatchday){
        case 1,2,3,4,5,6: urlString = "https://api.football-data.org/v4/competitions/CL/matches?matchday=" + jornada
        case 7: urlString = "https://api.football-data.org/v4/competitions/CL/matches?stage=" + "LAST_16"
        case 8: urlString = "https://api.football-data.org/v4/competitions/CL/matches?stage=" + "QUARTER_FINALS"
        case 9: urlString = "https://api.football-data.org/v4/competitions/CL/matches?stage=" + "SEMI_FINALS"
        case 10: urlString = "https://api.football-data.org/v4/competitions/CL/matches?stage=" + "FINAL"
        default:urlString = ""

        }
        guard let url = URL(string: urlString)
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
                matches = decodedResponse.matches
                firestoreManager.addMatchdayMatchesCL(decodedResponse)
                firestoreManager.updateMatchdayMatchesCL()
            }
        } catch let jsonError as NSError {
            print("JSON decode failed: \(jsonError.localizedDescription)")
        }
    }
    func loadDataSeason() async {
        guard let url = URL(string: "https://api.football-data.org/v4/competitions/CL/matches?stage=LAST_16,GROUP_STAGE,QUARTER_FINALS,SEMI_FINALS,FINAL")
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
            }else if match.stage == "LAST_16" && matchday == 7{
                matches.append(match)
            }else if match.stage == "QUARTER_FINALS" && matchday == 8{
                matches.append(match)
            }else if match.stage == "SEMI_FINALS" && matchday == 9{
                matches.append(match)
            }else if match.stage == "FINAL" && matchday == 10{
                matches.append(match)
            }
        }
    }
    
    func getVideosWC(){
        firestoreManager.getVideosWC()

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
    
    func getMatchDay(newMatchDay:Int)->String{
        if newMatchDay <= 6 {
            return String(newMatchDay)
        }else{
            switch newMatchDay {
            case 7: return NSLocalizedString("last16Key",comment:"")
            case 8: return NSLocalizedString("quarterFinalsKey",comment:"")
            case 9: return NSLocalizedString("semiFinalsKey",comment:"")
            case 10: return NSLocalizedString("finalKey",comment:"")
            default: return ""
            }
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
                    return NSLocalizedString("firstHalfKey", comment: "")
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


struct HomeChampions_Previews: PreviewProvider {
    static var previews: some View {
            HomeChampions()
            .environmentObject(FirestoreManager())
       
    }
}
