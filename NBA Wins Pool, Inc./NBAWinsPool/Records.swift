//
//  Teams.swift
//  NBA Wins Pool
//
//  Created by John Benz Jessen on 9/3/16.
//  Copyright © 2016 NBA Wins Pool, Inc. All rights reserved.
//

import UIKit
import UserNotifications

class Records {
  static let shared = Records()
  
  enum Source {
    case cache, network
  }
  
  var yearToRecords = [String : [Team : Record]]()
  
  weak var delegate: RecordsDelegate?
  
  init() {}
  
  func cachedRecordsForYear(_ year: String) -> [Team : Record]? {
    if let records = yearToRecords[year] {
      return records
    }
    
    if let data = UserDefaults.standard.value(forKey: year) as? Data {
      do {
        yearToRecords[year] = try JSONDecoder().decode([Team : Record].self, from: data)
      } catch {
        print(error)
      }
      return yearToRecords[year]
    }
    
    return nil
  }
  
  func recordsForYear(_ year: String, completion: @escaping ([Team : Record]?, Source) -> Void) {
    if let cachedRecords = cachedRecordsForYear(year) {
      completion(cachedRecords, .cache)
      return
    }
    
    NBA.shared.getStandings(year: year) { [weak self] (success, standings) in
      if let records = standings?.toTeamRecords() {
        self?.save(year: year, records: records)
        completion(records, .network)
      }
    }
  }
  
  func save(year: String, records: [Team : Record]) {
    yearToRecords[year] = records
    do {
      let data = try JSONEncoder().encode(records)
      UserDefaults.standard.set(data, forKey: year)
      UserDefaults.standard.synchronize()
    } catch {
      print(error)
    }
  }
  
  @objc func refreshCurrentRecords(completion: ((Bool) -> Void)? = nil) {
    let year = Date().nbaYear
    let oldRecords = cachedRecordsForYear(year)
    NBA.shared.getStandings { (success, standings) in
      guard success, let newRecords = standings?.toTeamRecords() else {
        completion?(false)
        return
      }
      
      self.save(year: year, records: newRecords)
      
      guard let member = Member.currentMember else {
        completion?(true)
        return
      }
      
      FirebaseInterface.getPools(member: member) { (result, error) in
        let pools = result ?? []
        let completePools = pools.filter { $0.isComplete }
        completePools.forEach { UNUserNotificationCenter.addDraftPickNotification(pool: $0) }
        
        // save rankings
        var poolRankings = [String : Int]()
        for pool in completePools {
          pool.membersSortedByWinPercentage { sortedMembers in
            poolRankings[pool.id] = sortedMembers.firstIndex(of: member)
          }
        }
        
        // update standings
        newRecords.keys.forEach {
          let id = $0
          let record = newRecords[id]!
          
          // add notification for change in team record
          if let oldRecord = oldRecords?[id], oldRecord != record {
            for pool in completePools {
              if pool.teamsForMember(member).contains(id) {
                let isWinning = (record.wins - oldRecord.wins) > (record.losses - oldRecord.losses)
                if (pool.dateCreated ?? Date()).nbaYear == Date().nbaYear {
                  UNUserNotificationCenter.addNotificationForTeam(id, record:record, winning: isWinning)
                }
                break
              }
            }
          }
        }
        
        self.delegate?.didUpdateRecords(self, forYear: year)
        
        // check for changes in rankings
        for pool in completePools {
          if (pool.dateCreated ?? Date()).nbaYear == Date().nbaYear {
            pool.membersSortedByWinPercentage { members in
              if let newRank = members.firstIndex(of: member), let oldRank = poolRankings[pool.id], newRank != oldRank {
                UNUserNotificationCenter.addNotificationForPool(pool, rank: newRank + 1, rising: newRank < oldRank)
              }
            }
          }
        }
        
        completion?(true)
      }
    }
  }
}

protocol RecordsDelegate: AnyObject {
  func didUpdateRecords(_ records: Records, forYear: String)
}
