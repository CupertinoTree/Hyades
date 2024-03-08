//
//  PushToVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 08/07/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit

class PushToViewController: UIViewController, UIViewControllerTransitioningDelegate, PushToReceiver, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    //MARK: - IBOutlets
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var azimuthArrow: UIImageView!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var altitudeArrow: UIImageView!
    
    //MARK: - IBActions
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: { self.delegate?.closePushTo() })
    }
    
    @IBAction func selectorChanged() {
        sectionNbr = segmentedControl.selectedSegmentIndex
        collectionView.reloadData()
    }
    
    //MARK: - Variables
    static var target = DeepSkyObject()
    var delegate: PushToEmitter?
    var sectionNbr = 0
    var selectedCell = CollectionCell() {
        willSet {
            selectedCell.contentView.backgroundColor = #colorLiteral(red: 0.2194786269, green: 0.2194786269, blue: 0.2194786269, alpha: 1)
        }
        
        didSet {
            selectedCell.contentView.backgroundColor = #colorLiteral(red: 0.4598647992, green: 0.4598647992, blue: 0.4598647992, alpha: 1)
        }
    }
    
    var selection = [0, 0, 0]
    
    //MARK: - Functions
    func updateAltAz(alt: String, az: String) {
        altitudeLabel.text = "Altitude : " + alt
        azimuthLabel.text = "Azimuth : " + az
        
        if alt.first == "-" {
            altitudeArrow.image = UIImage(systemName: "arrow.up.circle.fill")
        } else {
            altitudeArrow.image = UIImage(systemName: "arrow.down.circle.fill")
        }
        
        if az.first == "-" {
            azimuthArrow.image = UIImage(systemName: "arrow.left.circle.fill")
        } else {
            azimuthArrow.image = UIImage(systemName: "arrow.right.circle.fill")
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        modalPresentationStyle = .custom
        modalTransitionStyle = .coverVertical
        transitioningDelegate = self
    }
    
    //MZRK: - View life cycle
    override func viewDidLoad() {
        collectionView.layer.cornerRadius = 10
        self.label.text = PushToViewController.target.name ?? PushToViewController.target.description
        self.selection = [Observatory.eyepieces.firstIndex(where: { $0 == Observatory.selectedEyepiece }) ?? 0, Observatory.barlows.firstIndex(where: { $0 == Observatory.selectedBarlow }) ?? 0, Observatory.tubes.firstIndex(where: { $0 == Observatory.selectedTube }) ?? 0]
        collectionView.dataSource = self
        collectionView.delegate   = self
    }
    
    //MARK: - Delegate implementation
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PushToPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sectionNbr == 0 ? Observatory.eyepieces.count : sectionNbr == 1 ? Observatory.barlows.count : Observatory.tubes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? CollectionCell {
            cell.contentView.backgroundColor = #colorLiteral(red: 0.2194786269, green: 0.2194786269, blue: 0.2194786269, alpha: 1)
            if indexPath.row == selection[sectionNbr] { selectedCell = cell }
            let source = sectionNbr == 0 ? Observatory.eyepieces.map({ $0.length }) : sectionNbr == 1 ? Observatory.barlows : Observatory.tubes
            cell.label.text = (sectionNbr == 1 ? "x" : "") + "\(source[indexPath.row])" + (sectionNbr == 1 ? "" : "mm")
            cell.layer.cornerRadius = 10
            cell.layer.masksToBounds = true
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height * 2, height: collectionView.frame.height * 0.9)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selection[sectionNbr] = indexPath.row
        selectedCell = collectionView.cellForItem(at: indexPath) as! CollectionCell
        
        switch sectionNbr {
            case 0: Observatory.selectedEyepiece = Observatory.eyepieces[indexPath.row]
            case 1: Observatory.selectedBarlow = Observatory.barlows[indexPath.row]
            case 2: Observatory.selectedTube = Observatory.tubes[indexPath.row]
            default: break
        }
        
        delegate?.updateFOV()
    }
    
}

class PushToPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = UIScreen.main.bounds
        let size = CGSize(width: bounds.width, height: bounds.height - 50 - bounds.width)
        let origin = CGPoint(x: bounds.midX - size.width / 2, y: bounds.maxY - size.height)
        return CGRect(origin: origin, size: size)
    }

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

        presentedView?.autoresizingMask = [
            .flexibleTopMargin,
            .flexibleBottomMargin,
            .flexibleLeftMargin,
            .flexibleRightMargin
        ]

        presentedView?.translatesAutoresizingMaskIntoConstraints = true
        
        presentedView?.layer.cornerRadius = 20
    }
    
}

protocol PushToEmitter {
    func updateFOV()
    func closePushTo()
}

protocol PushToReceiver {
    func updateAltAz(alt: String, az: String)
}

class CollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var label: UILabel!
    
}
