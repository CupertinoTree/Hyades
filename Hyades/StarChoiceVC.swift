//
//  CalibrationVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 30/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit
import AudioToolbox

class StarChoiceViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var firstStarView: UIView!
    
    @IBOutlet weak var secondStarView: UIView!
    @IBOutlet weak var secondStarLabel: UILabel!
    
    @IBOutlet weak var starPicker: UIPickerView!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBAction func nextPressed() {
        if isEnabled {
            guard let storyboard = storyboard else { return }
            present(storyboard.instantiateViewController(identifier: "calibrationVC"), animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Attention", message: "Sélectionnez l'étoile de votre choix.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            
            alert.setValue(NSAttributedString(string: alert.message!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium), NSAttributedString.Key.foregroundColor : uiColor]), forKey: "attributedMessage")
            alert.setValue(NSAttributedString(string: alert.title!, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.bold), NSAttributedString.Key.foregroundColor : uiColor]), forKey: "attributedTitle")
            
            alert.view.tintColor = uiColor
            self.present(alert, animated: true, completion: nil)
            return
        }
    }
    
    var brightStars = [DeepSkyObject]()
    
    var isEnabled = false
    
    var uiColor : UIColor { return SkyViewController.redMode ? #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1) : #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) }
    
    static var firstStar = DeepSkyObject()
    static var secondStar = DeepSkyObject()
    
    override func viewDidLoad() {
        
        brightStars = Observatory.catalogue.filter({ $0.name != nil && $0.type == .star })
        
        StarChoiceViewController.firstStar = brightStars.first(where: { $0.name == "Polaris" })!
        
        starPicker.delegate = self
        starPicker.dataSource = self
        
        nextBtn.layer.cornerRadius = 15
        nextBtn.layer.masksToBounds = true
        
        firstStarView.layer.cornerRadius = 15
        firstStarView.layer.masksToBounds = true
        
        secondStarView.layer.cornerRadius = 15
        secondStarView.layer.masksToBounds = true
        
        titleLabel.textColor = uiColor
        nextBtn.backgroundColor = uiColor
        firstStarView.backgroundColor = uiColor
        secondStarView.backgroundColor = uiColor
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if Observatory.deviceCalibrated {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return brightStars.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let name = row == 0 ? "Deuxième étoile" : brightStars[row - 1].name!
        
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.foregroundColor: uiColor])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let name = row == 0 ? "Deuxième étoile" : brightStars[row - 1].name!
        secondStarLabel.text = name
        
        if row == 0 { isEnabled = false; return }
        
        StarChoiceViewController.secondStar = brightStars[row - 1]
        isEnabled = true
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }

}
