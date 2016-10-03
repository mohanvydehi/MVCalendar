//
//  MVCalendarFlowLayout.swift
//  MVCalendar
//
//  Created by Mohan Vydehi on 27/09/16.
//  Copyright © 2016 Mohan Vydehi. All rights reserved.
//

import UIKit

public class MVCalendarFlowLayout: UICollectionViewFlowLayout {

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        return super.layoutAttributesForElements(in: rect)?.map {
            attributes in
           
            let attrCopy = attributes.copy() as! UICollectionViewLayoutAttributes
            self.applyLayoutAttributes(attributes: attrCopy)
            return attrCopy
        }
    }
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        if let attributes = super.layoutAttributesForItem(at: indexPath) {
            
            let attrCopy = attributes.copy() as! UICollectionViewLayoutAttributes
            self.applyLayoutAttributes(attributes: attrCopy)
            return attrCopy
        }
        return nil
    }
    
    func applyLayoutAttributes(attributes : UICollectionViewLayoutAttributes) {
        
        if attributes.representedElementKind != nil {
            return
        }
        
        if let collectionView = self.collectionView {
            
            let stride = (self.scrollDirection == .horizontal) ? collectionView.frame.size.width : collectionView.frame.size.height
            
            let offset = CGFloat(attributes.indexPath.section) * stride
            
            var xCellOffset : CGFloat = CGFloat(attributes.indexPath.item % 7) * self.itemSize.width
            
            var yCellOffset : CGFloat = CGFloat(attributes.indexPath.item / 7) * self.itemSize.height
            
            if(self.scrollDirection == .horizontal) {
                xCellOffset += offset;
            } else {
                yCellOffset += offset
            }
            
            attributes.frame = CGRect(x: xCellOffset, y: yCellOffset, width: self.itemSize.width, height: self.itemSize.height)
        }
        
    }
    
}
