//
//  CustomloadingView?.swift
//  IPSX
//
//  Created by Calin Chitu on 03/05/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

class CustomLoadingView: UIView {
    
    var circleColor = UIColor.darkRed.cgColor
    var secondCircleColor = UIColor.disabledGrey.cgColor
    var thirdCircleColor  = UIColor.lightBlue.cgColor
    
    var lineWidth: CGFloat { return frame.size.width / 15 }
    private var secondCircle: CAShapeLayer!
    private var thirdCircle: CAShapeLayer!
    
    @IBInspectable open var firstCircleColor: UIColor = UIColor.darkRed {
        didSet {
            circleColor = firstCircleColor.cgColor
        }
    }
    
    @IBInspectable open var singleCircle: Bool = false
    @IBInspectable open var ignoreInteractionEvents: Bool = false
    
    public func startAnimating() {
        
        DispatchQueue.main.async {
            
            if self.ignoreInteractionEvents { UIApplication.shared.beginIgnoringInteractionEvents() }
            
            if !self.singleCircle && (self.secondCircle == nil || self.self.thirdCircle == nil) {
                return
            }
            self.alpha = 1
            self.rotationAnimation(duration: 2, layer: self.self.layer)
            
            if !self.singleCircle {
                self.rotationAnimation(duration: 1, layer: self.secondCircle)
                self.rotationAnimation(duration: 2, layer: self.thirdCircle)
            }
        }
    }
    
    public func stopAnimating() {
        
        DispatchQueue.main.async {
            
            if self.ignoreInteractionEvents { UIApplication.shared.endIgnoringInteractionEvents() }
            
            if !self.singleCircle && (self.secondCircle == nil || self.self.thirdCircle == nil) {
                return
            }
            self.alpha = 0
            self.layer.removeAllAnimations()
            
            if !self.singleCircle {
                self.secondCircle?.removeAllAnimations()
                self.thirdCircle?.removeAllAnimations()
            }
        }
    }
    
    override public var layer: CAShapeLayer {
        get {
            return super.layer as! CAShapeLayer
        }
    }
    
    override public class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .clear
        self.alpha = 0
        setPath()
    }
    
    private func setPath() {
        
        let centery: CGPoint = CGPoint(x: layer.frame.size.width / 2, y: layer.frame.size.width / 2)
        let path1 = UIBezierPath(arcCenter: centery, radius: (layer.frame.size.width / 2) - (lineWidth / 2), startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true)
        let path2 = UIBezierPath(arcCenter: centery, radius: (layer.frame.size.width / 2) - (lineWidth / 2) - (lineWidth * 2), startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true)
        let path3 = UIBezierPath(arcCenter: centery, radius: (layer.frame.size.width / 2) - (lineWidth / 2) - (lineWidth * 4), startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true)
        
        layer.fillColor = nil
        layer.strokeColor = circleColor
        layer.lineWidth = lineWidth
        layer.path = path1.cgPath
        
        if !singleCircle {
            
            secondCircle = CAShapeLayer()
            secondCircle.frame = layer.bounds
            secondCircle.path = path2.cgPath
            secondCircle.fillColor = nil
            secondCircle.strokeColor = secondCircleColor
            secondCircle.lineWidth = lineWidth
            layer.addSublayer(secondCircle)
            
            thirdCircle = CAShapeLayer()
            thirdCircle.frame = layer.bounds
            thirdCircle.path = path3.cgPath
            thirdCircle.fillColor = nil
            thirdCircle.strokeColor = thirdCircleColor
            thirdCircle.lineWidth = lineWidth
            layer.addSublayer(thirdCircle)
        }
    }
    
    func rotationAnimation(duration: CFTimeInterval, layer: CAShapeLayer) {
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue =  Double.pi * 2.0
        animation.duration = duration
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        
        layer.add(animation, forKey: "spin")
    }
    
}
