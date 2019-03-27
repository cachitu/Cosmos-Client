//
//  UIView+extensions.swift
//  IPSX
//
//  Created by Calin Chitu on 08/05/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit
import WebKit

public extension UIView {
    
    /**
     Returns an UIView from a xib file.
     
     - Parameters:
     - withOwner: The file owner set in the xib file
     - bundle: The bundle for the xib file
     
     - Returns: The top level UIView of the xib file
     */
    static func viewFromNib(withOwner: UIView, bundle: Bundle) -> UIView {
        
        let nib = UINib(nibName: "\(type(of: withOwner))", bundle: bundle)
        let view = nib.instantiate(withOwner: withOwner, options: nil).first as! UIView
        return view
    }
    
    func removeParticlesAnimation() {
        if subviews.first is WKWebView {
            subviews.first?.removeFromSuperview()
        }
    }
    
    func createParticlesAnimation() {
        
        if subviews.first is WKWebView { return }
        
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: bounds, configuration: webConfiguration)
        webView.alpha = 0
        UIView.animate(withDuration: 3, delay: 0, options: .curveEaseIn, animations: {
            webView.alpha = 1
        })
        insertSubview(webView, at: 0)
        if let url = Bundle.main.url(forResource: "background", withExtension: "html") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func loadNib(withOwner: UIView) -> UIView {
        
        let bundle = Bundle(for: self.classForCoder)
        let view = UIView.viewFromNib(withOwner: withOwner, bundle: bundle)
        view.frame = bounds
        return view
    }
    
    func labelTransition(_ duration : CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = CATransitionType.moveIn
        animation.duration = duration
        layer.add(animation, forKey: CATransitionType.fade.rawValue)
    }
}
