//
//  GameViewController.swift
//  Hyades
//
//  Created by Ronan Clemente on 26/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class SkyViewController: UIViewController, SCNSceneRendererDelegate, CalibrationManager, PushToManager, PushToEmitter {
    
    //MARK: - IBOutlets
    @IBOutlet weak var panModeLabel: UILabel!
    @IBOutlet weak var panModeBtn: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var paramBtn: UIButton!
    
    //MARK: - IBActions
    @IBAction func panModeDidChange(_ sender: UIButton) {
        
        sender.setImage(UIImage(systemName: compassMode ? "location.circle.fill" : "location.circle"), for: .highlighted)
        compassMode = !compassMode
        sender.setImage(UIImage(systemName: compassMode ? "location.circle.fill" : "location.circle"), for: .normal)
        
        panModeLabel.text = compassMode ? "Mode Boussole" : "Mode tactile"
        
        UIView.animate(withDuration: 0.5, animations: { self.panModeLabel.alpha = 1 }, completion: {_ in UIView.animate(withDuration: 0.5, delay: 1, animations: { self.panModeLabel.alpha = 0 }) })
        
        if compassMode {
            panGesture.isEnabled = false
            motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: .main) { [self] (data, error) in
                if error != nil {
                    print(error!)
                } else {
                    if data != nil {
                        
                        self.altitude = Float(max(min(.pi/2, data!.attitude.pitch), -.pi/2))
                        self.azimuth  = Float(data!.attitude.yaw + .pi/2)
                        
                        self.cameraNode.runAction(SCNAction.rotateTo(x: CGFloat(self.altitude), y: CGFloat(self.azimuth < 0 ? self.azimuth + 2 * .pi : self.azimuth), z: 0, duration: 0.1, usesShortestUnitArc: true))
                        
                        if self.pushToEnabled, let targetNode = SkyViewController.namedNodes.first(where: { $0.name == PushToViewController.target.name }) {
                            
                            let deltaAlt = self.altitude - asin(targetNode.worldPosition.y / targetNode.worldPosition.normalized())
                            
                            var deltaAz = self.azimuth - atan(targetNode.worldPosition.x / targetNode.worldPosition.z) + (targetNode.worldPosition.z > 0 ? .pi : 0)
                            
                            //On remap deltaAz dans [-.pi ; .pi]
                            deltaAz = deltaAz < -.pi ? 2 * .pi - deltaAz : deltaAz > .pi ? -2 * .pi + deltaAz : deltaAz
                            
                            self.delegate?.updateAltAz(alt: Double(deltaAlt).toDM(), az: Double(deltaAz).toDM())
                        }
                    }
                }
            }
        } else {
            motionManager.stopDeviceMotionUpdates()
            panGesture.isEnabled = true
        }
        
    }
    
    @IBAction func search() {
        if Observatory.deviceCalibrated {
            guard let searchVC = storyboard?.instantiateViewController(identifier: "SearchVC") as? SearchViewController else { return }
            searchVC.delegate = self
            present(searchVC, animated: true, completion: nil)
        } else {
            guard let modalVC = storyboard?.instantiateViewController(identifier: "ModalVC") as ModalViewController? else { return }
            modalVC.delegate = self
            self.present(modalVC, animated: true)
        }
    }
    
    @IBAction func settings() {
        
    }
    
    //MARK: - Variables
    static var redMode = false
    static var namedNodes = [SCNNode]()
    static var starsNodes = [SCNNode]()
    static var movingNodes = [(object: Satellite, node: SCNNode)]()
    
    var uiColor : UIColor { return SkyViewController.redMode ? #colorLiteral(red: 0.3294608161, green: 0, blue: 0.03175119489, alpha: 1) : #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) }
    
    var cameraNode = SCNNode()
    var skySphereNode = SCNNode()
    var mainNode = SCNNode()
    var sceneView = SCNView()
    
    var altitude = Float()
    var azimuth = Float()
    
    var previousFOV: CGFloat = 60
    
    var namedStarsLabels = [UILabel]()
    
    var panGesture = UIPanGestureRecognizer()
    let motionManager = CMMotionManager()
    
    var compassMode = false
    var pushToEnabled = false
    
    var delegate: PushToReceiver?

    //MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        panModeBtn.tintColor = uiColor
        panModeLabel.textColor = uiColor
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/sky.scn")!
        
        motionManager.deviceMotionUpdateInterval = 0.1
        
        // create and add a camera to the scene
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        //add the scene light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light!.type = .ambient
        ambientLight.position = SCNVector3Zero
        scene.rootNode.addChildNode(ambientLight)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        altitude = cameraNode.eulerAngles.y
        azimuth  = cameraNode.eulerAngles.x
        
        // retrieve the SCNView
        sceneView = self.view.subviews.first as! SCNView
        sceneView.delegate = self
        
        // set the scene to the view
        sceneView.scene = scene
        
        // configure the view
        sceneView.backgroundColor = UIColor.black
        
        // add a pan gesture recognizer
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(rotate(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        mainNode = scene.rootNode.childNode(withName: "mainNode", recursively: false)!
        
        skySphereNode = mainNode.childNode(withName: "skySphere", recursively: false)!
        
        skySphereNode.loadSky()
        
        for object in SkyViewController.namedNodes {
            let label = UILabel()
            label.frame.size = CGSize(width: 100, height: 50)
            label.alpha = 0
            label.text = object.name
            label.textAlignment = .center
            label.font = UIFont(name: "AvenirNext-Bold", size: 14)
            label.textColor = uiColor
            sceneView.addSubview(label)
            self.namedStarsLabels.append(label)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !Observatory.deviceCalibrated {
            guard let modalVC = storyboard?.instantiateViewController(identifier: "ModalVC") as ModalViewController? else { return }
            modalVC.delegate = self
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.present(modalVC, animated: true)
            }
        } else {
            if StarChoiceViewController.firstStar.name != nil {
                
                skySphereNode.eulerAngles = SCNVector3(.pi, StarChoiceViewController.firstStar.rightAscension, .pi)
                
                let deltaAlt = Float(CalibrationViewController.firstAltitude - StarChoiceViewController.firstStar.declination)
                
                mainNode.eulerAngles = SCNVector3(x: -deltaAlt, y: Float(CalibrationViewController.firstAzimuth) + .pi, z: 0)
            
                let firstStarPosition = skySphereNode.childNode(withName: StarChoiceViewController.firstStar.name!, recursively: false)!.worldPosition
                
                let desiredStarPosition = SkyViewController.getXYZfrom(Alt: CalibrationViewController.secondAltitude, Az: CalibrationViewController.secondAzimuth, distance: skySphereNode.getRadius() - 1)
            
                //recursiveRotation(firstStarPosition: firstStarPosition, desiredStarPosition: desiredStarPosition)
                
                //le ciel tourne sur lui-même en un jour sidéral
                self.skySphereNode.removeAllActions()
                self.skySphereNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2 * CGFloat.pi, z: 0, duration: 86164.1)))
                
                panModeDidChange(panModeBtn)
                
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        didMove()
    }
    
    func didMove() {
        
        func distance(_ x1: CGFloat, _ y1: CGFloat, _ x2: CGFloat, _ y2: CGFloat) -> CGFloat {
            sqrt((x2-x1).squared() + (y2-y1).squared())
        }
        
        for node in SkyViewController.namedNodes {
            
            if sceneView.isNode(node, insideFrustumOf: sceneView.pointOfView!) {
                
                let screenCoordinate = self.sceneView.projectPoint(node.worldPosition)
                
                DispatchQueue.main.async {
                    let middleOfView : (x: CGFloat, y: CGFloat) = (x: self.sceneView.frame.size.width/2, y: self.sceneView.frame.size.height/2)
                    let maxDistance = middleOfView.x
                    
                    if let label = self.namedStarsLabels.first(where: { $0.text == node.name }) {
                            
                        let finalDistance = min(distance(CGFloat(screenCoordinate.x), CGFloat(screenCoordinate.y), middleOfView.x, middleOfView.y), maxDistance)
                            
                        label.alpha = 2 * (1 - (finalDistance/maxDistance))
                        if label.alpha.isNaN { label.alpha = 0 }
                            
                        label.frame.origin = CGPoint(x: CGFloat(screenCoordinate.x) - label.frame.width/2, y: CGFloat(screenCoordinate.y) - label.frame.height)
                    }
                }
                
            } else {
                DispatchQueue.main.async {
                    if let label = self.namedStarsLabels.first(where: { $0.text == node.name }) {
                        label.alpha = 0
                    }
                }
            }
        }

    }
    
    func recursiveRotation(firstStarPosition: SCNVector3, desiredStarPosition: SCNVector3, _ loop: Int = 0) {
        
        if loop >= 10 { return }
            
        var secondStarPosition = skySphereNode.childNode(withName: StarChoiceViewController.secondStar.name!, recursively: false)!.worldPosition
        
        let firstLesserThanSecond = firstStarPosition.y - desiredStarPosition.y < 0 ? true : false
        
        var netAngle = Plane(firstStarPosition, secondStarPosition, SCNVector3Zero).angleWith(Plane(firstStarPosition, desiredStarPosition, SCNVector3Zero))
        
        mainNode.runAction(SCNAction.rotate(by: CGFloat((firstStarPosition.y - secondStarPosition.y < 0) != firstLesserThanSecond ? -netAngle + .pi : netAngle), around: firstStarPosition, duration: 0), completionHandler: {
                
                secondStarPosition = self.skySphereNode.childNode(withName: StarChoiceViewController.secondStar.name!, recursively: false)!.worldPosition
                    
                netAngle = Plane(firstStarPosition, secondStarPosition, SCNVector3Zero).angleWith(Plane(firstStarPosition, desiredStarPosition, SCNVector3Zero))
                
                if abs(netAngle) > 0.0001 {
                    self.recursiveRotation(firstStarPosition: firstStarPosition, desiredStarPosition: desiredStarPosition, loop + 1)
                }
        
            }
        )
        
    }
    
    @objc func rotate(_ recognizer: UIPanGestureRecognizer) {
        
        let translation = recognizer.translation(in: sceneView)
        
        let deltaAltitude = GLKMathDegreesToRadians(Float(translation.y))/5
        let deltaAzimuth  = GLKMathDegreesToRadians(Float(translation.x))/5
        
        let newAz = self.azimuth + deltaAzimuth
        
        cameraNode.runAction(SCNAction.rotateTo(x: CGFloat(max(min(altitude + deltaAltitude, .pi/2), -.pi/2)), y: CGFloat(newAz < 0 ? newAz + 2 * .pi : newAz), z: 0, duration: 0.1, usesShortestUnitArc: true))
        
        if recognizer.state == .ended {
            altitude  = max(min(altitude + deltaAltitude, .pi/2), -.pi/2)
            azimuth = newAz < 0 ? newAz + 2 * .pi : newAz
        }
    }
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
    
    static func getXYZfrom(RA: Double, DEC: Double, distance: Double) -> SCNVector3 {
        let x = -distance*sin(RA)*cos(DEC)
        let y =  distance*sin(DEC)
        let z = -distance*cos(DEC)*cos(RA)
        return SCNVector3(x: Float(x), y: Float(y), z: Float(z))
    }
    
    static func getXYZfrom(Alt: Double, Az: Double, distance: Double) -> SCNVector3 {
        return getXYZfrom(RA: Az, DEC: Alt, distance: distance)
    }
    
    //MARK: - CalibrationManager Delegate
    func loadCalibration() {
        guard let viewController = self.storyboard?.instantiateViewController(identifier: "StarChoiceVC") else { return }
        self.present(viewController, animated: true, completion: nil)
    }
    
    //MARK: - PushToManager Delegate
    func loadPushTo() {
        
        pushToEnabled = true
        
        if !compassMode { self.panModeDidChange(panModeBtn) }
        
        UIView.animate(withDuration: 1, animations: {
            self.view.frame = CGRect(x: 0, y: 40, width: self.view.frame.width, height: self.view.frame.width)
            self.view.layer.cornerRadius = self.view.frame.width/2
            self.view.layer.masksToBounds = true
            
            self.panModeBtn.isEnabled = false
            self.panModeBtn.isHidden  = true
            self.paramBtn.isEnabled   = false
            self.paramBtn.isHidden    = true
            self.searchBtn.isEnabled  = false
            self.searchBtn.isHidden    = true
        })
        
        let fov : CGFloat = (Observatory.selectedEyepiece.fov/(Observatory.selectedTube/Observatory.selectedEyepiece.length))/Observatory.selectedBarlow
        
        cameraNode.camera?.fieldOfView = fov
        previousFOV = fov
        
        for node in SkyViewController.starsNodes {
            if let geometry = node.geometry as? SCNSphere {
                geometry.radius *= fov/30
            }
        }
    }
    
    func loadPushToVC() {
        if let pushToVC = storyboard?.instantiateViewController(identifier: "PushToVC") as? PushToViewController {
            self.delegate = pushToVC
            pushToVC.delegate = self
            self.present(pushToVC, animated: true, completion: nil)
        }
    }
    
    //MARK: - PushToEmitter Delegate
    func updateFOV() {
        
        let fov : CGFloat = (Observatory.selectedEyepiece.fov/(Observatory.selectedTube/Observatory.selectedEyepiece.length))/Observatory.selectedBarlow
        
        cameraNode.camera?.fieldOfView = fov
        
        for node in SkyViewController.starsNodes {
            if let geometry = node.geometry as? SCNSphere {
                geometry.radius *= fov/previousFOV
            }
        }
        
        previousFOV = fov
    }
    
    func closePushTo() {
        pushToEnabled = false
        
        UIView.animate(withDuration: 1, animations: {
            self.view.frame = UIScreen.main.bounds
            self.view.layer.cornerRadius = 0
        })
        
        self.panModeBtn.isEnabled = true
        self.panModeBtn.isHidden  = false
        self.paramBtn.isEnabled   = true
        self.paramBtn.isHidden    = false
        self.searchBtn.isEnabled  = true
        self.searchBtn.isHidden    = false
        
        cameraNode.camera?.fieldOfView = 60
        
        for node in SkyViewController.starsNodes {
            if let geometry = node.geometry as? SCNSphere {
                geometry.radius /= previousFOV/30
            }
        }
        
        previousFOV = 60
    }

}
