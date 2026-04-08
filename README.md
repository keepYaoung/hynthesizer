# hyn*thesizer

맥북 덮개 각도로 연주하는 신디사이저.

힌지를 열고 닫으면 피치가 바뀌고, LP 레코드가 회전하며, 시스템 오디오에 필터를 걸 수 있습니다.

## 기능

### 3가지 연주 모드
- **Glide** - 테레민처럼 연속 피치 변화
- **Scale** - 음계 스텝 + ADSR 엔벨로프 (Pentatonic / Major / Minor / Blues)
- **Rhythm** - BPM 클럭에 맞춰 자동 트리거 (40~240 BPM)

### 5가지 악기 음색
Theremin, Flute, Organ, String, Brass (가법 합성, 하모닉스 기반)

### LP 바이닐 UI
- 힌지 각도에 따라 LP가 실시간 회전
- 톤암이 각도에 맞춰 이동
- 레드 레이블에 현재 음정/악기/주파수 표시
- 실시간 웨이브폼 시각화

### MIDI 출력
가상 MIDI 포트 "LidSynth"를 생성하여 DAW(Ableton, Logic, GarageBand 등)에서 인식 가능.
- Note On/Off (Scale/Rhythm 모드)
- CC 전송 (Mod Wheel / Volume / Expression / Filter)
- 힌지 각도 → MIDI CC 값 (0-127) 매핑

### 시스템 오디오 믹싱
ScreenCaptureKit으로 맥에서 재생 중인 음악을 캡처하여 믹싱.
- 힌지 각도로 로우패스 필터 cutoff 조절 (닫으면 먹먹, 열면 선명)
- 신스 사운드와 동시 믹스 가능

### Output 조합

| Synth | MIDI | 동작 |
|-------|------|------|
| ON | ON | 신스 + 시스템 오디오 믹스 |
| OFF | ON | 시스템 오디오에 힌지 필터 적용 |
| ON | OFF | 신스만 |
| OFF | OFF | 무음 (시작 기본값) |

## 요구사항

- macOS 14.0+
- Swift 5.9+

### macOS 권한
- **화면 녹화** - 시스템 오디오 캡처 시 필요 (시스템 설정 > 개인정보 보호 > 화면 녹화)

## 빌드 및 실행

```bash
cd LidSynth
swift build
.build/debug/LidSynth
```

## 구조

```
hynthesizer/
├── lid_synth.py                 # Python 원본 (tkinter)
├── LidSynth/                    # Swift macOS 앱
│   ├── Package.swift
│   └── Sources/
│       ├── LidSynthApp.swift    # 앱 진입점
│       ├── ContentView.swift    # 메인 UI + 로직
│       ├── VinylView.swift      # LP 레코드 + 톤암
│       ├── WaveformView.swift   # 실시간 파형
│       ├── GaugeView.swift      # 반원형 게이지
│       ├── AudioEngine.swift    # 가법 합성 + ADSR + 믹싱
│       ├── MIDIEngine.swift     # CoreMIDI 가상 포트
│       ├── LidSensor.swift      # IOKit HID 네이티브 센서
│       ├── SystemAudioCapture.swift  # ScreenCaptureKit
│       └── Models.swift         # 상수, 음계, 악기, 유틸
└── README.md
```

## 라이선스

MIT
