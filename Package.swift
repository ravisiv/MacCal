// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacCal",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacCal", targets: ["MacCal"])
    ],
    targets: [
        .executableTarget(
            name: "MacCal",
            path: "Sources/MacCal",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("EventKit"),
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/MacCal/Info.plist"
                ])
            ]
        ),
        .testTarget(
            name: "MacCalTests",
            dependencies: ["MacCal"]
        )
    ]
)
