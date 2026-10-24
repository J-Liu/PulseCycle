# PulseCycle

A HIIT (High-Intensity Interval Training) interval timer with real-time heart rate monitoring for iOS.

## Features

- **Interval Timer**: Configurable warm-up, work, rest, and cool-down phases
- **Heart Rate Monitoring**: Real-time heart rate display via Bluetooth LE chest straps
- **Profile System**: Save and switch between multiple workout configurations
- **Customizable Settings**:
  - Rounds, work/rest duration, warning timing
  - Start/end/warning sounds
  - Color themes for different phases
  - Voice input support

## Requirements

- iOS 18.6+
- Xcode 27.1+
- Bluetooth LE heart rate monitor (optional)

## Building

Build from command line:

```bash
./build.sh
```

Install to connected device:

```bash
./install.sh
```

## Usage

1. Tap the profile name at the top to select or create workout profiles
2. Configure rounds, durations, and other settings in Settings
3. Tap Go to start the timer
4. Monitor heart rate in real-time (requires BLE chest strap)
5. Tap Pause/Resume to control the workout
6. Tap Reset to stop and reset the timer

## License

Licensed under AGPL-3.0-or-later with additional permissions. See [LICENSE](LICENSE) and [NOTICE](NOTICE) for details.

## Copyright

Copyright 2026 Jia Liu
