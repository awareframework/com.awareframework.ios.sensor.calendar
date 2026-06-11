//
//  CalendarSensor.swift
//  com.aware.ios.sensor.calendar
//
//  Created by Yuuki Nishiyama on 2026/06/10.
//

import EventKit
import Foundation
import com_awareframework_ios_core

extension Notification.Name {
    public static let actionAwareCalendar = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR)
    public static let actionAwareCalendarStart = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_START)
    public static let actionAwareCalendarStop = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_STOP)
    public static let actionAwareCalendarSync = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_SYNC)
    public static let actionAwareCalendarSyncCompletion = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_SYNC_COMPLETION)
    public static let actionAwareCalendarSetLabel = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_SET_LABEL)
    public static let actionAwareCalendarChanged = Notification.Name(CalendarSensor.ACTION_AWARE_CALENDAR_CHANGED)
}

public protocol CalendarObserver {
    func onCalendarChanged(data: [CalendarData])
}

public class CalendarSensor: AwareSensor {

    public static let TAG = "AWARE::Calendar"

    public static let ACTION_AWARE_CALENDAR = "com.awareframework.ios.sensor.calendar"
    public static let ACTION_AWARE_CALENDAR_START = "com.awareframework.ios.sensor.calendar.SENSOR_START"
    public static let ACTION_AWARE_CALENDAR_STOP = "com.awareframework.ios.sensor.calendar.SENSOR_STOP"
    public static let ACTION_AWARE_CALENDAR_SET_LABEL = "com.awareframework.ios.sensor.calendar.SET_LABEL"
    public static let ACTION_AWARE_CALENDAR_SYNC = "com.awareframework.ios.sensor.calendar.SENSOR_SYNC"
    public static let ACTION_AWARE_CALENDAR_SYNC_COMPLETION = "com.awareframework.ios.sensor.calendar.SENSOR_SYNC_COMPLETION"
    public static let ACTION_AWARE_CALENDAR_CHANGED = "com.awareframework.ios.sensor.calendar.ACTION_AWARE_CALENDAR_CHANGED"

    public static let EXTRA_LABEL = "label"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_TABLE_NAME = "tableName"

    public var CONFIG = Config()

    private let eventStore = EKEventStore()
    private let workQueue = DispatchQueue(label: "com.awareframework.ios.sensor.calendar.work", qos: .utility)
    private var isStarted = false

    public class Config: SensorConfig {
        public var sensorObserver: CalendarObserver?

        /// Number of days before now to include when collecting calendar events.
        public var pastDays: Int = 30

        /// Number of days after now to include when collecting calendar events.
        public var futureDays: Int = 30

        /// When false, event notes are omitted because they often contain sensitive text.
        public var includeNotes: Bool = false

        public override init() {
            super.init()
            dbPath = "aware_calendar"
        }

        public override func set(config: [String: Any]) {
            super.set(config: config)
            if let pastDays = config["pastDays"] as? Int {
                self.pastDays = pastDays
            }
            if let futureDays = config["futureDays"] as? Int {
                self.futureDays = futureDays
            }
            if let includeNotes = config["includeNotes"] as? Bool {
                self.includeNotes = includeNotes
            }
        }

        public func apply(closure: (_ config: CalendarSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }

    public override convenience init() {
        self.init(CalendarSensor.Config())
    }

    public init(_ config: CalendarSensor.Config) {
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        super.syncConfig = DbSyncConfig().apply { syncConfig in
            syncConfig.serverType = config.serverType
            syncConfig.debug = config.debug
            syncConfig.batchSize = 1000
            syncConfig.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.calendar.sync.queue")
            syncConfig.completionHandler = { [weak self] status, error in
                guard let self else { return }
                var userInfo: [String: Any] = [CalendarSensor.EXTRA_STATUS: status]
                if let error { userInfo[CalendarSensor.EXTRA_ERROR] = error }
                self.notificationCenter.post(name: .actionAwareCalendarSyncCompletion, object: self, userInfo: userInfo)
            }
        }
        initializeTables()
    }

    deinit {
        notificationCenter.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
    }

    public override func start() {
        requestCalendarAccess { [weak self] granted in
            guard let self else { return }
            guard granted else {
                if self.CONFIG.debug {
                    print(CalendarSensor.TAG, "Calendar access denied or restricted.")
                }
                return
            }

            self.notificationCenter.addObserver(
                self,
                selector: #selector(self.eventStoreChanged(_:)),
                name: .EKEventStoreChanged,
                object: self.eventStore
            )
            self.isStarted = true
            self.collectAndSaveEvents()
            self.notificationCenter.post(name: .actionAwareCalendarStart, object: self)
        }
    }

    public override func stop() {
        notificationCenter.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
        isStarted = false
        notificationCenter.post(name: .actionAwareCalendarStop, object: self)
    }

    public override func sync(force: Bool = false) {
        guard let syncConfig = super.syncConfig else { return }
        notificationCenter.post(name: .actionAwareCalendarSync, object: self)

        let engine = Engine.Builder()
            .setPath(CONFIG.dbPath)
            .setType(CONFIG.dbType)
            .setHost(CONFIG.dbHost)
            .setEncryptionKey(CONFIG.dbEncryptionKey)
            .setTableName(CalendarData.TABLE_NAME)
            .build()

        let config = DbSyncConfig()
        config.removeAfterSync = syncConfig.removeAfterSync
        config.batchSize = syncConfig.batchSize
        config.markAsSynced = syncConfig.markAsSynced
        config.skipSyncedData = syncConfig.skipSyncedData
        config.keepLastData = syncConfig.keepLastData
        config.deviceId = syncConfig.deviceId
        config.debug = syncConfig.debug
        config.debugLevel = syncConfig.debugLevel
        config.progressHandler = syncConfig.progressHandler
        config.dispatchQueue = syncConfig.dispatchQueue
        config.backgroundSession = syncConfig.backgroundSession
        config.compactDataFormat = syncConfig.compactDataFormat
        config.serverType = syncConfig.serverType
        config.test = syncConfig.test
        config.completionHandler = { [weak self] status, error in
            guard let self else { return }
            var userInfo: [String: Any] = [
                CalendarSensor.EXTRA_STATUS: status,
                CalendarSensor.EXTRA_TABLE_NAME: CalendarData.TABLE_NAME,
                CalendarSensor.EXTRA_OBJECT_TYPE: CalendarData.self,
            ]
            if let error { userInfo[CalendarSensor.EXTRA_ERROR] = error }
            self.notificationCenter.post(name: .actionAwareCalendarSyncCompletion, object: self, userInfo: userInfo)
            syncConfig.completionHandler?(status, error)
        }
        engine.startSync(config)
    }

    public override func set(label: String) {
        CONFIG.label = label
        notificationCenter.post(
            name: .actionAwareCalendarSetLabel,
            object: self,
            userInfo: [CalendarSensor.EXTRA_LABEL: label]
        )
    }

    public func collectAndSaveEvents() {
        workQueue.async { [weak self] in
            guard let self else { return }
            let data = self.collectEvents()
            guard data.isEmpty == false else { return }
            self.saveModels(data)
            self.CONFIG.sensorObserver?.onCalendarChanged(data: data)
            self.notificationCenter.post(name: .actionAwareCalendarChanged, object: self)
        }
    }

    @objc private func eventStoreChanged(_ notification: Notification) {
        guard isStarted else { return }
        collectAndSaveEvents()
    }

    private func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            completion(true)
        case .fullAccess:
            completion(true)
        case .writeOnly:
            completion(false)
        case .notDetermined:
            if #available(iOS 17.0, *) {
                eventStore.requestFullAccessToEvents { granted, error in
                    if let error, self.CONFIG.debug {
                        print(CalendarSensor.TAG, "Calendar permission error:", error)
                    }
                    completion(granted)
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error, self.CONFIG.debug {
                        print(CalendarSensor.TAG, "Calendar permission error:", error)
                    }
                    completion(granted)
                }
            }
        case .restricted, .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func collectEvents() -> [CalendarData] {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -max(0, CONFIG.pastDays), to: now) ?? now
        let endDate = Calendar.current.date(byAdding: .day, value: max(0, CONFIG.futureDays), to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)
        let timestamp = Int64(Date().timeIntervalSince1970 * 1000)

        return events.map { event in
            var data = CalendarData(timestamp: timestamp, label: CONFIG.label)
            data.eventIdentifier = event.eventIdentifier ?? ""
            data.calendarIdentifier = event.calendar.calendarIdentifier
            data.calendarTitle = event.calendar.title
            data.calendarSourceTitle = event.calendar.source.title
            data.title = event.title ?? ""
            data.location = event.location ?? ""
            data.notes = CONFIG.includeNotes ? (event.notes ?? "") : ""
            data.url = event.url?.absoluteString ?? ""
            data.startTimestamp = Int64(event.startDate.timeIntervalSince1970 * 1000)
            data.endTimestamp = Int64(event.endDate.timeIntervalSince1970 * 1000)
            data.isAllDay = event.isAllDay
            data.availability = event.availability.rawValue
            data.status = event.status.rawValue
            if let lastModifiedDate = event.lastModifiedDate {
                data.lastModifiedTimestamp = Int64(lastModifiedDate.timeIntervalSince1970 * 1000)
            }
            return data
        }
    }

    private func initializeTables() {
        guard let queue = (dbEngine as? SQLiteEngine)?.getSQLiteInstance() else { return }
        do {
            try CalendarData.createTable(queue: queue)
        } catch {
            if CONFIG.debug { print(CalendarSensor.TAG, "DB init error:", error) }
        }
    }

    private func saveModels<T: BaseDbModelSQLite>(_ models: [T]) {
        guard let engine = dbEngine as? SQLiteEngine else { return }
        engine.save(models)
    }
}
