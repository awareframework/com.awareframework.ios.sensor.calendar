import XCTest
import com_awareframework_ios_sensor_calendar

class Tests: XCTestCase {

    func testControllers() {
        let sensor = CalendarSensor()
        sensor.CONFIG.debug = true

        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(
            forName: .actionAwareCalendarSetLabel,
            object: nil,
            queue: .main
        ) { notification in
            let dict = notification.userInfo as? [String: String]
            XCTAssertEqual(dict?[CalendarSensor.EXTRA_LABEL], newLabel)
            expectSetLabel.fulfill()
        }
        sensor.set(label: newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)

        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(
            forName: .actionAwareCalendarSync,
            object: nil,
            queue: .main
        ) { _ in expectSync.fulfill() }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)

        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(
            forName: .actionAwareCalendarStop,
            object: nil,
            queue: .main
        ) { _ in expectStop.fulfill() }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
    }

    func testCalendarDataDefaults() {
        let data = CalendarData()
        let dict = data.toDictionary()

        XCTAssertEqual(dict["eventIdentifier"] as? String, "")
        XCTAssertEqual(dict["calendarIdentifier"] as? String, "")
        XCTAssertEqual(dict["calendarTitle"] as? String, "")
        XCTAssertEqual(dict["calendarSourceTitle"] as? String, "")
        XCTAssertEqual(dict["title"] as? String, "")
        XCTAssertEqual(dict["location"] as? String, "")
        XCTAssertEqual(dict["notes"] as? String, "")
        XCTAssertEqual(dict["url"] as? String, "")
        XCTAssertEqual(dict["startTimestamp"] as? Int64, 0)
        XCTAssertEqual(dict["endTimestamp"] as? Int64, 0)
        XCTAssertEqual(dict["isAllDay"] as? Bool, false)
        XCTAssertEqual(dict["availability"] as? Int, 0)
        XCTAssertEqual(dict["status"] as? Int, 0)
        XCTAssertEqual(dict["lastModifiedTimestamp"] as? Int64, 0)
    }

    func testCalendarDataDictInit() {
        let source: [String: Any] = [
            "eventIdentifier": "event-1",
            "calendarIdentifier": "calendar-1",
            "calendarTitle": "Work",
            "calendarSourceTitle": "iCloud",
            "title": "Meeting",
            "location": "Room 1",
            "notes": "Agenda",
            "url": "https://example.com",
            "startTimestamp": Int64(1_700_000_000_000),
            "endTimestamp": Int64(1_700_003_600_000),
            "isAllDay": true,
            "availability": 1,
            "status": 2,
            "lastModifiedTimestamp": Int64(1_700_000_100_000),
        ]

        let data = CalendarData(source)
        XCTAssertEqual(data.eventIdentifier, "event-1")
        XCTAssertEqual(data.calendarIdentifier, "calendar-1")
        XCTAssertEqual(data.calendarTitle, "Work")
        XCTAssertEqual(data.calendarSourceTitle, "iCloud")
        XCTAssertEqual(data.title, "Meeting")
        XCTAssertEqual(data.location, "Room 1")
        XCTAssertEqual(data.notes, "Agenda")
        XCTAssertEqual(data.url, "https://example.com")
        XCTAssertEqual(data.startTimestamp, 1_700_000_000_000)
        XCTAssertEqual(data.endTimestamp, 1_700_003_600_000)
        XCTAssertTrue(data.isAllDay)
        XCTAssertEqual(data.availability, 1)
        XCTAssertEqual(data.status, 2)
        XCTAssertEqual(data.lastModifiedTimestamp, 1_700_000_100_000)
    }
}
