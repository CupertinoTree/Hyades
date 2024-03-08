//
//  ModalVC.swift
//  Hyades
//
//  Created by Ronan Clemente on 26/06/2020.
//  Copyright © 2020 Ronan Clemente. All rights reserved.
//

import UIKit

class ModalViewController: UIViewController, UIViewControllerTransitioningDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var descriptionView: UITextView!
    @IBOutlet weak var calibrateBtn: UIButton!
    
    //MARK: - IBActions
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextClicked() {
        self.dismiss(animated: true, completion: {
            self.delegate?.loadCalibration()
        })
    }
    
    //MARK: - Variables
    var nextClicks = 0
    var delegate: CalibrationManager?

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
    
    //MARK: - View life cycle
    override func viewDidLoad() {
        self.calibrateBtn.layer.cornerRadius = 15
    }
    
    //MARK: - Delegate implementation
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting)
    }
    
}

class PresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = UIScreen.main.bounds
        let size = CGSize(width: bounds.width, height: bounds.height/2.25)
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
    
    let dimmingView: UIView = {
        let dimmingView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        return dimmingView
    }()

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        let superview = presentingViewController.view!
        superview.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            dimmingView.topAnchor.constraint(equalTo: superview.topAnchor)
        ])

        dimmingView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()

        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }
    
}

protocol CalibrationManager {
    func loadCalibration()
}
