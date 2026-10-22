# KRYONIX 2.0 static validation

This environment does not contain Xcode/iOS SDK, so an actual iOS link/run cannot be performed here.

Static checks performed before packaging:
- Swift parser run across all `.swift` files
- project.yml YAML parse
- GitHub workflow YAML parse
- Empty `Button {}` action scan
- Expected project folders/files existence check

Functional design review:
- Splash/onboarding prevents an empty white first-run experience
- Face ID/device-auth lock is optional
- Album destructive actions use Recently Deleted before permanent deletion
- Chat supports persistent local message actions
- Story supports local creation/view/archive/highlight flow
- Map never fabricates partner location
- Life Hub data is persisted with SwiftData

Final compile/run validation must happen on the GitHub macOS/Xcode runner and then on a real iPhone.
