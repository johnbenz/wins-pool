//
//  Pool.swift
//  NBA Wins Pool, Inc.
//
//  Created by John Benz Jessen on 9/3/16.
//  Copyright © 2016 NBA Wins Pool, Inc. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct Pool: Codable {
  struct Pick: Codable {
    let number: Int
    let member: Member
    var teamId: String?
    var didNotifyMember: Bool?
  }
  
  let id: String
  let name: String
  let size: Int
  var idToMember = [String : Member]()
  var numberToPick = [Int : Pick]()
  let dateCreated: Date?
  
  static var dateFormatter = ISO8601DateFormatter()
  
  init(id: String, name: String, size: Int, members: [Member]) {
    self.id = id
    self.name = name
    self.size = size
    self.dateCreated = Date()
    members.forEach { self.idToMember[$0.id] = $0 }
  }
  
  mutating func addMember(_ member: Member) {
    guard members.count < size else { return }
    idToMember[member.id] = member
    
    guard members.count == size else { return }
    guard let memberIndices = Pool.sizeToDraftOrder[size] else { return }
    
    let randomMembers = members.shuffled()
    let memberPickOrder = memberIndices.map { randomMembers[$0-1] }
    for (index, member) in memberPickOrder.enumerated() {
      let draftNumber = index+1
      numberToPick[draftNumber] = Pick(number: draftNumber, member: member, teamId: nil)
    }
  }
}

extension Pool {
  static let sizeToDraftOrder = [
    2: [1, 2, 2, 1, 2, 1, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1, 1, 2, 2, 1, 2, 1],
    3: [1, 2, 3, 3, 2, 1, 2, 1, 3, 3, 2, 1, 1, 2, 3, 3, 2, 1, 1, 2, 3, 3, 2, 1, 2, 1, 3, 3, 2, 1],
    5: [1, 2, 3, 4, 5, 5, 4, 3, 2, 1, 1, 2, 3, 5, 4, 5, 4, 3, 2, 1, 4, 2, 3, 1, 5, 5, 4, 3, 2, 1],
    6: [1, 2, 3, 4, 5, 6, 6, 5, 4, 3, 2, 1, 5, 2, 4, 3, 6, 1, 5, 6, 4, 2, 3, 1, 6, 5, 4, 3, 2, 1],
  ]
  
  var picksSortedByDraftNumber: [Pick] {
    return picks?.sorted { $0.number < $1.number } ?? []
  }
  
  var currentPick: Pick? {
    for pick in picksSortedByDraftNumber {
      if pick.team == nil {
        return pick
      }
    }
    return nil
  }
  
  var isComplete: Bool {
    return picksSortedByDraftNumber.last?.team != nil
  }
  
  func picksForMember(_ member: Member) -> [Pick]? {
    return picks?.filter { $0.member == member }
  }
  
  func teamsForMember(_ member: Member) -> Set<Team> {
    return Set(picks?.filter { $0.member == member }.compactMap { $0.team } ?? [])
  }
  
  func recordForMember(_ member: Member, completion: @escaping (Record) -> Void) {
    let teams = teamsForMember(member)
    Records.shared.recordsForYear((dateCreated ?? Date()).nbaYear) { records, _ in
      var result = Record.zero
      guard let r = records else {
        completion(result)
        return
      }
      teams.forEach {
        result = result + (r[$0] ?? .zero)
      }
      completion(result)
    }
  }
}

extension Pool.Pick {
  var team: Team? {
    guard let id = teamId else { return nil }
    return Team(rawValue: id)
  }
}

extension Pool {
  var members: [Member] {
    return Array(idToMember.values)
  }
  
  var picks: [Pick]? {
    guard !numberToPick.isEmpty else { return nil }
    return Array(numberToPick.values).sorted { $0.number < $1.number }
  }
  
  var isFull: Bool {
    return size == members.count
  }
  
  func membersSortedByWinPercentage(completion: @escaping ([Member]) -> Void) {
    var memberToRecord = [Member : Record]()
    
    let group = DispatchGroup()
    members.forEach {
      let member = $0
      group.enter()
      self.recordForMember(member) { record in
        memberToRecord[member] = record
        group.leave()
      }
    }
    group.notify(queue: .main) {
      completion(members.sorted { memberToRecord[$0]!.percentage > memberToRecord[$1]!.percentage })
    }
  }
  
  var teamsRemaining: Set<Team> {
    let selectedTeams = picks?.compactMap { $0.team } ?? []
    return Set(Set(Team.allCases).subtracting(selectedTeams))
  }
}

extension Pool: Equatable {
  static func ==(poolA: Pool, poolB: Pool) -> Bool {
    return poolA.id == poolB.id
  }
}

extension Pool: Hashable {
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension Pool.Pick: Equatable {
  static func == (lhs: Pool.Pick, rhs: Pool.Pick) -> Bool {
    return lhs.member == rhs.member && lhs.teamId == rhs.teamId && lhs.number == rhs.number
  }
}

