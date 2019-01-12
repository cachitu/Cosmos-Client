//
//  ToastAlertView.swift
//  IPSX
//
//  Created by Calin Chitu on 02/05/2018.
//
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

/*
How to use:
 
** Prequisites **
 - A table view or other full screen view to add this alert on top of it
 - An outlet to the table/other view's distance to top, to update animated when showing or hiding
 
** Add these properties to the view controller that supports the alert. **
 @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint! {
    didSet {
        topConstraint = topConstraintOutlet
    }
 }
 var toast: ToastAlertView?
 var topConstraint: NSLayoutConstraint?

** Link the outlet with the storyboard constraint **
 
** Implement the ToastAlertViewPresentable protocol in the view controller that presents it **
 extension ImplementingViewController: ToastAlertViewPresentable {
 
    func createToastAlert(onTopOf parentUnderView: UIView, text: String) {
        if self.toast == nil, let toastView = ToastAlertView(parentUnderView: parentUnderView, parentUnderViewConstraint: self.topConstraint, alertText:text) {
            self.toast = toastView
            view.insertSubview(toastView, belowSubview: topBarView)
        }
    }
 }
 
** In viewDidLyoutSubviews, call **
 override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createToastAlert(onTopOf: someView, text: "")
 }

** Display the toast with any of below **
 - toast?.showToastAlert() //will use the text passed at init
 - toast?.showToastAlert("Some text")
 - toast?.showToastAlert(autoHideAfter: 5)
 - toast?.showToastAlert("A text", autoHideAfter: 5)

** Hide the toast **
 - using the toast close button or
 - showing with dismiss timer or
 - toast?.hideToastAlert()
 
 */

import UIKit

public protocol ToastAlertViewPresentable {
    
    var toast: ToastAlertView? { get set }
    
    func createToastAlert(creatorView: UIView, holderUnderView: UIView, holderTopDistanceConstraint: NSLayoutConstraint, coveringView: UIView?) -> ToastAlertView?
}

extension ToastAlertViewPresentable {
    
    func createToastAlert(creatorView: UIView, holderUnderView: UIView, holderTopDistanceConstraint: NSLayoutConstraint, coveringView: UIView? = nil) -> ToastAlertView? {
        
        if self.toast == nil, let toastView = ToastAlertView(holderUnderView: holderUnderView, parentUnderViewConstraint: holderTopDistanceConstraint, alertText:"") {
            if let covering = coveringView {
                creatorView.insertSubview(toastView, belowSubview: covering)
            } else {
                creatorView.addSubview(toastView)
            }
            return toastView
        } else {
            return self.toast
        }
    }
}

public enum ToastAlertType {
    case error
    case info
    case success
    case deletePending
    case deleteConfirmed
    case validatePending
}

public class ToastAlertView: UIView {
    
    @IBOutlet weak var alertTextLabel: UILabel!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var dismissButton: UIButton!
    
    var onShow: (()->())?
    var onHide: (()->())?
    
    var currentText: String? { return alertTextLabel.text }
    
    private weak var view: UIView!
    private weak var parent: UIView!
    private weak var underViewTopConstraint: NSLayoutConstraint!

    private var initialParentConstraint:  CGFloat!
    private var hideTimer: Timer?
    private var extraOffest: CGFloat = 0
    
    public init?(holderUnderView: UIView, parentUnderViewConstraint: NSLayoutConstraint, alertText: String, topOffset: CGFloat = 0) {
        
        let frame = CGRect(x: 15, y: holderUnderView.frame.origin.y - 50, width: UIScreen.main.bounds.width - 30, height: 50)
        super.init(frame: frame)
        extraOffest = topOffset
        view = loadNib(withOwner: self)

        view.layer.cornerRadius = 5
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        view.layer.masksToBounds = false
        view.layer.shadowRadius = 3.0
        view.layer.shadowOpacity = 0.2

        parent = holderUnderView
        underViewTopConstraint  = parentUnderViewConstraint
        initialParentConstraint = parentUnderViewConstraint.constant
        alertTextLabel.text = alertText
        self.alpha = 0
        addSubview(view)
    }
    
    public override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        view = loadNib(withOwner: self)
        addSubview(view)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        view = loadNib(withOwner: self)
        addSubview(view)
    }
    
    @IBAction func closeButton(_ sender: UIButton) {
        updateInfoToastUI(visible: false)
    }
    
    public func showToastAlert(_ text: String? = "", autoHideAfter: Double = 0.0, type: ToastAlertType = .error, dismissable: Bool = true) {
        DispatchQueue.main.async {
            if type == .error { UIApplication.shared.endIgnoringInteractionEvents() }
            self.dismissButton.isHidden = !dismissable
            self.updateInfoToastUI(visible: true, alertText: text, type: type)
            if autoHideAfter > 0.0 {
                self.hideTimer?.invalidate()
                self.hideTimer = Timer.scheduledTimer(timeInterval: autoHideAfter, target: self, selector: #selector(self.hideToast), userInfo: nil, repeats: false)
            }
        }
    }
    
    @objc func hideToast() {
        hideTimer?.invalidate()
        hideTimer = nil
        updateInfoToastUI(visible: false)
    }
    
    public func hideToastAlert(completion: (()->())? = nil) {
        updateInfoToastUI(visible: false, completion: completion)
    }
    
    private func updateInfoToastUI(visible: Bool, alertText: String? = "", type: ToastAlertType? = nil, completion: (()->())? = nil) {
        
        DispatchQueue.main.async {
            if visible { self.onShow?() } else { self.onHide?() }
            if let toastType = type {
                self.view.backgroundColor = .green
                var imageName = "warningWhite"
                switch toastType {
                case .error:
                    self.view.backgroundColor = UIColor.darkRed
                case .info:
                    self.view.backgroundColor = UIColor.lightBlue
                    imageName = "infoWhite"
                case .success:
                    self.view.backgroundColor = UIColor.lightBlue
                    imageName = "successWhite"
                case .deletePending:
                    self.view.backgroundColor = UIColor.darkRed
                    imageName = "mailSent"
                case .deleteConfirmed:
                    self.view.backgroundColor = UIColor.darkRed
                    imageName = "garbageWhite"
                case .validatePending:
                    self.view.backgroundColor = UIColor.pendingYellow
                    imageName = "toastRefresh"
              }
                self.leftImageView.image = UIImage(named: imageName)
            }
            if let text = alertText, text.count > 0 {
                self.alertTextLabel.text = text
                self.frame.size.height = max(50, self.alertTextLabel.requiredHeight() + 6)
            }
            
            self.superview?.layoutIfNeeded()
            self.underViewTopConstraint?.constant = (visible) ? self.initialParentConstraint + self.frame.size.height + 7 : self.initialParentConstraint
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
                guard let parent = self.parent else {
                    self.alpha = (visible) ? 1.0 : 0.0
                    return
                }
                self.superview?.layoutIfNeeded()
                self.frame.origin.y = (visible) ? parent.frame.origin.y - self.frame.size.height - 3.5 + self.extraOffest : -self.frame.size.height
                self.alpha = (visible) ? 1.0 : 0.0
            }, completion: {success in
                completion?()
            })
        }
    }
}

extension UILabel {
    
    func requiredHeight() -> CGFloat{
        
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = self.font
        label.text = self.text
        
        label.sizeToFit()
        
        return label.frame.height
    }
}
