//
//  CenteringFlowLayout.swift
//
//  Created by Calin Chitu on 18/12/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

class CenteringFlowLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        
        guard let collectionView = collectionView,
            let layoutAttributesArray = layoutAttributesForElements(in: collectionView.bounds),
            var candidate = layoutAttributesArray.first else { return proposedContentOffset }
        
        layoutAttributesArray.filter({$0.representedElementCategory == .cell }).forEach { layoutAttributes in
            
            if (velocity.x > 0 && layoutAttributes.center.x > candidate.center.x) ||
                (velocity.x <= 0 && layoutAttributes.center.x < candidate.center.x) {
                candidate = layoutAttributes
            }
        }
        return CGPoint(x: candidate.center.x - collectionView.bounds.width / 2, y: proposedContentOffset.y)
    }
    
}
