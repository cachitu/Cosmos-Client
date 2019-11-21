//
//  SimpleWebView.swift
//
//  Created by Calin Chitu on 15/06/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit
import WebKit

class SimpleWebView: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var topBarTitleLabel: UILabel!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var webViewHolder: UIView!
    
    var webView: WKWebView!
    
    var loadingURLString: String?
    var titleString = "FAQ"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView()
        webView.navigationDelegate = self

        if let stringUrl = loadingURLString, let url = URL(string: stringUrl) {

            webView.load(URLRequest(url: url))
            webView.allowsBackForwardNavigationGestures = true
        }
        topBarTitleLabel.text = titleString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        webView.frame = webViewHolder.bounds
        webViewHolder.addSubview(webView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.shared.endIgnoringInteractionEvents()
        }
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingView?.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingView?.stopAnimating()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        dismiss(animated: true)
    }
}
