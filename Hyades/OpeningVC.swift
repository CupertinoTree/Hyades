//
//  OpeningVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 30/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit

class OpeningViewController: UIViewController {
    
    static var redMode = false
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var firstText: UITextView!
    @IBOutlet weak var toggleView: UIView!
    @IBOutlet weak var redSwitch: UISwitch!
    @IBOutlet weak var secondText: UITextView!
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBAction func toggledRed() {
        if redSwitch.isOn {
            titleLabel.textColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            firstText.textColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            toggleView.backgroundColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            redSwitch.thumbTintColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            secondText.textColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            nextBtn.backgroundColor = #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1)
            
            OpeningViewController.redMode = true
        } else {
            titleLabel.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            firstText.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            toggleView.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            redSwitch.thumbTintColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            secondText.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            nextBtn.backgroundColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            
            OpeningViewController.redMode = false
        }
    }
    
    override func viewDidLoad() {
        
        toggleView.layer.cornerRadius = 10
        toggleView.layer.masksToBounds = true
        
        redSwitch.layer.cornerRadius = 16
        
        nextBtn.layer.cornerRadius = 15
        nextBtn.layer.masksToBounds = true
        
        firstText.font? = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        secondText.font? = UIFont.systemFont(ofSize: fontSize, weight: .bold)
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    var fontSize: CGFloat { (self.view.frame.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom) / 40 }
    
}
