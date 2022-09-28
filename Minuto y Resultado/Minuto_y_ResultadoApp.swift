//
//  Minuto_y_ResultadoApp.swift
//  Minuto y Resultado
//
//  Created by Victor Manuel Del Rio Garcia on 17/9/22.
//

import SwiftUI
import BackgroundTasks
import Firebase
import UserNotifications
import ActivityKit


@main
struct Minuto_y_ResultadoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
                MainView()
        }
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
                        let updateMatch = MatchAttributes.ContentState(status: "IN_PLAY", scoreHomeHalfTime: ActivityMatches.counter, scoreAwayHalfTime: ActivityMatches.counter, scoreHomeFullTime: ActivityMatches.counter, scoreAwayFullTime: ActivityMatches.counter)
                        await activityTest.update(using: updateMatch, alertConfiguration: nil)
                    } else{
                        let finalMatchStatus = MatchAttributes.ContentState(status: "FINISHED", scoreHomeHalfTime: ActivityMatches.counter, scoreAwayHalfTime: ActivityMatches.counter, scoreHomeFullTime: ActivityMatches.counter, scoreAwayFullTime:ActivityMatches.counter)
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


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

      let deviceToken:[String: String] = ["token": fcmToken ?? ""]
        print("Device token: ", deviceToken) // This token can be used for testing notifications on FCM
        
    }
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNS token  retrieved: \(deviceToken)")
        var token = ""
        for i in 0..<deviceToken.count{
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print("Registration succeeded! Token:",token)
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
        
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error al registrar el dispositivo")
    }

    //Cuando se pincha sobre la push
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo

    if let messageID = userInfo[gcmMessageIDKey] {
      print("Message ID from userNotificationCenter didReceive: \(messageID)")
    }

    print(userInfo)

    completionHandler()
  }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self

        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        return true
    }
    
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // Perform background operation
        if #available(iOS 16.1, *) {
            if let strMatchId = userInfo["matchId"] as? String, let matchId = Int(strMatchId),let strHomeScore = userInfo["homeScore"] as? String, let homeScore = Int(strHomeScore),let strAwayScore = userInfo["awayScore"] as? String, let awayScore = Int(strAwayScore) ,let status = userInfo["status"] as? String{
                    if let activity = getActivityLive(matchId: Int(matchId)){
                        updateLiveActivity(activity: activity, homeScore: homeScore, awayScore:awayScore,status:status)
                    }
            }
        }
        completionHandler(.newData)
    }

    @available(iOS 16.1, *)
    func updateLiveActivity(activity:MatchActivity, homeScore: Int, awayScore: Int, status: String) {
        Task{
            let updateMatch = MatchAttributes.ContentState(status: status, scoreHomeFullTime: homeScore, scoreAwayFullTime: awayScore)
            await activity.matchActivity.update(using: updateMatch, alertConfiguration: nil)
        }
    }

    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in foreground")
        print(notification.request.content.userInfo)
        completionHandler([UNNotificationPresentationOptions.banner,UNNotificationPresentationOptions.sound, UNNotificationPresentationOptions.badge])
    }
    

   }
