import Foundation
import GRDB
import com_awareframework_ios_core

public struct CalendarData: BaseDbModelSQLite {
    public static let databaseTableName = "calendarData"
    public static let TABLE_NAME = databaseTableName

    public var id: Int64?
    public var timestamp: Int64
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String = ""
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1

    public var eventIdentifier: String = ""
    public var calendarIdentifier: String = ""
    public var calendarTitle: String = ""
    public var calendarSourceTitle: String = ""
    public var title: String = ""
    public var location: String = ""
    public var notes: String = ""
    public var url: String = ""
    public var startTimestamp: Int64 = 0
    public var endTimestamp: Int64 = 0
    public var isAllDay: Bool = false
    public var availability: Int = 0
    public var status: Int = 0
    public var lastModifiedTimestamp: Int64 = 0

    public init(timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000), label: String = "") {
        self.timestamp = timestamp
        self.label = label
    }

    public init(_ dict: [String: Any]) {
        self.id = dict["id"] as? Int64
        self.timestamp = dict["timestamp"] as? Int64 ?? Int64(Date().timeIntervalSince1970 * 1000)
        self.deviceId = dict["deviceId"] as? String ?? AwareUtils.getCommonDeviceId()
        self.label = dict["label"] as? String ?? ""
        self.timezone = dict["timezone"] as? Int ?? AwareUtils.getTimeZone()
        self.os = dict["os"] as? String ?? "iOS"
        self.jsonVersion = dict["jsonVersion"] as? Int ?? 1
        self.eventIdentifier = dict["eventIdentifier"] as? String ?? ""
        self.calendarIdentifier = dict["calendarIdentifier"] as? String ?? ""
        self.calendarTitle = dict["calendarTitle"] as? String ?? ""
        self.calendarSourceTitle = dict["calendarSourceTitle"] as? String ?? ""
        self.title = dict["title"] as? String ?? ""
        self.location = dict["location"] as? String ?? ""
        self.notes = dict["notes"] as? String ?? ""
        self.url = dict["url"] as? String ?? ""
        self.startTimestamp = dict["startTimestamp"] as? Int64 ?? 0
        self.endTimestamp = dict["endTimestamp"] as? Int64 ?? 0
        self.isAllDay = dict["isAllDay"] as? Bool ?? false
        self.availability = dict["availability"] as? Int ?? 0
        self.status = dict["status"] as? Int ?? 0
        self.lastModifiedTimestamp = dict["lastModifiedTimestamp"] as? Int64 ?? 0
    }

    public func toDictionary() -> [String: Any] {
        [
            "id": id ?? -1,
            "timestamp": timestamp,
            "deviceId": deviceId,
            "label": label,
            "timezone": timezone,
            "os": os,
            "jsonVersion": jsonVersion,
            "eventIdentifier": eventIdentifier,
            "calendarIdentifier": calendarIdentifier,
            "calendarTitle": calendarTitle,
            "calendarSourceTitle": calendarSourceTitle,
            "title": title,
            "location": location,
            "notes": notes,
            "url": url,
            "startTimestamp": startTimestamp,
            "endTimestamp": endTimestamp,
            "isAllDay": isAllDay,
            "availability": availability,
            "status": status,
            "lastModifiedTimestamp": lastModifiedTimestamp,
        ]
    }

    public static func createTable(queue: DatabaseQueue) throws {
        try queue.write { db in
            try db.create(table: databaseTableName, ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("timestamp", .integer).notNull()
                t.column("deviceId", .text).notNull()
                t.column("label", .text).notNull()
                t.column("timezone", .integer).notNull()
                t.column("os", .text).notNull()
                t.column("jsonVersion", .integer).notNull()
                t.column("eventIdentifier", .text).notNull()
                t.column("calendarIdentifier", .text).notNull()
                t.column("calendarTitle", .text).notNull()
                t.column("calendarSourceTitle", .text).notNull()
                t.column("title", .text).notNull()
                t.column("location", .text).notNull()
                t.column("notes", .text).notNull()
                t.column("url", .text).notNull()
                t.column("startTimestamp", .integer).notNull()
                t.column("endTimestamp", .integer).notNull()
                t.column("isAllDay", .boolean).notNull()
                t.column("availability", .integer).notNull()
                t.column("status", .integer).notNull()
                t.column("lastModifiedTimestamp", .integer).notNull()
            }
        }
    }
}
