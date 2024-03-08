//
//  DeepSkyExtension.swift
//  Hyades
//
//  Created by Ronan Clemente on 28/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import SceneKit
import UIKit
import Foundation

extension SCNNode {
    
    func getRadius() -> Double {
        guard let geometry = self.geometry as! SCNSphere? else { return 0 }
        return Double(geometry.radius)
    }
    
    func loadSky() {
        
        for object in Observatory.catalogue {
            
            let node = SCNNode()
            node.name = object.name
            
            var radius: Double = 0
            var distance: Double = 0
            
            if object.type == .star {
                radius = 0.005 * (1 + object.brightness())
                distance = getRadius() - 1
                SkyViewController.starsNodes.append(node)
            } else if object.type == .planet {
                if Observatory.earthHeliocentricXYZ == (x: 0, y: 0, z: 0) {
                    Observatory.earthHeliocentricXYZ = Observatory.earth.getHeliocentricXYZ()
                }
                let planet = (object as! Satellite)
                SkyViewController.movingNodes.append((object: planet, node: node))
                
                planet.loadPosition()
                
                distance = getRadius() - 1.5
                radius = 0.01 + 10 * (Observatory.sizeOfPlanets[planet.name!]! * distance) / planet.distanceToEarth
            }
            
            node.geometry = SCNSphere(radius: CGFloat(radius))
            node.geometry?.firstMaterial?.diffuse.contents = object.type == .planet ? UIImage(named: object.name!)! : object.color
            node.geometry?.firstMaterial?.emission.contents = object.color
            
            if object.type == .planet {
                node.geometry?.firstMaterial?.multiply.contents = #colorLiteral(red: 0.01955148964, green: 0.01955148964, blue: 0.01955148964, alpha: 1)
            }
            
            node.position = SkyViewController.getXYZfrom(RA: object.rightAscension, DEC: object.declination, distance: distance)
            node.eulerAngles = SCNVector3(x: Float(object.declination), y: Float(object.rightAscension), z: 0)
            self.addChildNode(node)
            
            if object.name != nil {
                SkyViewController.namedNodes.append(node)
            }
            
        }
        
    }
    
}

extension Date {

    func daysFromJ2000() -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return self.timeIntervalSince(formatter.date(from: "01/01/2000 12:00:00")!)/86400
    }

    func toUTCDecHours() -> Double {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = formatter.string(from: self)
        
        let dateElements = date.split(separator: ":")
        
        let hours = Int(dateElements[0])!
        let min   = Int(dateElements[1])!
        let sec   = Int(dateElements[2])!
        return Double(hours) + Double(min)/60 + Double(sec)/3600
    }

}

extension Double {
    
    func squared() -> Double { self * self }
    
    func toDegrees() -> Double { Double(GLKMathRadiansToDegrees(Float(self))) }
    func toRadians() -> Double { Double(GLKMathDegreesToRadians(Float(self))) }
    
    func toDM() -> String {
        let degCheck = self.toDegrees().isNaN ? 0 : abs(self.toDegrees())
        let deg = Int(abs(degCheck))
        let min = Int((degCheck - Double(deg)) * 60)
        
        let roundM = abs(min) < 10
        
        return (self < 0 ? "-" : "") + "\(deg)° \(roundM ? "0" : "")\(abs(min))'"
    }
    
    func toDMS() -> String {
        let degCheck = self.toDegrees().isNaN ? 0 : abs(self.toDegrees())
        let deg = Int(abs(degCheck))
        let min = Int((degCheck - Double(deg)) * 60)
        let sec = Int((degCheck - Double(deg) - Double(min)/60) * 3600)
        
        let roundM = abs(min) < 10
        let roundS = abs(sec) < 10
        
        return (self < 0 ? "-" : "") + "\(deg)° \(roundM ? "0" : "")\(abs(min))' \(roundS ? "0" : "")\(abs(sec))''"
    }
    
    func toHMS() -> String {
        let hours = self.toDegrees() / 15
        let min = abs((hours - Double(Int(hours))) * 60)
        let sec = (min - Double(Int(min))) * 60
        
        let roundM = min < 10
        let roundS = sec < 10
        
        return "\(Int(hours))h \(roundM ? "0" : "")\(Int(min))m \(roundS ? "0" : "")\(Int(sec))s"
    }
    
}

extension Float {
    var isNegative : Bool { return self < 0 }
    func squared() -> Float { self * self }
}

extension CGFloat { func squared() -> CGFloat { self * self } }

infix operator • : MultiplicationPrecedence

extension SCNVector3 {
    
    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        
        let x = (left.y * right.z) - (left.z * right.y)
        let y = (left.z * right.x) - (left.x * right.z)
        let z = (left.x * right.y) - (left.y * right.x)
        
        return SCNVector3(x, y, z)
    }
    
    static func • (left: SCNVector3, right: SCNVector3) -> Float {
        return left.x * right.x + left.y * right.y + left.z * right.z
    }
    
    func normalized() -> Float {
        let product = self.x.squared() + self.y.squared() + self.z.squared()
        return sqrt(product)
    }
    
}

class Plane {
    
    var normalVector: SCNVector3
    
    init(_ vector1: SCNVector3, _ vector2: SCNVector3, _ vector3: SCNVector3) {
        
        let vector12 = vector2 - vector1
        let vector13 = vector3 - vector1
        
        self.normalVector = vector12 * vector13
        
    }
    
    init(normalVector: SCNVector3) {
        self.normalVector = normalVector
    }
    
    func angleWith(_ plane: Plane) -> Float {
        
        let cosine = abs(self.normalVector • plane.normalVector) / (self.normalVector.normalized() * plane.normalVector.normalized())
        
        let sign: Float = (self.normalVector.z * plane.normalVector.x) - (self.normalVector.x * plane.normalVector.z) < 0 ? -1 : 1
        
        return sign * acos(cosine)
        
    }
    
}
