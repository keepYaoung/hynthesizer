// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LidSynth",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "LidSynth",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreMIDI"),
                .linkedFramework("IOKit"),
                .linkedFramework("ScreenCaptureKit"),
            ]
        )
    ]
)
