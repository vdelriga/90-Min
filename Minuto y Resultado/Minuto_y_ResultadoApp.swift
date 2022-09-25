//
//  Minuto_y_ResultadoApp.swift
//  Minuto y Resultado
//
//  Created by Victor Manuel Del Rio Garcia on 17/9/22.
//

import SwiftUI
import BackgroundTasks


@main
struct Minuto_y_ResultadoApp: App {
    
    
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
                MainView()
        }
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }.backgroundTask(.appRefresh("matchUpdate")) {
            scheduleAppRefresh()
            print("Se está ejecutando en Background")
            ActivityMatches.counter += 1
            if #available(iOS 16.1, *) {
                    if activityOnGoing(){
                            await loadLiveData()
                    }
            }
            
        }
    }

}

func scheduleAppRefresh() {
   let request = BGAppRefreshTaskRequest(identifier: "matchUpdate")
   // Fetch no earlier than 30s from now.
    request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
        
   do {
      try BGTaskScheduler.shared.submit(request)
   } catch {
      print("Could not schedule app refresh: \(error)")
   }
}

@available(iOS 16.1, *)
func loadLiveData() async {
    guard let url = URL(string: "https://api.football-data.org/v4/competitions/PD/matches?status=IN_PLAY")
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
            ActivityMatches.liveMatches = decodedResponse.matches
            print("Número de partidos en background:" +  String(ActivityMatches.liveMatches.count))
            for match in ActivityMatches.liveMatches{
                if let activity = getActivityLive(matchId: match.id){
                    let statusText = getPart(halfTime: match.score.halfTime, fullTime: match.score.fullTime, status: match.status)
                    switch statusText {
                        case "1ª PARTE","2ª PARTE","DESCANSO" :
                            let updateMatch = MatchAttributes.ContentState(status: statusText, scoreHomeHalfTime: match.score.halfTime.home, scoreAwayHalfTime: match.score.halfTime.away, scoreHomeFullTime: match.score.fullTime.home, scoreAwayFullTime: match.score.fullTime.away)
                                await activity.matchActivity.update(using: updateMatch, alertConfiguration: nil)
                        case "FINALIZADO":
                            let finalMatchStatus = MatchAttributes.ContentState(status: statusText, scoreHomeHalfTime: match.score.halfTime.home, scoreAwayHalfTime: match.score.halfTime.away, scoreHomeFullTime: match.score.fullTime.home, scoreAwayFullTime: match.score.fullTime.away)
                                await activity.matchActivity.end(using:finalMatchStatus, dismissalPolicy: .default)
                        default: print("Escenario no contemplado")
                    }
                }
            }
            //Para probar actualización
            if let activityTest = ActivityManager.matchActivities.first?.matchActivity{
                if ActivityMatches.liveMatches.count == 0{
                    print("Actualizando el liveActivity:\(ActivityMatches.counter)")
                    if ActivityMatches.counter<6 {
                        let updateMatch = MatchAttributes.ContentState(status: "ACTUALIZ", scoreHomeHalfTime: ActivityMatches.counter, scoreAwayHalfTime: ActivityMatches.counter, scoreHomeFullTime: ActivityMatches.counter, scoreAwayFullTime: ActivityMatches.counter)
                        await activityTest.update(using: updateMatch, alertConfiguration: nil)
                    } else{
                        let finalMatchStatus = MatchAttributes.ContentState(status: "ACTUALIZ", scoreHomeHalfTime: ActivityMatches.counter, scoreAwayHalfTime: ActivityMatches.counter, scoreHomeFullTime: ActivityMatches.counter, scoreAwayFullTime:ActivityMatches.counter)
                        await activityTest.end(using:finalMatchStatus, dismissalPolicy: .default)
                    }
                }}//fin bloque de pruebas
           
        }
    } catch let jsonError as NSError {
        print("JSON decode failed: \(jsonError.localizedDescription)")
    }
}



@available(iOS 16.1, *)
func activityOnGoing()->Bool{
    for activity in ActivityManager.matchActivities {
        if activity.matchActivity.activityState == .active{
            return true
        }
    }
    return false
}

struct ActivityMatches{
    static var liveMatches = [Match]()
    static var counter: Int = 0
}


