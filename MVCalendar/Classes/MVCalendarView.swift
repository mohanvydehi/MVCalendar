//
//  MVCalendarView.swift
//  MVCalendar
//
//  Created by Mohan Vydehi on 27/09/16.
//  Copyright © 2016 Mohan Vydehi. All rights reserved.
//

import UIKit

let MAXIMUM_NUMBER_OF_ROWS = 6
let NUMBER_OF_DAYS_IN_WEEK = 7

let FIRST_DAY_INDEX = 0
let NUMBER_OF_DAYS_INDEX = 1
let DATE_SELECTED_INDEX = 2

let CELL_IDENTIFIER = "MVCalendarDayCell"

protocol MVCalendarViewDataSource {
    
    func startDate() -> Date?
    func endDate() -> Date?
    
}

protocol MVCalendarViewDelegate {
    
    func calendar(calendar: MVCalendarView, didSelectDate date: Date) -> Void
    
}

class MVCalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var dataSource : MVCalendarViewDataSource?
    var delegate : MVCalendarViewDelegate?

    lazy var calendarView : UICollectionView = {
        
        let layout = MVCalendarFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.allowsMultipleSelection = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        return collectionView
        
    }()
    
    lazy var gregorian : NSCalendar = {
        
        let cal = NSCalendar(identifier: NSCalendar.Identifier.gregorian)!
        cal.timeZone = NSTimeZone(abbreviation: "UTC")! as TimeZone
        return cal
        
    }()
    
    var calendar : NSCalendar {
        return self.gregorian
    }
    
    var direction : UICollectionViewScrollDirection = .horizontal {
        didSet {
            if let layout = self.calendarView.collectionViewLayout as? MVCalendarFlowLayout {
                layout.scrollDirection = direction
                self.calendarView.reloadData()
            }
        }
    }
    
    var displayDate : Date?
    
    private var startDateCache : Date = Date()
    private var endDateCache : Date = Date()
    private var startOfMonthCache : Date = Date()
    private var todayIndexPath : NSIndexPath?
    
    private(set) var selectedIndexPaths : [IndexPath] = [IndexPath]()
    private(set) var selectedDates : [Date] = [Date]()
    
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        self.initialSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        self.initialSetup()
    }
    
    // MARK: Public Methods
    
    
    // MARK: CollectionView Delegate and DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard let startDate = self.dataSource?.startDate(), let endDate = self.dataSource?.endDate() else {
            return 0
        }
        
        startDateCache = startDate
        endDateCache = endDate
        
        // check if the dates are in correct order
        if self.gregorian.compare(startDate, to: endDate, toUnitGranularity: .nanosecond) != ComparisonResult.orderedAscending {
            return 0
        }
        
        var firstDayOfStartMonth = self.gregorian.components( [.era, .year, .month], from: startDateCache)
        firstDayOfStartMonth.day = 1
        
        guard let dateFromDayOneComponents = self.gregorian.date(from: firstDayOfStartMonth) else {
            return 0
        }
        
        startOfMonthCache = dateFromDayOneComponents
        
        let today = Date()
        
        if  startOfMonthCache.compare(today) == ComparisonResult.orderedAscending &&
            endDateCache.compare(today) == ComparisonResult.orderedDescending {
            
            let differenceFromTodayComponents = self.gregorian.components([NSCalendar.Unit.month, NSCalendar.Unit.day], from: startOfMonthCache, to: today, options: NSCalendar.Options())
            
            self.todayIndexPath = NSIndexPath(item: differenceFromTodayComponents.day!, section: differenceFromTodayComponents.month!)
            
        }
        
        let differenceComponents = self.gregorian.components(NSCalendar.Unit.month, from: startDateCache, to: endDateCache, options: NSCalendar.Options())
        
        return differenceComponents.month! + 1 // if we are for example on the same month and the difference is 0 we still need 1 to display it
        
    }
    
    private var monthInfo : [Int:[Int]] = [Int:[Int]]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var monthOffsetComponents = DateComponents()
        monthOffsetComponents.month = section;
        
        guard let correctMonthForSectionDate = self.gregorian.date(byAdding: monthOffsetComponents, to: startOfMonthCache, options: NSCalendar.Options()) else {
            return 0
        }
        
        let numberOfDaysInMonth = self.gregorian.range(of: .day, in: .month, for: correctMonthForSectionDate).length
        
        var firstWeekdayOfMonthIndex = self.gregorian.component(NSCalendar.Unit.weekday, from: correctMonthForSectionDate)
        firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default
        
        monthInfo[section] = [firstWeekdayOfMonthIndex, numberOfDaysInMonth]
        
        return NUMBER_OF_DAYS_IN_WEEK * MAXIMUM_NUMBER_OF_ROWS // 7 x 6 = 42
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(MVCalendarDayCell.self), for: indexPath) as! MVCalendarDayCell
        
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]! // we are guaranteed an array by the fact that we reached this line (so unwrap)
        
        let fdIndex = currentMonthInfo[FIRST_DAY_INDEX]
        let nDays = currentMonthInfo[NUMBER_OF_DAYS_INDEX]
        
        let fromStartOfMonthIndexPath =  IndexPath(item: indexPath.item - fdIndex, section: indexPath.section)
        
        if indexPath.item >= fdIndex &&
            indexPath.item < fdIndex + nDays {
            
            dayCell.textLabel.text = String(fromStartOfMonthIndexPath.item + 1)
            
        }
        else {
            dayCell.textLabel.text = ""
        }
        
        dayCell.isSelected = selectedIndexPaths.contains(indexPath)

        if indexPath.section == 0 && indexPath.item == 0 {
            self.scrollViewDidEndDecelerating(collectionView)
        }
        
        if let idx = todayIndexPath {
            dayCell.isToday = (idx.section == indexPath.section && idx.item + fdIndex == indexPath.item)
        }
        
        return dayCell
        
    }
    
    // MARK: ScrollView Delegate Methods
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }
    
    func calculateDateBasedOnScrollViewPosition(scrollView: UIScrollView) {
        
        let cvbounds = self.calendarView.bounds
        
        var page : Int = Int(floor(self.calendarView.contentOffset.x / cvbounds.size.width))
        
        page = page > 0 ? page : 0
        
        var monthsOffsetComponents = DateComponents()
        monthsOffsetComponents.month = page
        
        guard self.delegate != nil else {
            return
        }
        
        guard let yearDate = self.gregorian.date(byAdding: monthsOffsetComponents, to: self.startOfMonthCache, options: NSCalendar.Options()) else {
            return
        }
//        
//        let month = self.gregorian.component(NSCalendar.Unit.month, from: yearDate) // get month
//        
//        let monthName = DateFormatter().monthSymbols[(month-1) % 12] // 0 indexed array
//        
//        let year = self.gregorian.component(NSCalendar.Unit.year, from: yearDate)
//        
        self.displayDate = yearDate
        
        
//        delegate.calendar(self, didScrollToMonth: yearDate)
        
    }
    
    // MARK : CollectionView Delegate Methods
    
    private var dateBeingSelectedByUser : Date?
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!
        let firstDayInMonth = currentMonthInfo[FIRST_DAY_INDEX]
        
        var offsetComponents = DateComponents()
        offsetComponents.month = indexPath.section
        offsetComponents.day = indexPath.item - firstDayInMonth
        
        if let dateUserSelected = self.gregorian.date(byAdding: offsetComponents, to: startOfMonthCache, options: NSCalendar.Options()) {
            
            dateBeingSelectedByUser = dateUserSelected
            
            // Optional protocol method (the delegate can "object")
//            if let canSelectFromDelegate = delegate?.calendar?(self, canSelectDate: dateUserSelected) {
//                return canSelectFromDelegate
//            }
            
            return true // it can select any date by default
            
        }
        
        return false
        
    }
    
    func selectDate(date : Date) {
        
        guard let indexPath = self.indexPathForDate(date: date) else {
            return
        }
        
        guard (self.calendarView.indexPathsForSelectedItems?.contains(indexPath))! == false else {
            return
        }
        
        self.calendarView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        
        selectedIndexPaths.append(indexPath)
        selectedDates.append(date)
        
    }
    
    func deselectDate(date : Date) {
        
        guard let indexPath = self.indexPathForDate(date: date) else {
            return
        }
        
        guard self.calendarView.indexPathsForSelectedItems?.contains(indexPath) == true else {
            return
        }
        
        
        self.calendarView.deselectItem(at: indexPath, animated: false)
        
        guard let index = selectedIndexPaths.index(of: indexPath) else {
            return
        }
        
        selectedIndexPaths.remove(at: index)
        selectedDates.remove(at: index)
        
        
    }
    
    func indexPathForDate(date : Date) -> IndexPath? {
        
        let distanceFromStartComponent = self.gregorian.components( [.month, .day], from:startOfMonthCache, to: date, options: NSCalendar.Options() )
        
        guard let currentMonthInfo : [Int] = monthInfo[distanceFromStartComponent.month!] else {
            return nil
        }
        
        
        let item = distanceFromStartComponent.day! + currentMonthInfo[FIRST_DAY_INDEX]
        let indexPath = IndexPath(item: item, section: distanceFromStartComponent.month!)
        
        return indexPath
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let dateBeingSelectedByUser = dateBeingSelectedByUser else {
            return
        }
                
        delegate?.calendar(calendar: self, didSelectDate: dateBeingSelectedByUser)
        
        // Update model
        selectedIndexPaths.append(indexPath)
        selectedDates.append(dateBeingSelectedByUser)
        
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        guard dateBeingSelectedByUser != nil else {
            return
        }
        
        guard let index = selectedIndexPaths.index(of: indexPath) else {
            return
        }
        
//        delegate?.calendar?(self, didDeselectDate: dateBeingSelectedByUser)
        
        selectedIndexPaths.remove(at: index)
        selectedDates.remove(at: index)
        
    }
    
    func reloadData() {
        self.calendarView.reloadData()
    }
    
    
    func setDisplayDate(date : Date, animated: Bool) {
        
        if let dispDate = self.displayDate {
            
            // skip is we are trying to set the same date
            if  date.compare(dispDate) == ComparisonResult.orderedSame {
                return
            }
            
            // check if the date is within range
            if  date.compare(startDateCache) == ComparisonResult.orderedAscending ||
                date.compare(endDateCache) == ComparisonResult.orderedDescending   {
                return
            }
            
            let difference = self.gregorian.components([NSCalendar.Unit.month], from: startOfMonthCache, to: date, options: NSCalendar.Options())
            
            let distance : CGFloat = CGFloat(difference.month!) * self.calendarView.frame.size.width
            
            self.calendarView.setContentOffset(CGPoint(x: distance, y: 0.0), animated: animated)
            
        }
        
    }
    
}

private extension MVCalendarView {
    
    func initialSetup() {
        
        self.clipsToBounds = true
        self.calendarView.register(MVCalendarDayCell.self, forCellWithReuseIdentifier: NSStringFromClass(MVCalendarDayCell.self))
        self.addSubview(self.calendarView)
        
        let views = ["calendarView" : calendarView]
        var allConstraints = [NSLayoutConstraint]()
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[calendarView]-|", options: [], metrics: nil, views: views)
        allConstraints += horizontalConstraints
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[calendarView]-|", options: [], metrics: nil, views: views)
        allConstraints += verticalConstraints
        
        self.addConstraints(allConstraints)
        
    }
}
