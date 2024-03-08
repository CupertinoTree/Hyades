//
//  SearchVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 07/07/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    //MARK: - IBOutlets
    @IBOutlet weak var dismissBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - IBActions
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Variables
    let data = Observatory.catalogue.filter({ $0.name != nil })
    
    var delegate: PushToManager?
    
    override var prefersStatusBarHidden: Bool { return true }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        
        dismissBtn.layer.cornerRadius = dismissBtn.frame.height/2
        dismissBtn.layer.masksToBounds = true
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    //MARK: - Data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = data[indexPath.row].name
        return cell
    }
    
    //MARK: - Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.loadPushTo()
        PushToViewController.target = self.data[indexPath.row]
        dismiss(animated: true, completion: { self.delegate?.loadPushToVC() })
    }
    
}

protocol PushToManager {
    func loadPushTo()
    func loadPushToVC()
}
