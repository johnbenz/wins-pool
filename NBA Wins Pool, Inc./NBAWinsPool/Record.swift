//
//  Record.swift
//  Wins Pool
//
//  Created by John Jessen on 10/24/25.
//  Copyright © 2025 NBA Wins Pool, Inc. All rights reserved.
//

import UIKit

struct Record: Codable {
  let wins: Int
  let losses: Int
  
  var percentage: Double {
    if wins + losses == 0 {
      return 0
    }
    return Double(wins) / Double(wins + losses)
  }
  
  var asString: String {
    return "\(wins)-\(losses)"
  }
  
  public static func +(lhs: Record, rhs: Record) -> Record {
    return Record(wins: lhs.wins + rhs.wins, losses: lhs.losses + rhs.losses)
  }
  
  static let zero = Record(wins: 0, losses: 0)
}

extension Record: Equatable {
  static func ==(lhs: Record, rhs: Record) -> Bool {
    return lhs.wins == rhs.wins && lhs.losses == rhs.losses
  }
}

extension Record: CustomStringConvertible {
  var description: String {
    return "\(wins)-\(losses) (\(percentage))"
  }
}
