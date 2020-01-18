//
//  GaiaSecurityController.swift
//  Syncnode
//
//  Created by Calin Chitu on 04/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import LocalAuthentication

enum CollectMode {
    case unlock
    case sign
    case collectPhase1
    case collectPhase2
}

class GaiaSecurityController: UIViewController {

    var context = LAContext()

    var collectMode: CollectMode = .unlock
    var expectedPin: String? = AppContext.shared.node?.getPinFromKeychain()
    var onValidate: ((_ success: Bool) -> ())?
    var onCollect: ((_ success: Bool) -> ())?

    @IBOutlet weak var starsStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var pinStateLabel: UILabel!
    
    @IBOutlet weak var star1: UIButton!
    @IBOutlet weak var star2: UIButton!
    @IBOutlet weak var star3: UIButton!
    @IBOutlet weak var star4: UIButton!
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func digitAction(_ sender: RoundedButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        if digits.count >= 4 {
            return
        }
        digits.append(sender.titleLabel?.text ?? "")
    }
    
    @IBAction func backAction(_ sender: RoundedButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        guard  digits.count > 0 else {
            return
        }
        digits.removeLast()
    }
    
    @IBAction func clearAction(_ sender: RoundedButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        clearState()
    }
    
    private var digits: [String] = [] {
        didSet {
            updateStars(value: digits.count)
            handleState()
        }
    }
    
    private var retryCount = 0
    private var firstPin: String = ""
    private var secondPin: String = ""

    private func clearState() {
        digits = []
        firstPin = ""
        secondPin = ""
        pinStateLabel.text = screenTitle()
        if collectMode == .collectPhase2 {
            collectMode = .collectPhase1
        }
    }
    
    private func screenTitle() -> String {
        return collectMode == .unlock ? "Unlock" : collectMode == .sign ? "Sign" : "Create your pin"
    }
    
    private func handleState() {
        if digits.count == 4 {
            switch collectMode {
            case .unlock, .sign:
                firstPin = digits.joined()
                if firstPin == expectedPin {
                    self.dismiss(animated: true) {
                        self.onValidate?(true)
                    }
                } else {
                    retryCount += 1
                    if retryCount < 3 {
                        Animations.requireUserAtention(on: starsStackView)
                        clearState()
                    } else {
                        dismiss(animated: true) {
                            self.onValidate?(false)
                        }
                    }
                }
            case .collectPhase1:
                firstPin = digits.joined()
                digits = []
                secondPin = ""
                updateStars(value: 0)
                pinStateLabel.text = "Enter your pin again"
                collectMode = .collectPhase2
            case .collectPhase2:
                collectMode = .collectPhase1
                secondPin = digits.joined()
                if firstPin == secondPin {
                    onCollect?(true)
                    persistPin(pin: secondPin)
                    dismiss(animated: true, completion: nil)
                } else {
                    retryCount += 1
                    if retryCount < 3 {
                        Animations.requireUserAtention(on: starsStackView)
                        clearState()
                    } else {
                        onCollect?(false)
                        dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    private func updateStars(value: Int) {
        star1.isSelected = value > 0
        star2.isSelected = value > 1
        star3.isSelected = value > 2
        star4.isSelected = value > 3
    }
    
    private var retypeDigits: [String] = []
    
    private func persistPin(pin: String) {
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = AppContext.shared.node {
            for savedNode in savedNodes.nodes {
                if savedNode.uniqueID == validNode.uniqueID {
                    savedNode.savePinToKeychain(pin: pin)
                }
            }
            PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        isModalInPresentation = true
        closeButton.isHidden = collectMode == .unlock
        updateStars(value: 0)
        if AppContext.shared.node?.getPinFromKeychain() == nil {
            collectMode = .collectPhase1
        }
        titleLabel.text = screenTitle()
        pinStateLabel.text = collectMode == .unlock || collectMode == .sign ? "Type your pin" : "Create your pin"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error), UserDefaults.standard.bool(forKey: GaiaConstants.bioAuthDefautsKey), collectMode == .unlock {
            
            let reason = "Validate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { [weak self] success, error in
                DispatchQueue.main.async { [weak self] in
                    if success {
                        self?.updateStars(value: 4)
                        self?.onValidate?(true)
                        self?.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
}

class Animations {
    static func requireUserAtention(on onView: UIView) {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 4
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: onView.center.x - 10, y: onView.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: onView.center.x + 10, y: onView.center.y))
        onView.layer.add(animation, forKey: "position")
    }
}
