import Foundation

// MARK: - Constants
let kSampleRate: Double = 44100
let kBlockSize: Int = 512
let kAngleMin: Double = 15
let kAngleMax: Double = 175
let kBaseMidi: Int = 48 // C3

// MARK: - Synth Mode
enum SynthMode: String, CaseIterable, Identifiable {
    case glide  = "Glide"
    case scale  = "Scale"
    case rhythm = "Rhythm"
    var id: String { rawValue }
}

// MARK: - Scale
enum ScaleType: String, CaseIterable, Identifiable {
    case pentatonic = "Pentatonic"
    case major      = "Major"
    case minor      = "Minor"
    case blues      = "Blues"
    var id: String { rawValue }

    var intervals: [Int] {
        switch self {
        case .pentatonic: [0, 2, 4, 7, 9]
        case .major:      [0, 2, 4, 5, 7, 9, 11]
        case .minor:      [0, 2, 3, 5, 7, 8, 10]
        case .blues:      [0, 3, 5, 6, 7, 10]
        }
    }
}

// MARK: - Instrument
enum InstrumentType: String, CaseIterable, Identifiable {
    case theremin = "Theremin"
    case flute    = "Flute"
    case organ    = "Organ"
    case string   = "String"
    case brass    = "Brass"
    var id: String { rawValue }

    var harmonics: [Double] {
        let raw: [Double]
        switch self {
        case .theremin: raw = [0.55, 0.25, 0.12, 0.06, 0.02]
        case .flute:    raw = [0.85, 0.10, 0.04, 0.01]
        case .organ:    raw = [0.40, 0.38, 0.30, 0.20, 0.12, 0.06, 0.03]
        case .string:   raw = [0.45, 0.35, 0.25, 0.15, 0.08, 0.04]
        case .brass:    raw = [0.35, 0.05, 0.30, 0.05, 0.25, 0.05, 0.15, 0.05, 0.08]
        }
        let total = raw.reduce(0, +)
        return raw.map { $0 / total }
    }
}

// MARK: - Envelope Phase
enum EnvPhase {
    case idle, attack, decay, sustain, release
}

// MARK: - Pitch Helpers
func angleToFreqGlide(_ angle: Double) -> Double {
    guard angle >= kAngleMin else { return 0 }
    let r = min((angle - kAngleMin) / (kAngleMax - kAngleMin), 1.0)
    return 130.81 * pow(1046.50 / 130.81, r)
}

func angleToMidi(_ angle: Double, scale: ScaleType) -> Int? {
    guard angle >= kAngleMin else { return nil }
    let intervals = scale.intervals
    let r = min((angle - kAngleMin) / (kAngleMax - kAngleMin), 1.0)
    let total = intervals.count * 3
    let step = Int((r * Double(total - 1)).rounded())
    return kBaseMidi + (step / intervals.count) * 12 + intervals[step % intervals.count]
}

func midiToFreq(_ midi: Int) -> Double {
    440.0 * pow(2.0, Double(midi - 69) / 12.0)
}

func freqToNote(_ freq: Double) -> String {
    guard freq >= 20 else { return "---" }
    let notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    let n = Int((12.0 * log2(freq / 440.0)).rounded()) + 69
    let octave = n / 12 - 1
    return "\(notes[((n % 12) + 12) % 12])\(octave)"
}
