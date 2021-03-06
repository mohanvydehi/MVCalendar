//
//  MVCalendarView.swift
//  MVCalendar
//
//  Created by Mohan Vydehi on 27/09/16.
//  Copyright © 2016 Mohan Vydehi. All rights reserved.
//

/*
    1. Date before today should be desabled.
    2. Default date of selection is today.
 */

import UIKit

let MAXIMUM_NUMBER_OF_ROWS  = 6
let NUMBER_OF_DAYS_IN_WEEK  = 7

let FIRST_DAY_INDEX         = 0
let NUMBER_OF_DAYS_INDEX    = 1
let CURRENT_MONTH_INDEX     = 2

let CELL_IDENTIFIER         = "MVCalendarDayCell"


enum MVMonthComparisonResult : Int {
    
    case same
    case previous
    case next
    
}


@objc
public protocol MVCalendarViewDataSource {
    
    @objc optional func startDate() -> Date?
    @objc optional func endDate() -> Date?
    
}


@objc
public protocol MVCalendarViewDelegate {
    
    @objc optional func calendar(calendar: MVCalendarView, didSelectDate date: Date) -> Void
    
}


public class MVCalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public var dataSource : MVCalendarViewDataSource?
    public var delegate : MVCalendarViewDelegate?

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
    
    public var calendar : NSCalendar {
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
    
    var displayDate : Date? = Date()
    
    private var startDateCache : Date!
    private var endDateCache : Date!
    private var startOfMonthCache : Date = Date()
    private var todayIndexPath : IndexPath?
    
    private var selectedIndexPath : IndexPath = IndexPath()
    private var selectedDate : Date? = Date()
    
    private var monthInfo : [Int:[Int]] = [Int:[Int]]()
    

    override init(frame: CGRect) {
        super.init(frame : frame)
        self.initialSetup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        self.initialSetup()
    }
    
    // MARK: CollectionView Delegate and DataSource
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard let startDate = self.dataSource?.startDate!(), let endDate = self.dataSource?.endDate!() else {
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
            
            self.todayIndexPath = NSIndexPath(item: differenceFromTodayComponents.day!, section: differenceFromTodayComponents.month!) as IndexPath
            
        }
        
        let differenceComponents = self.gregorian.components(NSCalendar.Unit.month, from: startDateCache, to: endDateCache, options: NSCalendar.Options())
        
        return differenceComponents.month! + 1 // if we are for example on the same month and the difference is 0 we still need 1 to display it
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        var monthOffsetComponents = DateComponents()
        monthOffsetComponents.month = section;
        
        guard let correctMonthForSectionDate = self.gregorian.date(byAdding: monthOffsetComponents, to: startOfMonthCache, options: NSCalendar.Options()) else {
            return 0
        }
        
        let numberOfDaysInMonth = self.gregorian.range(of: .day, in: .month, for: correctMonthForSectionDate).length
        
        var firstWeekdayOfMonthIndex = self.gregorian.component(NSCalendar.Unit.weekday, from: correctMonthForSectionDate)
        firstWeekdayOfMonthIndex = firstWeekdayOfMonthIndex - 1 // firstWeekdayOfMonthIndex should be 0-Indexed
        firstWeekdayOfMonthIndex = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly so that we take it back one day so that the first day is Monday instead of Sunday which is the default
        
        monthInfo[section] = [firstWeekdayOfMonthIndex, numberOfDaysInMonth, self.gregorian.component(NSCalendar.Unit.month, from: correctMonthForSectionDate)]
        
        return NUMBER_OF_DAYS_IN_WEEK * MAXIMUM_NUMBER_OF_ROWS // 7 x 6 = 42
        
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(MVCalendarDayCell.self), for: indexPath) as! MVCalendarDayCell
        
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]! // we are guaranteed an array by the fact that we reached this line (so unwrap)
        
        let fdIndex = currentMonthInfo[FIRST_DAY_INDEX]
        
        let date = dateForIndexPath(indexPath: indexPath)
        dayCell.textLabel.text = String(self.gregorian.component(NSCalendar.Unit.day, from: date))
        
        if let idx = todayIndexPath {
            dayCell.isToday = (idx.section == indexPath.section && idx.item + fdIndex == indexPath.item)
        }
        
        dayCell.isDateSelectable = isSelectedIndexPathCurrentMonth(indexPath: indexPath)
        dayCell.isSelected = (selectedDate!.compare(date) == .orderedSame)

        if indexPath.section == 0 && indexPath.item == 0 {
            self.scrollViewDidEndDecelerating(collectionView)
        }
        
        return dayCell
        
    }
    
    private func isSelectedIndexPathCurrentMonth(indexPath: IndexPath) -> Bool {
        
        var isDateSelectable: Bool = (selectedIndexPathMonthComparisonResult(indexPath: indexPath) == MVMonthComparisonResult.same)
        let selectedDate = dateForIndexPath(indexPath: indexPath)

        if (selectedDate.compare(Date()) == .orderedAscending) {
            isDateSelectable = false
        }
        
        return isDateSelectable
        
    }
    
    private func selectedIndexPathMonthComparisonResult(indexPath: IndexPath) -> MVMonthComparisonResult {
        
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!
        let currentMonth = currentMonthInfo[CURRENT_MONTH_INDEX]
        
        let selectedDate = dateForIndexPath(indexPath: indexPath)
        
        if currentMonth == self.gregorian.component(NSCalendar.Unit.month, from: selectedDate) {
            return MVMonthComparisonResult.same
        }
        
        if currentMonth <= self.gregorian.component(NSCalendar.Unit.month, from: selectedDate) {
            return MVMonthComparisonResult.next
        }
        
        if currentMonth >= self.gregorian.component(NSCalendar.Unit.month, from: selectedDate) {
            return MVMonthComparisonResult.previous
        }
        
        return MVMonthComparisonResult.same
    }
    
    // MARK: ScrollView Delegate Methods
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.calculateDateBasedOnScrollViewPosition(scrollView: scrollView)
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
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
        
        self.displayDate = yearDate
        
    }
    
    // MARK : CollectionView Delegate Methods
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        selectedDate = dateForIndexPath(indexPath: indexPath)
        // TODO: Need to check if selected date is lessthan from today's date need to return false
        return true
        
    }
    
    private func dateForIndexPath(indexPath: IndexPath) -> Date {
        
        let currentMonthInfo : [Int] = monthInfo[indexPath.section]!
        let firstDayInMonth = currentMonthInfo[FIRST_DAY_INDEX]
        
        var offsetComponents = DateComponents()
        offsetComponents.month = indexPath.section
        offsetComponents.day = indexPath.item - firstDayInMonth
        
        return self.gregorian.date(byAdding: offsetComponents, to: startOfMonthCache, options: NSCalendar.Options())!
        
    }
    
    func selectDate(date : Date) {
        
        guard let indexPath = self.indexPathForDate(date: date) else {
            return
        }
        
        guard (self.calendarView.indexPathsForSelectedItems?.contains(indexPath))! == false else {
            return
        }
        
        self.calendarView.selectItem(at: indexPath, animated: true, scrollPosition: [])
        
        selectedIndexPath = indexPath
        selectedDate = date
        
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
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let dateBeingSelectedByUser = selectedDate else {
            return
        }
        
        selectedIndexPath = indexPath
        
        let monthComparisonResult = selectedIndexPathMonthComparisonResult(indexPath: indexPath)
        
        switch monthComparisonResult {
        case .same:
            break
        case .next:
            setDisplayDate(date: dateBeingSelectedByUser, animated: true)
            break
        case .previous:
            setDisplayDate(date: dateBeingSelectedByUser, animated: true)
            break
        }
        
        reloadData()
        
        delegate?.calendar!(calendar: self, didSelectDate: dateBeingSelectedByUser)
        
    }
    
    public func scrollToNextMonth(animated: Bool) {
        
        var todayComponents = calendar.components([.year, .month], from: selectedDate!)
        todayComponents.month = todayComponents.month! + 1
        let firstDayOfNextMonth = calendar.date(from: todayComponents)
        
        selectedDate = firstDayOfNextMonth!
        setDisplayDate(date: selectedDate!, animated: true)
        reloadData()
        
        delegate?.calendar!(calendar: self, didSelectDate: selectedDate!)
        
    }
    
    public func scrollToPreviousMonth(animated: Bool) {
        
        var todayComponents = calendar.components([.year, .month], from: selectedDate!)
        todayComponents.month = todayComponents.month! - 1
        var firstDayOfPreviousMonth = calendar.date(from: todayComponents)
        
        if firstDayOfPreviousMonth?.compare(Date()) == .orderedAscending {
            firstDayOfPreviousMonth = Date()
        }
        
        selectedDate = firstDayOfPreviousMonth!
        setDisplayDate(date: selectedDate!, animated: true)
        reloadData()
        
        delegate?.calendar!(calendar: self, didSelectDate: selectedDate!)
        
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
