import Foundation

/// macOS lid angle sensor via pybooklid (Python bridge).
/// Python 프로세스가 센서를 읽어 stdout으로 각도를 보내줌.
final class LidSensor {
    private(set) var sensorAvailable = false
    private var currentAngle: Double = 90
    private var process: Process?
    private var running = false

    init() {
        startBridge()
    }

    deinit {
        stop()
    }

    // MARK: - Public

    var angle: Double { currentAngle }

    func poll() {
        // currentAngle is updated by the background reader thread
    }

    func setAngle(_ a: Double) {
        currentAngle = max(0, min(180, a))
    }

    func stop() {
        running = false
        process?.terminate()
        process = nil
    }

    // MARK: - Python Bridge

    private func startBridge() {
        // Find the venv python with pybooklid installed
        let candidates = [
            // Relative to the app's parent (dev build)
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()  // Sources/
                .deletingLastPathComponent()  // LidSynth/
                .deletingLastPathComponent()  // lid-synth/
                .appendingPathComponent(".venv/bin/python3").path,
            // Absolute fallback
            NSHomeDirectory() + "/Downloads/0000 Git repository/lid-synth/.venv/bin/python3",
        ]

        var pythonPath: String?
        for c in candidates {
            if FileManager.default.fileExists(atPath: c) {
                pythonPath = c
                break
            }
        }

        guard let python = pythonPath else {
            fputs("[Sensor] Python venv not found — demo mode\n", stderr)
            sensorAvailable = false
            return
        }

        let script = """
        import sys, time
        try:
            from pybooklid import LidSensor
            s = LidSensor()
            while True:
                print(s.read_angle(), flush=True)
                time.sleep(0.04)
        except Exception as e:
            print(f"ERROR:{e}", flush=True)
            sys.exit(1)
        """

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: python)
        proc.arguments = ["-c", script]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice

        do {
            try proc.run()
        } catch {
            fputs("[Sensor] Failed to start Python bridge: \(error)\n", stderr)
            sensorAvailable = false
            return
        }

        process = proc
        running = true
        sensorAvailable = true
        fputs("[Sensor] Python bridge started — lid angle active\n", stderr)

        // Background thread to read angle values
        let handle = pipe.fileHandleForReading
        Thread.detachNewThread { [weak self] in
            var buffer = ""
            while self?.running == true {
                let data = handle.availableData
                guard !data.isEmpty else { break }
                buffer += String(data: data, encoding: .utf8) ?? ""

                // Process complete lines
                while let newline = buffer.firstIndex(of: "\n") {
                    let line = String(buffer[buffer.startIndex..<newline]).trimmingCharacters(in: .whitespaces)
                    buffer = String(buffer[buffer.index(after: newline)...])

                    if line.hasPrefix("ERROR:") {
                        fputs("[Sensor] \(line)\n", stderr)
                        self?.sensorAvailable = false
                        return
                    }

                    if let val = Double(line) {
                        self?.currentAngle = max(0, min(180, val))
                    }
                }
            }
        }
    }
}
