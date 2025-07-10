//import XCTest
//@testable import MediStock
//
//final class DateExtensionsTests: XCTestCase {
//    
//    var testDate: Date!
//    var calendar: Calendar!
//    
//    override func setUp() {
//        super.setUp()
//        calendar = Calendar.current
//        // Create a fixed test date: January 15, 2024, 14:30:45
//        let components = DateComponents(
//            year: 2024,
//            month: 1,
//            day: 15,
//            hour: 14,
//            minute: 30,
//            second: 45
//        )
//        testDate = calendar.date(from: components)!
//    }
//    
//    override func tearDown() {
//        testDate = nil
//        calendar = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Formatting Tests
//    
//    func testFormattedString_DefaultFormat() {
//        // When
//        let formatted = testDate.formatted()
//        
//        // Then
//        XCTAssertFalse(formatted.isEmpty)
//        XCTAssertTrue(formatted.contains("2024"))
//        XCTAssertTrue(formatted.contains("Jan") || formatted.contains("1"))
//        XCTAssertTrue(formatted.contains("15"))
//    }
//    
//    func testFormattedString_ShortDateStyle() {
//        // When
//        let formatted = testDate.formatted(date: .numeric, time: .omitted)
//        
//        // Then
//        XCTAssertFalse(formatted.isEmpty)
//        XCTAssertTrue(formatted.contains("2024") || formatted.contains("24"))
//        XCTAssertTrue(formatted.contains("1") || formatted.contains("01"))
//        XCTAssertTrue(formatted.contains("15"))
//    }
//    
//    func testFormattedString_TimeOnly() {
//        // When
//        let formatted = testDate.formatted(date: .omitted, time: .shortened)
//        
//        // Then
//        XCTAssertFalse(formatted.isEmpty)
//        XCTAssertTrue(formatted.contains("14") || formatted.contains("2")) // 14:30 or 2:30 PM
//        XCTAssertTrue(formatted.contains("30"))
//    }
//    
//    // MARK: - Relative Date Tests
//    
//    func testIsToday_SameDay() {
//        // Given
//        let today = Date()
//        
//        // When
//        let isToday = today.isToday
//        
//        // Then
//        XCTAssertTrue(isToday)
//    }
//    
//    func testIsToday_DifferentDay() {
//        // Given
//        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
//        
//        // When
//        let isToday = yesterday.isToday
//        
//        // Then
//        XCTAssertFalse(isToday)
//    }
//    
//    func testIsYesterday_PreviousDay() {
//        // Given
//        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
//        
//        // When
//        let isYesterday = yesterday.isYesterday
//        
//        // Then
//        XCTAssertTrue(isYesterday)
//    }
//    
//    func testIsYesterday_SameDay() {
//        // Given
//        let today = Date()
//        
//        // When
//        let isYesterday = today.isYesterday
//        
//        // Then
//        XCTAssertFalse(isYesterday)
//    }
//    
//    func testIsTomorrow_NextDay() {
//        // Given
//        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
//        
//        // When
//        let isTomorrow = tomorrow.isTomorrow
//        
//        // Then
//        XCTAssertTrue(isTomorrow)
//    }
//    
//    func testIsTomorrow_SameDay() {
//        // Given
//        let today = Date()
//        
//        // When
//        let isTomorrow = today.isTomorrow
//        
//        // Then
//        XCTAssertFalse(isTomorrow)
//    }
//    
//    // MARK: - Date Component Tests
//    
//    func testStartOfDay() {
//        // When
//        let startOfDay = testDate.startOfDay
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startOfDay)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 15)
//        XCTAssertEqual(components.hour, 0)
//        XCTAssertEqual(components.minute, 0)
//        XCTAssertEqual(components.second, 0)
//    }
//    
//    func testEndOfDay() {
//        // When
//        let endOfDay = testDate.endOfDay
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfDay)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 15)
//        XCTAssertEqual(components.hour, 23)
//        XCTAssertEqual(components.minute, 59)
//        XCTAssertEqual(components.second, 59)
//    }
//    
//    func testStartOfWeek() {
//        // When
//        let startOfWeek = testDate.startOfWeek
//        
//        // Then
//        let weekday = calendar.component(.weekday, from: startOfWeek)
//        XCTAssertEqual(weekday, calendar.firstWeekday)
//    }
//    
//    func testStartOfMonth() {
//        // When
//        let startOfMonth = testDate.startOfMonth
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: startOfMonth)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 1)
//    }
//    
//    func testEndOfMonth() {
//        // When
//        let endOfMonth = testDate.endOfMonth
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: endOfMonth)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 31) // January has 31 days
//    }
//    
//    // MARK: - Age Calculation Tests
//    
//    func testAge_InYears() {
//        // Given
//        let birthDate = calendar.date(byAdding: .year, value: -25, to: Date())!
//        
//        // When
//        let age = birthDate.age
//        
//        // Then
//        XCTAssertEqual(age, 25)
//    }
//    
//    func testAge_ZeroYears() {
//        // Given
//        let recentDate = calendar.date(byAdding: .month, value: -6, to: Date())!
//        
//        // When
//        let age = recentDate.age
//        
//        // Then
//        XCTAssertEqual(age, 0)
//    }
//    
//    func testAge_FutureDate() {
//        // Given
//        let futureDate = calendar.date(byAdding: .year, value: 1, to: Date())!
//        
//        // When
//        let age = futureDate.age
//        
//        // Then
//        XCTAssertEqual(age, -1)
//    }
//    
//    // MARK: - Time Interval Tests
//    
//    func testTimeIntervalSinceNow_Past() {
//        // Given
//        let pastDate = calendar.date(byAdding: .hour, value: -2, to: Date())!
//        
//        // When
//        let interval = pastDate.timeIntervalSinceNow
//        
//        // Then
//        XCTAssertLessThan(interval, 0) // Should be negative for past dates
//        XCTAssertLessThan(abs(interval), 2.5 * 3600) // Within 2.5 hours
//        XCTAssertGreaterThan(abs(interval), 1.5 * 3600) // At least 1.5 hours
//    }
//    
//    func testTimeIntervalSinceNow_Future() {
//        // Given
//        let futureDate = calendar.date(byAdding: .hour, value: 3, to: Date())!
//        
//        // When
//        let interval = futureDate.timeIntervalSinceNow
//        
//        // Then
//        XCTAssertGreaterThan(interval, 0) // Should be positive for future dates
//        XCTAssertLessThan(interval, 3.5 * 3600) // Within 3.5 hours
//        XCTAssertGreaterThan(interval, 2.5 * 3600) // At least 2.5 hours
//    }
//    
//    // MARK: - Date Arithmetic Tests
//    
//    func testAddingDays() {
//        // When
//        let futureDate = testDate.adding(days: 5)
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: futureDate)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 20)
//    }
//    
//    func testAddingNegativeDays() {
//        // When
//        let pastDate = testDate.adding(days: -10)
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: pastDate)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 5)
//    }
//    
//    func testAddingWeeks() {
//        // When
//        let futureDate = testDate.adding(weeks: 2)
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: futureDate)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 29)
//    }
//    
//    func testAddingMonths() {
//        // When
//        let futureDate = testDate.adding(months: 3)
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: futureDate)
//        XCTAssertEqual(components.year, 2024)
//        XCTAssertEqual(components.month, 4)
//        XCTAssertEqual(components.day, 15)
//    }
//    
//    func testAddingYears() {
//        // When
//        let futureDate = testDate.adding(years: 2)
//        
//        // Then
//        let components = calendar.dateComponents([.year, .month, .day], from: futureDate)
//        XCTAssertEqual(components.year, 2026)
//        XCTAssertEqual(components.month, 1)
//        XCTAssertEqual(components.day, 15)
//    }
//    
//    // MARK: - Date Comparison Tests
//    
//    func testIsSameDay() {
//        // Given
//        let sameDay = calendar.date(byAdding: .hour, value: 2, to: testDate)!
//        let differentDay = calendar.date(byAdding: .day, value: 1, to: testDate)!
//        
//        // When & Then
//        XCTAssertTrue(testDate.isSameDay(as: sameDay))
//        XCTAssertFalse(testDate.isSameDay(as: differentDay))
//    }
//    
//    func testIsSameWeek() {
//        // Given
//        let sameWeek = calendar.date(byAdding: .day, value: 2, to: testDate)!
//        let differentWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: testDate)!
//        
//        // When & Then
//        XCTAssertTrue(testDate.isSameWeek(as: sameWeek))
//        XCTAssertFalse(testDate.isSameWeek(as: differentWeek))
//    }
//    
//    func testIsSameMonth() {
//        // Given
//        let sameMonth = calendar.date(byAdding: .day, value: 10, to: testDate)!
//        let differentMonth = calendar.date(byAdding: .month, value: 1, to: testDate)!
//        
//        // When & Then
//        XCTAssertTrue(testDate.isSameMonth(as: sameMonth))
//        XCTAssertFalse(testDate.isSameMonth(as: differentMonth))
//    }
//    
//    func testIsSameYear() {
//        // Given
//        let sameYear = calendar.date(byAdding: .month, value: 6, to: testDate)!
//        let differentYear = calendar.date(byAdding: .year, value: 1, to: testDate)!
//        
//        // When & Then
//        XCTAssertTrue(testDate.isSameYear(as: sameYear))
//        XCTAssertFalse(testDate.isSameYear(as: differentYear))
//    }
//    
//    // MARK: - Days Between Tests
//    
//    func testDaysBetween_SameDay() {
//        // When
//        let days = testDate.daysBetween(testDate)
//        
//        // Then
//        XCTAssertEqual(days, 0)
//    }
//    
//    func testDaysBetween_FutureDays() {
//        // Given
//        let futureDate = calendar.date(byAdding: .day, value: 7, to: testDate)!
//        
//        // When
//        let days = testDate.daysBetween(futureDate)
//        
//        // Then
//        XCTAssertEqual(days, 7)
//    }
//    
//    func testDaysBetween_PastDays() {
//        // Given
//        let pastDate = calendar.date(byAdding: .day, value: -5, to: testDate)!
//        
//        // When
//        let days = testDate.daysBetween(pastDate)
//        
//        // Then
//        XCTAssertEqual(days, -5)
//    }
//    
//    // MARK: - Weekday Tests
//    
//    func testWeekdayName() {
//        // When
//        let weekdayName = testDate.weekdayName
//        
//        // Then
//        XCTAssertFalse(weekdayName.isEmpty)
//        // January 15, 2024 is a Monday
//        XCTAssertTrue(weekdayName.contains("Mon") || weekdayName.contains("Monday"))
//    }
//    
//    func testMonthName() {
//        // When
//        let monthName = testDate.monthName
//        
//        // Then
//        XCTAssertFalse(monthName.isEmpty)
//        XCTAssertTrue(monthName.contains("Jan") || monthName.contains("January"))
//    }
//    
//    // MARK: - Quarter Tests
//    
//    func testQuarter_January() {
//        // When
//        let quarter = testDate.quarter
//        
//        // Then
//        XCTAssertEqual(quarter, 1)
//    }
//    
//    func testQuarter_April() {
//        // Given
//        let aprilDate = calendar.date(from: DateComponents(year: 2024, month: 4, day: 15))!
//        
//        // When
//        let quarter = aprilDate.quarter
//        
//        // Then
//        XCTAssertEqual(quarter, 2)
//    }
//    
//    func testQuarter_July() {
//        // Given
//        let julyDate = calendar.date(from: DateComponents(year: 2024, month: 7, day: 15))!
//        
//        // When
//        let quarter = julyDate.quarter
//        
//        // Then
//        XCTAssertEqual(quarter, 3)
//    }
//    
//    func testQuarter_October() {
//        // Given
//        let octoberDate = calendar.date(from: DateComponents(year: 2024, month: 10, day: 15))!
//        
//        // When
//        let quarter = octoberDate.quarter
//        
//        // Then
//        XCTAssertEqual(quarter, 4)
//    }
//    
//    // MARK: - Edge Cases Tests
//    
//    func testLeapYear() {
//        // Given
//        let leapYear = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29))!
//        
//        // When
//        let isValid = leapYear.timeIntervalSince1970 > 0
//        
//        // Then
//        XCTAssertTrue(isValid) // 2024 is a leap year, so Feb 29 should be valid
//    }
//    
//    func testEndOfFebruary_LeapYear() {
//        // Given
//        let febStart = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
//        
//        // When
//        let febEnd = febStart.endOfMonth
//        
//        // Then
//        let components = calendar.dateComponents([.day], from: febEnd)
//        XCTAssertEqual(components.day, 29) // 2024 is a leap year
//    }
//    
//    func testEndOfFebruary_NonLeapYear() {
//        // Given
//        let febStart = calendar.date(from: DateComponents(year: 2023, month: 2, day: 1))!
//        
//        // When
//        let febEnd = febStart.endOfMonth
//        
//        // Then
//        let components = calendar.dateComponents([.day], from: febEnd)
//        XCTAssertEqual(components.day, 28) // 2023 is not a leap year
//    }
//    
//    // MARK: - Performance Tests
//    
//    func testFormattingPerformance() {
//        // Given
//        let dates = (0..<1000).map { _ in Date() }
//        
//        // When
//        measure {
//            for date in dates {
//                _ = date.formatted()
//            }
//        }
//        
//        // Then - Should complete within reasonable time
//    }
//    
//    func testDateArithmeticPerformance() {
//        // Given
//        let baseDate = Date()
//        
//        // When
//        measure {
//            for i in 0..<1000 {
//                _ = baseDate.adding(days: i)
//            }
//        }
//        
//        // Then - Should complete within reasonable time
//    }
//    
//    // MARK: - Timezone Tests
//    
//    func testDifferentTimezones() {
//        // Given
//        let utcTimeZone = TimeZone(identifier: "UTC")!
//        let pstTimeZone = TimeZone(identifier: "America/Los_Angeles")!
//        
//        var utcCalendar = Calendar.current
//        utcCalendar.timeZone = utcTimeZone
//        
//        var pstCalendar = Calendar.current
//        pstCalendar.timeZone = pstTimeZone
//        
//        // When
//        let utcStart = utcCalendar.startOfDay(for: testDate)
//        let pstStart = pstCalendar.startOfDay(for: testDate)
//        
//        // Then
//        XCTAssertNotEqual(utcStart, pstStart)
//    }
//}
