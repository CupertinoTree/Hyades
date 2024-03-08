//
//  CalibrationVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 30/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit
import CoreMotion

class CalibrationViewController: UIViewController {
    
    @IBOutlet weak var returnBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descTxt: UITextView!
    
    @IBOutlet weak var firstStarView: UIView!
    @IBOutlet weak var firstStarName: UILabel!
    @IBOutlet weak var firstStarAlt: UILabel!
    @IBOutlet weak var firstStarAz: UILabel!
    @IBOutlet weak var firstStarIndicator: UIImageView!
    
    @IBOutlet weak var secondStarView: UIView!
    @IBOutlet weak var secondStarName: UILabel!
    @IBOutlet weak var secondStarAlt: UILabel!
    @IBOutlet weak var secondStarAz: UILabel!
    @IBOutlet weak var secondStarIndicator: UIImageView!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBAction func returnPressed() {
        if isEditingFirstStar {
            motionManager.stopDeviceMotionUpdates()
            self.dismiss(animated: true, completion: nil)
        } else {
            cancel()
        }
    }
    
    @IBAction func next() {
        if isEditingFirstStar {
            
            isEditingFirstStar = false
            CalibrationViewController.firstMeasureDate = Date()
            
            self.descTxt.text = "Centrez la deuxième étoile dans l'oculaire puis appuyez sur le bouton \"Terminer\"."
            self.nextBtn.setTitle("Terminer", for: .normal)
            self.firstStarIndicator.isHighlighted = true
            
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
                self.secondStarView.alpha = 1
            }
            
        } else {
            motionManager.stopDeviceMotionUpdates()
            Observatory.deviceCalibrated = true
            UIView.animate(withDuration: 0.25, animations: {
                self.secondStarIndicator.isHighlighted = true
            }, completion: {_ in
                self.dismiss(animated: true, completion: nil)
            })
        }
    }
    
    var uiColor : UIColor { return SkyViewController.redMode ? #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1) : #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) }
    var isEditingFirstStar = true
    
    let motionManager = CMMotionManager()
    
    static var firstMeasureDate = Date()
    static var firstAltitude = Double()
    static var firstAzimuth = Double()
    static var secondAltitude = Double()
    static var secondAzimuth = Double()
    
    override func viewDidLoad() {
        
        motionManager.deviceMotionUpdateInterval = 0.01
        
        returnBtn.backgroundColor = uiColor
        returnBtn.layer.cornerRadius = returnBtn.frame.height/2
        returnBtn.layer.masksToBounds = true
        
        titleLabel.textColor = uiColor
        descTxt.textColor = uiColor
        descTxt.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        
        firstStarName.text = StarChoiceViewController.firstStar.name!
        firstStarView.backgroundColor = uiColor
        firstStarView.layer.cornerRadius = 15
        firstStarView.layer.masksToBounds = true
        
        secondStarName.text = StarChoiceViewController.secondStar.name!
        secondStarView.backgroundColor = uiColor
        secondStarView.layer.cornerRadius = 15
        secondStarView.layer.masksToBounds = true
        
        nextBtn.backgroundColor = uiColor
        nextBtn.layer.cornerRadius = 15
        nextBtn.layer.masksToBounds = true
        
        motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { (data, error) in
            
            if error != nil {
                print(error!)
            } else {
                if data != nil {
                    
                    if self.isEditingFirstStar {
                        CalibrationViewController.firstAltitude = max(min(data!.attitude.pitch, .pi/2), -.pi/2)
                        self.firstStarAlt.text = CalibrationViewController.firstAltitude.toDM()
                        CalibrationViewController.firstAzimuth  = data!.attitude.yaw + .pi/2
                        if CalibrationViewController.firstAzimuth < 0 { CalibrationViewController.firstAzimuth += 2 * .pi }
                        self.firstStarAz.text = CalibrationViewController.firstAzimuth.toDM()
                    } else {
                        CalibrationViewController.secondAltitude = max(min(data!.attitude.pitch, .pi/2), -.pi/2)
                        self.secondStarAlt.text = CalibrationViewController.secondAltitude.toDM()
                        CalibrationViewController.secondAzimuth  = data!.attitude.yaw + .pi/2
                        if CalibrationViewController.secondAzimuth < 0 { CalibrationViewController.secondAzimuth += 2 * .pi }
                        self.secondStarAz.text = CalibrationViewController.secondAzimuth.toDM()
                    }
                }
            }
        }
        
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    func cancel() {
        
        isEditingFirstStar = true
        
        self.descTxt.text = "Prenez votre temps pour pointer Polaris, afin qu'elle soit bien au centre de l'oculaire le plus puissant que vous comptez utiliser. Dès que vous aurez réussi, appuyez sur le bouton \"Continuer\" au bas de l'écran."
        
        self.nextBtn.setTitle("Continuer", for: .normal)
        self.firstStarIndicator.isHighlighted = false
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
            self.secondStarView.alpha = 0
        }
    }
    
    var fontSize: CGFloat { (self.view.frame.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom) / 40 }
    
}
