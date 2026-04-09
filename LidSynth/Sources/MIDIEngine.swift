import CoreMIDI
import Foundation

/// Virtual MIDI source — DAW에서 "LidSynth" 포트로 인식됨.
final class MIDIEngine {
    private var client = MIDIClientRef()
    private var source = MIDIEndpointRef()
    private var isSetup = false

    // State tracking
    private var lastNote: UInt8? = nil
    private var lastCCValues: [UInt8: UInt8] = [:]
    private var enabled = false

    private let channel: UInt8 = 0

    init() {
        setup()
    }

    // MARK: - Setup

    private func setup() {
        var status = MIDIClientCreateWithBlock("LidSynth.client" as CFString, &client) { _ in }
        guard status == noErr else {
            fputs("[MIDI] Client creation failed: \(status)\n", stderr)
            return
        }

        status = MIDISourceCreateWithProtocol(
            client,
            "LidSynth" as CFString,
            ._1_0,
            &source
        )
        guard status == noErr else {
            fputs("[MIDI] Source creation failed: \(status)\n", stderr)
            return
        }

        isSetup = true
        fputs("[MIDI] Virtual source 'LidSynth' created\n", stderr)
    }

    // MARK: - Public

    func setEnabled(_ on: Bool) { enabled = on }

    func sendNoteOn(_ note: UInt8, velocity: UInt8 = 100) {
        guard isSetup, enabled else { return }
        if let prev = lastNote {
            sendRaw(status: 0x80 | channel, data1: prev, data2: 0)
        }
        sendRaw(status: 0x90 | channel, data1: note, data2: velocity)
        lastNote = note
    }

    func sendNoteOff() {
        guard isSetup, enabled, let note = lastNote else { return }
        sendRaw(status: 0x80 | channel, data1: note, data2: 0)
        lastNote = nil
    }

    func sendCC(controller: UInt8, value: UInt8) {
        guard isSetup, enabled else { return }
        if lastCCValues[controller] == value { return }
        lastCCValues[controller] = value
        sendRaw(status: 0xB0 | channel, data1: controller, data2: value)
    }

    func sendAngleAsCC(_ angle: Double, controller: UInt8 = 1) {
        let clamped = max(0, min(180, angle))
        let value = UInt8(clamped / 180.0 * 127.0)
        sendCC(controller: controller, value: value)
    }

    func allNotesOff() {
        sendNoteOff()
        sendCC(controller: 123, value: 0)
    }

    // MARK: - Raw MIDI send (MIDIEventList builder API)

    private func sendRaw(status: UInt8, data1: UInt8, data2: UInt8) {
        let word: UInt32 =
            UInt32(0x20) << 24 |
            UInt32(status) << 16 |
            UInt32(data1) << 8 |
            UInt32(data2)

        // Use MIDIEventListAdd for safe packet construction
        let bufferSize = 256
        let buffer = UnsafeMutablePointer<MIDIEventList>.allocate(capacity: 1)
        defer { buffer.deallocate() }

        var packet = MIDIEventListInit(buffer, ._1_0)
        packet = MIDIEventListAdd(buffer, bufferSize, packet, mach_absolute_time(), 1, [word])

        MIDIReceivedEventList(source, buffer)
    }
}
