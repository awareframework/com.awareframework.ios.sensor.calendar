# Aware Calendar

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)

`com.awareframework.ios.sensor.calendar` is an AWARE Framework sensor plugin for reading iOS Calendar events through EventKit.

## Requirements
iOS 13 or later

## Installation

1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...`

2. Find the package using the manager
    * Select `Search Package URL` and type `https://github.com/awareframework/com.awareframework.ios.sensor.calendar.git`

3. Import the package into your target.

4. Add calendar usage descriptions to the host app's `Info.plist`:
    * `NSCalendarsUsageDescription` — required for iOS 16 and earlier.
    * `NSCalendarsFullAccessUsageDescription` — required for iOS 17 and later.

## Public functions

### CalendarSensor

+ `init(_ config: CalendarSensor.Config)`: Initializes the sensor with the given configuration.
+ `start()`: Requests EventKit calendar authorization and loads events from the configured time window. Registers a change observer to reload on subsequent calendar changes.
+ `stop()`: Removes the calendar change observer.
+ `sync(force:)`: Syncs stored data to the configured host.
+ `set(label:)`: Sets a custom label applied to all subsequent data points.

### CalendarSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: CalendarObserver?`: Callback for live data updates.
+ `pastDays: Int`: Number of days before now to include when collecting calendar events. (default = `30`)
+ `futureDays: Int`: Number of days after now to include when collecting calendar events. (default = `30`)
+ `includeNotes: Bool`: When `false`, event notes are omitted because they often contain sensitive text. (default = `false`)
+ `enabled: Bool`: Sensor is enabled or not. (default = `false`)
+ `debug: Bool`: Enable/disable logging. (default = `false`)
+ `label: String`: Label for the data. (default = "")
+ `deviceId: String`: Id of the device associated with the events. (default = "")
+ `dbEncryptionKey`: Encryption key for the database. (default = `nil`)
+ `dbType: Engine`: Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String`: Path of the database. (default = "aware_calendar")
+ `dbHost: String`: Host for syncing the database. (default = `nil`)

## Broadcasts

### Fired Broadcasts

+ `CalendarSensor.ACTION_AWARE_CALENDAR`: fired when calendar data is saved to the database.
+ `CalendarSensor.ACTION_AWARE_CALENDAR_CHANGED`: fired when the EventKit store reports a change and data is reloaded.

### Received Broadcasts

+ `CalendarSensor.ACTION_AWARE_CALENDAR_START`: received broadcast to start the sensor.
+ `CalendarSensor.ACTION_AWARE_CALENDAR_STOP`: received broadcast to stop the sensor.
+ `CalendarSensor.ACTION_AWARE_CALENDAR_SYNC`: received broadcast to send sync attempt to the host.
+ `CalendarSensor.ACTION_AWARE_CALENDAR_SET_LABEL`: received broadcast to set the data label.

## Data Representations

### CalendarData

Contains metadata for a calendar event.

| Field                  | Type   | Description                                                                 |
| ---------------------- | ------ | --------------------------------------------------------------------------- |
| eventIdentifier        | String | EKEvent.eventIdentifier — unique identifier for the event                   |
| calendarIdentifier     | String | EKCalendar.calendarIdentifier of the calendar containing this event         |
| calendarTitle          | String | Display title of the calendar                                               |
| calendarSourceTitle    | String | Title of the calendar source (e.g., iCloud, Google)                         |
| title                  | String | Event title                                                                 |
| location               | String | Event location string                                                       |
| notes                  | String | Event notes (empty string when `includeNotes` is `false`)                  |
| url                    | String | URL associated with the event                                               |
| startTimestamp         | Int64  | Event start time as Unix milliseconds                                       |
| endTimestamp           | Int64  | Event end time as Unix milliseconds                                         |
| isAllDay               | Bool   | Whether the event spans an entire day                                       |
| availability           | Int    | EKEventAvailability raw value: 0=notSupported, 1=busy, 2=free, 3=tentative, 4=unavailable |
| status                 | Int    | EKEventStatus raw value: 0=none, 1=confirmed, 2=tentative, 3=cancelled      |
| lastModifiedTimestamp  | Int64  | Event last modification time as Unix milliseconds                           |
| label                  | String | Customizable label. Useful for data calibration or traceability             |
| deviceId               | String | AWARE device UUID                                                           |
| timestamp              | Int64  | Unixtime milliseconds when the record was saved                             |
| timezone               | Int    | Timezone of the device                                                      |
| os                     | String | Operating system of the device (iOS)                                        |
| jsonVersion            | Int    | JSON schema version                                                         |

## Example usage

```swift
import com_awareframework_ios_sensor_calendar
```

```swift
let sensor = CalendarSensor(CalendarSensor.Config().apply { config in
    config.sensorObserver = Observer()
    config.pastDays = 30
    config.futureDays = 30
    config.includeNotes = false
    config.debug = true
})

sensor.start()

// Later...
sensor.stop()
```

```swift
class Observer: CalendarObserver {
    func onCalendarChanged(data: [CalendarData]) {
        print("Calendar updated:", data.count, "events")
    }
}
```

## Author
Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp

## Related Links
* [Apple | EventKit](https://developer.apple.com/documentation/eventkit)
* [Apple | Requesting Access to Calendars](https://developer.apple.com/documentation/eventkit/requesting_access_to_calendars)

## License
Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
