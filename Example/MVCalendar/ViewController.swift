//
//  ViewController.swift
//  MVCalendar
//
//  Created by Mohan Reddy on 09/30/2016.
//  Copyright (c) 2016 Mohan Reddy. All rights reserved.
//

import UIKit
import MVCalendar

class ViewController: UIViewController {
    
    @IBOutlet weak var calendarView: MVCalendarView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        calendarView.dataSource = self
        calendarView.delegate = self
        
    }
    
}

extension ViewController: MVCalendarViewDataSource, MVCalendarViewDelegate {
    
    func startDate() -> Date? {
        
        return Date()
        
    }
    
    func endDate() -> Date? {
        
        var dateComponents = DateComponents()
        
        dateComponents.year = 2;
        let today = Date()
        
        let twoYearsFromNow = self.calendarView.calendar.date(byAdding: dateComponents, to: today, options: NSCalendar.Options())
        
        return twoYearsFromNow
        
    }
    
    func calendar(calendar: MVCalendarView, didSelectDate date: Date) {
        
        print(date)
        
    }
    
}
