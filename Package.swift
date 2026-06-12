// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.calendar",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.calendar",
            targets: [
                "com.awareframework.ios.sensor.calendar"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.calendar",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core", condition: .when(platforms: [.iOS]))
            ],
            path: "Sources/com.awareframework.ios.sensor.calendar"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.calendarTests",
            dependencies: [
                .target(name: "com.awareframework.ios.sensor.calendar")
            ],
            path: "Tests/com.awareframework.ios.sensor.calendarTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
