//
//  UIImage+Extensions.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 19/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

extension UIImage {
    
     static func getQRCodeImage(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 5, y: 5)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
}
