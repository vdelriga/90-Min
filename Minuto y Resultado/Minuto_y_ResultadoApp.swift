//
//  Minuto_y_ResultadoApp.swift
//  Minuto y Resultado
//
//  Created by Victor Manuel Del Rio Garcia on 17/9/22.
//

import SwiftUI
import Firebase
import UserNotifications
import ActivityKit
import FirebaseFirestore
import FirebaseCore

@main
struct Minuto_y_ResultadoApp: App {
    
    @StateObject var firestoreManager = FirestoreManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(firestoreManager)
        }
    }

}

struct Constants{
    //Banner de Test
    //public static let BannerId = "ca-app-pub-3940256099942544/2934735716"
    //Banner de Prod
    public static let BannerId = "ca-app-pub-4851885141099304/9005939785"
}

/*
struct ActivityMatches{
    static var liveMatches = [Match]()
    static var counter: Int = 0
}
*/

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {

      let deviceToken:[String: String] = ["token": fcmToken ?? ""]
        print("Device token: ", deviceToken) // This token can be used for testing notifications on FCM
        Messaging.messaging().subscribe(toTopic: "90Min") { error in
          print("Subscribed to 90Min")
        }
        
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?) -> Bool {
        FirebaseApp.configure()
        //let db = Firestore.firestore()
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
            if let contentState = userInfo["content-state"] as? Activity<MatchAttributes>.ContentState{
                print("Nueva push")
            }else
            {
                if let strMatchId = userInfo["matchId"] as? String, let matchId = Int(strMatchId),let strHomeScore = userInfo["homeScore"] as? String, let homeScore = Int(strHomeScore),let strAwayScore = userInfo["awayScore"] as? String, let awayScore = Int(strAwayScore) ,let status = userInfo["status"] as? String{
                    updateLiveActivity(matchId: matchId, userInfo: userInfo, status: status, awayScore: awayScore, homeScore: homeScore)
                }
            }
        }
        completionHandler(.newData)
    }
    

   
    
   }
