//
//  NBA.swift
//  NBA Wins Pool, Inc.
//
//  Created by John Jessen on 11/15/18.
//  Copyright © 2018 NBA Wins Pool, Inc. All rights reserved.
//

import Foundation

class NBA {
  static let shared = NBA()
  static let standings = "http://data.nba.net/10s/prod/v1/current/standings_conference.json?fbclid=IwAR3HPj4FIv_fRQk6DSW2VvzE8hn_WrNLLGa9I5uQRpPAgcEwRGP6fWeyBTg"
  
  struct Standings: Codable {
    let teamteam_standing: [String: NBA.Standing]
  }
  
  enum TeamId: String, Codable {
    case celtics = "nba.t.2"
    case brooklynnets = "nba.t.17"
    case nyknicks = "nba.t.18"
    case sixers = "nba.t.20"
    case raptors = "nba.t.28"
    case chicagobulls = "nba.t.4"
    case cavs = "nba.t.5"
    case detroitpistons = "nba.t.8"
    case pacers = "nba.t.11"
    case bucks = "nba.t.15"
    case atlhawks = "nba.t.1"
    case miamiheat = "nba.t.14"
    case orlandomagic = "nba.t.19"
    case washwizards = "nba.t.27"
    case hornets = "nba.t.30"
    case warriors = "nba.t.9"
    case laclippers = "nba.t.12"
    case lakers = "nba.t.13"
    case suns = "nba.t.21"
    case sacramentokings = "nba.t.23"
    case pelicansnba = "nba.t.3"
    case dallasmavs = "nba.t.6"
    case houstonrockets = "nba.t.10"
    case spurs = "nba.t.24"
    case memgrizz = "nba.t.29"
    case nuggets = "nba.t.7"
    case timberwolves = "nba.t.16"
    case trailblazers = "nba.t.22"
    case okcthunder = "nba.t.25"
    case utahjazz = "nba.t.26"
  }
  
  struct Standing: Codable {
    let team_record: NBA.Record
  }
  
  struct Record: Codable {
    let wins: String
    let losses: String
  }
  
  static func seasonYearFromDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    
    // If the date is before June (month 6), use previous year
    let adjustedYear = month < 6 ? year - 1 : year
    return String(adjustedYear)
  }
  
  func getStandings(date: Date? = nil, completion: @escaping (Bool, NBA.Standings?) -> Void) {
    let year = NBA.seasonYearFromDate(date ?? Date())
    Backend.shared.request(host: "https://sports.yahoo.com/",
                           endPoint: "site/api/resource/sports.league.standings;alias=full_standings;count=100;league=nba;leagueSeason=standings;season=\(year)",
                           parameters: [
                            "device" : "desktop",
                            "ecma" : "modern",
                            "intl" : "us",
                            "lang" : "en-US",
//                            "prid" : "5m4t64dkfg95o",
                            "region" : "US",
                            "site" : "sports",
                            "ver" : "1.0.13202"
                                       ],
                           completion: completion)
  }
}

extension NBA.TeamId {
  func toTeamId() -> Team.Id? {
    switch self {
    case .atlhawks: return .hawks
    case .celtics: return .celtics
    case .brooklynnets: return .nets
    case .hornets: return .hornets
    case .chicagobulls: return .bulls
    case .cavs: return .cavaliers
    case .dallasmavs: return .mavericks
    case .nuggets: return .nuggets
    case .detroitpistons: return .pistons
    case .warriors: return .warriors
    case .houstonrockets: return .rockets
    case .pacers: return .pacers
    case .laclippers: return .clippers
    case .lakers: return .lakers
    case .memgrizz: return .grizzlies
    case .miamiheat: return .heat
    case .bucks: return .bucks
    case .timberwolves: return .timberwolves
    case .pelicansnba: return .pelicans
    case .nyknicks: return .knicks
    case .okcthunder: return .thunder
    case .orlandomagic: return .magic
    case .sixers: return .sixers
    case .suns: return .suns
    case .trailblazers: return .blazers
    case .sacramentokings: return .kings
    case .spurs: return .spurs
    case .raptors: return .raptors
    case .utahjazz: return .jazz
    case .washwizards: return .wizards
    }
  }
}

extension NBA.Standing {
  var wins: Int {
    return Int(team_record.wins) ?? 0
  }
  var losses: Int {
    return Int(team_record.losses) ?? 0
  }
}
