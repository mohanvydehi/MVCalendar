//
//  MVCalendarDayCell.swift
//  MVCalendar
//
//  Created by Mohan Vydehi on 27/09/16.
//  Copyright © 2016 Mohan Vydehi. All rights reserved.
//

import UIKit

let cellColorDefault = UIColor(white: 0.0, alpha: 0.0)
let cellColorToday = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.3)
let borderColor = UIColor(red: 254.0/255.0, green: 73.0/255.0, blue: 64.0/255.0, alpha: 0.8)

public class MVCalendarDayCell: UICollectionViewCell {
    
    public var isToday : Bool = false {
        
        didSet {
            
            if isToday == true {
                self.pBackgroundView.backgroundColor = cellColorToday
            }
            else {
                self.pBackgroundView.backgroundColor = cellColorDefault
            }
        }
    }
    
    override public var isSelected : Bool {
        
        didSet {
            
            if isSelected == true {
                self.pBackgroundView.backgroundColor = UIColor.lightGray
            }
            else {
                self.pBackgroundView.backgroundColor = cellColorDefault
            }
            
        }
    }
    
    lazy var pBackgroundView : UIView = {
        
//        var vFrame = self.frame.insetBy(dx: 3.0, dy: 3.0)
        let vFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let view = UIView(frame: vFrame)
        view.layer.cornerRadius = vFrame.width / 2
        view.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        
        return view
    }()
    
    lazy var textLabel : UILabel = {
        
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.textColor = UIColor.darkGray
        lbl.sizeToFit()
        
        return lbl
        
    }()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.addSubview(self.pBackgroundView)
        
        self.textLabel.frame = self.bounds
        self.addSubview(self.textLabel)

    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
