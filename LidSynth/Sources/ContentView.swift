import SwiftUI

struct ContentView: View {
    @State private var mode: SynthMode = .glide
    @State private var scaleType: ScaleType = .pentatonic
    @State private var instrument: InstrumentType = .theremin
    @State private var volume: Double = 0.22
    @State private var bpm: Double = 120
    @State private var beatFlash = false

    // Display
    @State private var currentAngle: Double = 0
    @State private var currentFreq: Double = 0
    @State private var currentNote: String = "---"
    @State private var waveform: [Float] = []

    // Demo slider
    @State private var demoAngle: Double = 90

    // Output toggles
    @State private var synthEnabled = false
    @State private var midiEnabled = false
    @State private var midiCC: UInt8 = 1

    @State private var prevMidi: Int? = nil

    private let audioEngine = AudioEngine()
    private let midiEngine = MIDIEngine()
    private let sensor = LidSensor()
    private let systemAudio = SystemAudioCapture()
    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // ── Header ──
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "asterisk")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    Text("jakdang.synth")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 4)

                // ── Vinyl Record ──
                VinylView(
                    angle: currentAngle,
                    freq: currentFreq,
                    note: currentNote,
                    isPlaying: currentFreq > 20,
                    instrument: instrument
                )
                .padding(.top, 8)

                // ── Song Info ──
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentNote)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("\(instrument.rawValue) · \(mode.rawValue)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    // Freq + angle badges
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1f Hz", currentFreq))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f°", currentAngle))
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    if mode == .rhythm {
                        Circle()
                            .fill(beatFlash ? Color.red : Color.white.opacity(0.1))
                            .frame(width: 10, height: 10)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // ── Waveform ──
                WaveformView(samples: waveform, freq: currentFreq, isActive: currentFreq > 20)
                    .frame(height: 60)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                // ── Angle Slider (센서 없을 때만 표시) ──
                if !sensor.sensorAvailable {
                    VStack(spacing: 4) {
                        Slider(value: $demoAngle, in: 0...180, step: 0.5)
                            .tint(.red.opacity(0.8))
                        HStack {
                            Text(String(format: "%.0f°", demoAngle))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                            Spacer()
                            Text("180°")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }

                // ── Divider ──
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    .padding(.horizontal, 24).padding(.vertical, 12)

                // ── Mode Buttons (icon style) ──
                HStack(spacing: 0) {
                    modeButton("Glide", icon: "waveform.path", mode: .glide)
                    modeButton("Scale", icon: "pianokeys", mode: .scale)
                    modeButton("Rhythm", icon: "metronome", mode: .rhythm)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)

                // ── Scale (when applicable) ──
                if mode != .glide {
                    HStack(spacing: 6) {
                        ForEach(ScaleType.allCases) { s in
                            Button(s.rawValue) { scaleType = s }
                                .buttonStyle(.plain)
                                .font(.system(size: 11, weight: s == scaleType ? .bold : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(s == scaleType ? Color.red.opacity(0.8) : Color.white.opacity(0.06))
                                )
                                .foregroundColor(s == scaleType ? .white : .gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }

                // ── BPM (rhythm only) ──
                if mode == .rhythm {
                    HStack {
                        Image(systemName: "metronome")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Slider(value: $bpm, in: 40...240, step: 1)
                            .tint(.red.opacity(0.8))
                        Text("\(Int(bpm))")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .frame(width: 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }

                // ── Instrument Row ──
                HStack(spacing: 6) {
                    ForEach(InstrumentType.allCases) { inst in
                        Button(inst.rawValue) { instrument = inst }
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: inst == instrument ? .bold : .regular))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(inst == instrument ? Color.white.opacity(0.15) : Color.white.opacity(0.04))
                            )
                            .foregroundColor(inst == instrument ? .white : .gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 10)

                // ── Volume ──
                HStack(spacing: 8) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Slider(value: $volume, in: 0...0.6)
                        .tint(.white.opacity(0.4))
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // ── Output section ──
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    .padding(.horizontal, 24)

                HStack(spacing: 20) {
                    // Synth toggle
                    outputToggle(
                        icon: "speaker.wave.2.fill",
                        label: "Synth",
                        isOn: $synthEnabled,
                        color: .mint
                    )
                    // MIDI toggle
                    outputToggle(
                        icon: "cable.connector",
                        label: "MIDI",
                        isOn: $midiEnabled,
                        color: .green
                    )
                    Spacer()

                    if midiEnabled {
                        // CC selector
                        Picker("", selection: $midiCC) {
                            Text("Mod").tag(UInt8(1))
                            Text("Vol").tag(UInt8(7))
                            Text("Expr").tag(UInt8(11))
                            Text("Filt").tag(UInt8(74))
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

                if midiEnabled {
                    HStack(spacing: 14) {
                        midiBadge("Note", value: currentNote)
                        midiBadge("CC\(midiCC)", value: "\(Int(currentAngle / 180 * 127))")
                        midiBadge("Ch", value: "1")
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                Spacer(minLength: 16)
            }
        }
        .frame(width: 480, height: 820)
        .background(Color(white: 0.04))
        .onAppear {
            audioEngine.systemAudio = systemAudio
            audioEngine.start()
            Task { await systemAudio.start() }
        }
        .onDisappear {
            audioEngine.stop()
            systemAudio.stop()
            midiEngine.allNotesOff()
        }
        .onReceive(timer) { _ in tick() }
        .onChange(of: mode) { _, val in
            audioEngine.setMode(val)
            midiEngine.allNotesOff()
            prevMidi = nil
        }
        .onChange(of: instrument) { _, val in audioEngine.setHarmonics(val.harmonics) }
        .onChange(of: bpm) { _, val in audioEngine.setBpm(val) }
        .onChange(of: volume) { _, val in audioEngine.setVolume(val) }
        .onChange(of: synthEnabled) { _, val in audioEngine.setMuted(!val) }
        .onChange(of: midiEnabled) { _, val in
            midiEngine.setEnabled(val)
            // MIDI ON → 시스템 오디오 믹싱 활성화
            audioEngine.setMixSystemAudio(val)
        }
    }

    // MARK: - Components

    private func modeButton(_ label: String, icon: String, mode: SynthMode) -> some View {
        Button {
            self.mode = mode
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(self.mode == mode ? .white : .gray.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(self.mode == mode ? Color.white.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func outputToggle(icon: String, label: String, isOn: Binding<Bool>, color: Color) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(isOn.wrappedValue ? color : .gray.opacity(0.4))
        }
        .toggleStyle(.switch)
        .tint(color)
    }

    private func midiBadge(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 4).fill(.green.opacity(0.06)))
    }

    // MARK: - Tick

    private func tick() {
        let angle: Double
        if sensor.sensorAvailable {
            sensor.poll()
            angle = sensor.angle
        } else {
            angle = demoAngle
        }
        currentAngle = angle

        // 시스템 오디오 필터: 힌지 각도로 cutoff 조절
        audioEngine.setFilterAngle(angle)

        switch mode {
        case .glide:
            let freq = angleToFreqGlide(angle)
            audioEngine.setTargetFreq(freq)
            currentFreq = freq
            midiEngine.sendAngleAsCC(angle, controller: midiCC)

        case .scale, .rhythm:
            if let midi = angleToMidi(angle, scale: scaleType) {
                let freq = midiToFreq(midi)
                audioEngine.setTargetFreq(freq)
                currentFreq = freq
                if midi != prevMidi {
                    if mode == .scale { audioEngine.triggerNote() }
                    midiEngine.sendNoteOn(UInt8(clamping: midi))
                }
                prevMidi = midi
            } else {
                audioEngine.setTargetFreq(0)
                audioEngine.releaseNote()
                midiEngine.sendNoteOff()
                currentFreq = 0
                prevMidi = nil
            }
            midiEngine.sendAngleAsCC(angle, controller: midiCC)
        }

        currentNote = freqToNote(currentFreq)
        waveform = audioEngine.copyWaveform()

        if audioEngine.consumeBeatFlash() {
            beatFlash = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { beatFlash = false }
        }
    }
}
