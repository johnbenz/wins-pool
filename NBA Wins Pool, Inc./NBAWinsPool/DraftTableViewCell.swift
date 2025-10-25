//
//  DraftTableViewCell.swift
//  NBA Wins Pool, Inc.
//
//  Created by John Benz Jessen on 10/8/16.
//  Copyright © 2016 NBA Wins Pool, Inc. All rights reserved.
//

import UIKit

class DraftTableViewCell: UITableViewCell {
  @IBOutlet weak var pick: UILabel!
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var emoji: UILabel!
  @IBOutlet weak var record: UILabel!
  
  func set(team: Team?, date: Date) {
    record.text = nil
    if let t = team {
      label.text = t.name
      emoji.text = t.emoji
      contentView.backgroundColor = t.primaryColor
      
      team?.recordForDate(date) { [weak self] r in
        guard let r else { return }
        self?.record.text = "\(r.wins)-\(r.losses) (\(String(format: "%.1f", r.percentage*100.0)))"
      }
    } else {
      label.text = "--"
      emoji.text = "🏀"
      contentView.backgroundColor = UIColor.almostBlackGray
    }
  }  
}
