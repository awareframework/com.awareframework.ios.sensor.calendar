# Aware Calendar

`com.awareframework.ios.sensor.calendar` is an AWARE Framework sensor plugin for reading iOS Calendar events through EventKit.

## Usage

Add calendar usage descriptions to the host app's `Info.plist`.

- `NSCalendarsUsageDescription` for iOS 16 and earlier.
- `NSCalendarsFullAccessUsageDescription` for iOS 17 and later.

```swift
let sensor = CalendarSensor(CalendarSensor.Config().apply { config in
    config.pastDays = 30
    config.futureDays = 30
    config.includeNotes = false
})

sensor.start()
sensor.sync()
sensor.stop()
```

`includeNotes` defaults to `false` because calendar notes often contain sensitive text.
