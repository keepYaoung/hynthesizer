import Foundation
import IOKit.hid

/// macOS lid angle sensor — IOKit HID 네이티브 구현.
/// Apple MacBook 힌지 센서(HID Orientation Sensor)에서 직접 각도를 읽음.
/// 매 폴링마다 디바이스를 열고 닫아야 최신 값을 받을 수 있음.
final class LidSensor {
    private(set) var sensorAvailable = false
    private var currentAngle: Double = 90
    private var running = false

    // HID matching criteria (Apple MacBook sensor hub)
    private static let vendorID:  Int = 0x05AC
    private static let productID: Int = 0x8104
    private static let usagePage: Int = 0x0020  // HID Sensor page
    private static let usage:     Int = 0x008A  // Orientation sensor

    init() {
        // Verify sensor exists, then start polling
        if probeSensor() {
            sensorAvailable = true
            running = true
            fputs("[Sensor] IOKit HID sensor found — lid angle active\n", stderr)
            startPolling()
        } else {
            fputs("[Sensor] No lid angle sensor found — demo mode\n", stderr)
        }
    }

    deinit {
        stop()
    }

    // MARK: - Public

    var angle: Double { currentAngle }

    func poll() {
        // currentAngle is updated by the background polling thread
    }

    func setAngle(_ a: Double) {
        currentAngle = max(0, min(180, a))
    }

    func stop() {
        running = false
    }

    // MARK: - IOKit HID

    /// Check if the sensor exists on this machine.
    private func probeSensor() -> Bool {
        return Self.readAngleOnce() != nil
    }

    /// Start background thread that polls the sensor.
    private func startPolling() {
        Thread.detachNewThread { [weak self] in
            while self?.running == true {
                if let angle = Self.readAngleOnce() {
                    self?.currentAngle = max(0, min(180, Double(angle)))
                }
                Thread.sleep(forTimeInterval: 0.04)  // ~25 Hz
            }
        }
    }

    /// Open device, read feature report, close device — each call returns fresh angle.
    private static func readAngleOnce() -> Int? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let matching: [String: Any] = [
            kIOHIDVendorIDKey as String:        vendorID,
            kIOHIDProductIDKey as String:       productID,
            kIOHIDPrimaryUsagePageKey as String: usagePage,
            kIOHIDPrimaryUsageKey as String:     usage,
        ]
        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let dev = deviceSet.first else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return nil
        }

        guard IOHIDDeviceOpen(dev, IOOptionBits(kIOHIDOptionsTypeSeizeDevice)) == kIOReturnSuccess else {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            return nil
        }

        var report = [UInt8](repeating: 0, count: 8)
        var len = CFIndex(8)
        let result = IOHIDDeviceGetReport(dev, kIOHIDReportTypeFeature, CFIndex(1), &report, &len)

        IOHIDDeviceClose(dev, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        guard result == kIOReturnSuccess, len >= 3 else { return nil }

        let raw = Int(UInt16(report[2]) << 8 | UInt16(report[1]))
        return raw
    }
}
