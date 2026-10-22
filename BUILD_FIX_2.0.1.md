# KRYONIX 2.0.1 build fix

Fixed from the first real Xcode 26.6 GitHub Actions compile log:

- Added SwiftUI import for PhotosPickerItem in MediaStore.
- Made UTType.movie and Data.WritingOptions.atomic explicit.
- Rewrote PhotosPicker onChange handlers to the one-argument overload accepted by this build.
- Fixed ChatSettingsSheet navigationTitle modifier placement.
- Restored AnimatedOrbBackground used by Splash/Onboarding/Lock.
- Replaced invalid `.caption2.black()` with `.caption2.weight(.black)`.
- Updated Bluetooth option to allowBluetoothHFP.
- Workflow now always uploads full `xcodebuild.log` and a compact `build-summary.txt`, even on failure.

Static Swift parser + YAML checks pass in the current environment. Final type-check/link is done by GitHub Xcode.
