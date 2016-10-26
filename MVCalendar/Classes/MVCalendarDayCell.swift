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
let currentMonthTextColor = UIColor.darkGray
let previousMonthTextColor = UIColor.lightGray

public class MVCalendarDayCell: UICollectionViewCell {
    
    public var isToday : Bool = false {
        
        didSet {
            
            if isToday == true {
                self.pBackgroundView.backgroundColor = cellColorToday
            }
//            else {
//                self.pBackgroundView.backgroundColor = cellColorDefault
//            }
        }
    }
    
    override public var isSelected : Bool {
        
        didSet {
            
            if isToday == false {
                
                if isSelected == true && isCurrentMonth == true {
                    self.pBackgroundView.backgroundColor = UIColor.lightGray
                }
                else {
                    self.pBackgroundView.backgroundColor = cellColorDefault
                }
                
            }
            
        }
    }
    
    public var isCurrentMonth : Bool = true {
        
        didSet {
            
            if isCurrentMonth == true {
                textLabel.textColor = currentMonthTextColor
            } else {
                textLabel.textColor = previousMonthTextColor
            }
            
        }
        
    }
    
    lazy var pBackgroundView : UIView = {
        
        let vFrame = CGRect(x: 0, y: 0, width: 40, height: 40)
        
        let view = UIView(frame: vFrame)
        view.layer.cornerRadius = vFrame.width / 2
        view.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        
        return view
    }()
    
    lazy var textLabel : UILabel = {
        
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.textColor = currentMonthTextColor
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
