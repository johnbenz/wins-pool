//
//  TeamsViewController.swift
//  NBA Wins Pool, Inc.
//
//  Created by John Benz Jessen on 10/13/16.
//  Copyright © 2016 NBA Wins Pool, Inc. All rights reserved.
//

import UIKit

class TeamsViewController: UITableViewController {
  
  var pool: Pool!
  var member: Member!
  var picks = [Pool.Pick]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "\(member.name)'s Teams"
    let nib = UINib(nibName: "DraftTableViewCell", bundle: nil)
    tableView.register(nib, forCellReuseIdentifier: "DraftTableViewCell")
    navigationController?.addBackButton(viewController: self)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    Records.shared.delegate = self
    reloadData()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    Records.shared.delegate = nil
  }
  
  @objc func reloadData() {
    let p = pool
    let m = member
    Records.shared.recordsForYear((pool.dateCreated ?? Date()).nbaYear) { [weak self] records, _ in
      guard let records else { return }
      
      func recordForPick(_ pick: Pool.Pick) -> Record? {
        guard let team = pick.team else { return nil }
        return records[team]
      }
      
      self?.picks = p!.picksForMember(m!)?.sorted { recordForPick($0)?.percentage ?? 0 > recordForPick($1)?.percentage ?? 0 } ?? []
      self?.tableView.reloadData()
    }
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return picks.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DraftTableViewCell", for: indexPath) as! DraftTableViewCell
    
    let pick = picks[indexPath.row]
    cell.set(team: pick.team, date: pool.dateCreated ?? Date())
    cell.pick.text = "Pick: \(pick.number)"
    
    return cell
  }
}

extension TeamsViewController: RecordsDelegate {
  func didUpdateRecords(_ records: Records, forYear: String) {
    reloadData()
  }
}
