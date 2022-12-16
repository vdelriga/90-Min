//
//  Partidos.swift
//  Minuto y Resultado
//
//  Created by Victor Manuel Del Rio Garcia on 17/9/22.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Token: Codable {
    var token: String
}

struct TeamData: Codable {
    var name: String?
    var website: String?
    var id: Int?
    var coach: Coach?
    var squad: [Player]?
    
}

struct Coach:Codable{
    var id:Int?
    var name: String?
    var nationality: String?
}
struct Player:Codable{
    var id:Int
    var name: String
    var position: String?
    var nationality:String?
}
struct Matches: Codable {
    var matches: [Match]
}
struct MatchesWC: Codable {
    var matches: [MatchWC]
}

struct Standing: Codable {
    var standings: [StandingType]
}

struct StandingCL: Codable {
    var standings: [StandingGroup]
}
struct StandingGroup:Codable{
    var group: String
    var table: [Position]
}
struct StandingType:Codable{
    var type: String
    var table: [Position]
}

struct Position:Codable{
        var position: Int
        var team: Team
        var playedGames: Int
        var won: Int
        var draw:Int
        var lost:Int
        var points:Int
        var goalsFor:Int
        var goalsAgainst:Int
        var goalDifference:Int
}

struct Team:Codable {
    var id: Int?
    var name: String?
    var shortName: String?
    var tla: String?
    var crest: String?
    
}

struct Season:Codable {
    var currentSeason:CurrentSeason
    
}
struct CurrentSeason:Codable{
    var id: Int
    var startDate:String
    var endDate: String
    var currentMatchday: Int
}

struct Match: Codable {
    var id: Int
    var utcDate: String
    var homeTeam: Team
    var awayTeam: Team
    var matchday: Int?
    var status: String
    var score: Score
}
struct MatchWC: Codable {
    var id: Int
    var utcDate: String
    var homeTeam: Team
    var awayTeam: Team
    var matchday: Int?
    var status: String
    var score: Score
    var stage: String
}

struct childScore:Codable{
    var home: Int?
    var away: Int?
}

struct Score: Codable{
   // var duration: String
    var fullTime: childScore
    var halfTime: childScore
}




