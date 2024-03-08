//
//  Observatory.swift
//  Hyades
//
//  Created by Ronan Clemente on 28/03/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit

class Observatory {
    
    static var deviceCalibrated = false
    
    static var earth = Satellite()
    static var earthHeliocentricXYZ : (x: Double, y: Double, z: Double) = (x: 0, y: 0, z: 0)
    static var catalogue : [DeepSkyObject] = []
    static var optimumDate = Double()
    
    private static let eclipticObliquityAtEpoch = 0.4090928042223323
    static let cosEc = cos(eclipticObliquityAtEpoch)
    static let sinEc = sin(eclipticObliquityAtEpoch)
    
    typealias Eyepiece = (fov: CGFloat, length: CGFloat)
    static var eyepieces : [Eyepiece] = [(fov: 52, length: 26), (fov: 52, length: 10), (fov: 52, length: 4), (fov: 70, length: 38)]
    static var selectedEyepiece : Eyepiece = (fov: 52, length: 26)
    
    static var barlows : [CGFloat] = [1, 2, 3, 5]
    static var selectedBarlow : CGFloat = 1
    
    static var tubes : [CGFloat] = [1200]
    static var selectedTube : CGFloat = 1200
    
    static func loadCatalogue() {
        
        if let path = Bundle.main.path(forResource: "Stars", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let starsArray = jsonResult as? Array<Dictionary<String, AnyObject>> {
                    for star in starsArray {
                        
                        let name = star["Name"] as? String
                        let desc = star["Description"] as? String ?? ""
                        let ra = Double(star["RA"] as? String ?? "0") ?? 0
                        let dec = star["DEC"] as? Double ?? 0
                        let mag = Double(star["MAG"] as? String ?? "0") ?? 0
                        let color = star["Color"] as? String ?? "Blanc"
                        
                        catalogue.append(DeepSkyObject(name, description: desc, .star, RA: ra, DEC: dec, magnitude: mag, color: color))
                    }
                }
              } catch {
                   print(error)
              }
        } else {
            print("Couldn't find file")
        }
        
        if let path = Bundle.main.path(forResource: "Planets2020", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                
                if let monthsArray = jsonResult as? Dictionary<String, Dictionary<String, Dictionary <String, Double>>> {
                    
                    let currentJ2000Days = Date().daysFromJ2000()
                    let optimumData = monthsArray.sorted(by: { abs(Double($0.key)!-currentJ2000Days) < abs(Double($1.key)!-currentJ2000Days) }).first!
                    optimumDate = Double(optimumData.key)!
                    
                    for (planetName, planetData) in optimumData.value {
                        
                        let planet = Satellite(planetName, type: .planet, i: planetData["inclination"]!, lAN: planetData["longitudeOfAscendingNode"]!, lOP: planetData["longitudeOfPerihelion"]!, mD: planetData["meanDistance"]!, dM: planetData["dailyMotion"]!, e: planetData["eccentricity"]!, mA: planetData["meanAnomaly"]!)
                        
                        if planetName == "Terre" { earth = planet } else { catalogue.append(planet) }
                    }
                    
                }
              } catch {
                   print(error)
              }
        } else {
            print("Couldn't find file")
        }
        
    }
    
    //Sizes given in A.U.
    static let sizeOfPlanets = ["Mercure": 1.63083872e-5, "Vénus": 4.04537843e-5, "Mars": 2.27021948e-5, "Jupiter": 0.000477894503, "Saturne": 0.000402866697, "Uranus": 0.000170851362, "Neptune": 0.000165537115]
    
}

class Satellite: DeepSkyObject {
    
    ///Angles are expressed in radians
    var inclination, longitudeOfAscendingNode, longitudeOfPerihelion, dailyMotion, meanAnomaly: Double
    
    ///Distances are expressed in Astronomical Units
    var meanDistance: Double
    
    var eccentricity: Double
    
    var distanceToEarth: Double = 0
    
    init(_ name: String, type: DeepSkyObjectType, i: Double, lAN: Double, lOP: Double, mD: Double, dM: Double, e: Double, mA: Double) {
        
        self.inclination = i
        self.longitudeOfAscendingNode = lAN
        self.longitudeOfPerihelion = lOP
        self.meanDistance = mD
        self.dailyMotion = dM
        self.eccentricity = e
        self.meanAnomaly = mA
        
        super.init()
        
        self.name = name
        self.description = name
        self.type = type
    }
    
    override init() {
        self.inclination = 0
        self.longitudeOfAscendingNode = 0
        self.longitudeOfPerihelion = 0
        self.meanDistance = 0
        self.dailyMotion = 0
        self.eccentricity = 0
        self.meanAnomaly = 0
        
        super.init()
    }
    
    func loadPosition() {
        
        let planetHeliocentricXYZ = self.getHeliocentricXYZ()
        let planetGeocentricXYZ = (x: planetHeliocentricXYZ.x - Observatory.earthHeliocentricXYZ.x, y: planetHeliocentricXYZ.y - Observatory.earthHeliocentricXYZ.y, z: planetHeliocentricXYZ.z - Observatory.earthHeliocentricXYZ.z)
        
        let equatorialGeocentricXYZ = (x: planetGeocentricXYZ.x, y: planetGeocentricXYZ.y * Observatory.cosEc - planetGeocentricXYZ.z * Observatory.sinEc, z: planetGeocentricXYZ.y * Observatory.sinEc + planetGeocentricXYZ.z * Observatory.cosEc)
        
        self.rightAscension = atan(equatorialGeocentricXYZ.y/equatorialGeocentricXYZ.x)
        
        if equatorialGeocentricXYZ.x < 0 {
            self.rightAscension += .pi
        } else if equatorialGeocentricXYZ.y < 0 {
            self.rightAscension += 2 * .pi
        }
        
        self.declination = atan(equatorialGeocentricXYZ.z/sqrt(equatorialGeocentricXYZ.x.squared() + equatorialGeocentricXYZ.y.squared()))
        
        self.distanceToEarth = sqrt(equatorialGeocentricXYZ.x.squared() + equatorialGeocentricXYZ.y.squared() + equatorialGeocentricXYZ.z.squared())
    }
    
    func getHeliocentricXYZ() -> (x: Double, y: Double, z: Double) {
        
        let deltaTime = Date().daysFromJ2000() - Observatory.optimumDate
        var currentMeanAnomaly = self.meanAnomaly + deltaTime * self.dailyMotion
        
        while currentMeanAnomaly < 0 { currentMeanAnomaly += 2 * .pi }
        while currentMeanAnomaly > 2 * .pi { currentMeanAnomaly -= 2 * .pi }
        
        var trueAnomaly = getTrueAnomaly(meanAnomaly: currentMeanAnomaly, eccentricity: self.eccentricity)
        if trueAnomaly < 0 { trueAnomaly += 2 * .pi }
        
        //The distance from the planet to the focus of the ellipse
        let radiusVector = self.meanDistance * (1 - pow(eccentricity, 2)) / (1 + eccentricity * cos(trueAnomaly))
        
        let cosInc = cos(inclination)
        let sumCos = cos(trueAnomaly + longitudeOfPerihelion - longitudeOfAscendingNode)
        let sumSin = sin(trueAnomaly + longitudeOfPerihelion - longitudeOfAscendingNode)
        let sinLan = sin(longitudeOfAscendingNode)
        let cosLan = cos(longitudeOfAscendingNode)
        
        //Find heliocentric coordinates
        let heliocentricX = radiusVector * (cosLan * sumCos - sinLan * sumSin * cosInc)
        let heliocentricY = radiusVector * (sinLan * sumCos + cosLan * sumSin * cosInc)
        let heliocentricZ = radiusVector * sumSin * sin(inclination)
        
        return (heliocentricX, heliocentricY, heliocentricZ)
    }
    
    private func getTrueAnomaly(meanAnomaly: Double, eccentricity: Double) -> Double {
        let firstPass = (2 * eccentricity - 0.25 * pow(eccentricity, 3)) * sin(meanAnomaly)
        let secondPass = (1.25 * pow(eccentricity, 2)) * sin(2 * meanAnomaly)
        let thirdPass = (1.08 * pow(eccentricity, 3)) * sin(3 * meanAnomaly)
        return meanAnomaly + firstPass + secondPass + thirdPass
    }
    
}

class DeepSkyObject {
    
    ///Angles are expressed in radians
    var rightAscension, declination : Double
    var magnitude: Double
    
    var name: String?
    var description: String
    
    var color: UIColor
    
    var type: DeepSkyObjectType
    
    init(_ name: String? = nil, description: String, _ type: DeepSkyObjectType, RA: Double, DEC: Double, magnitude: Double, color: String) {
        self.rightAscension = RA
        self.declination = DEC
        self.name = name == "" ? nil : name
        self.description = description
        self.type = type
        self.magnitude = magnitude
        self.color = color == "Rouge" ? #colorLiteral(red: 1, green: 0.02417027152, blue: 0, alpha: 0.5036036532) : color == "Orange" ? #colorLiteral(red: 1, green: 0.3299812726, blue: 0, alpha: 0.5) : color == "Jaune" ? #colorLiteral(red: 1, green: 0.955133597, blue: 0, alpha: 0.5) : color == "Blanc" ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : #colorLiteral(red: 0, green: 0.3011080917, blue: 1, alpha: 0.5)
    }
    
    init() {
        self.rightAscension = 0
        self.declination = 0
        self.name = nil
        self.description = ""
        self.type = .star
        self.magnitude = 0
        self.color = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    }
    
    func brightness() -> Double { 2*tanh(pow(10, -self.magnitude/2.5)) }
    
}

enum DeepSkyObjectType { case star, nebulae, galaxy, cluster, planet }
