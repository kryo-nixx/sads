# KRYONIX 2.0

Native SwiftUI iOS 17 app source.

## Important about size

The repository being a few hundred KB is normal: it is source code.
System frameworks such as SwiftUI, MapKit, PhotosUI, AVFoundation and LocalAuthentication
are linked by iOS/Xcode and are not copied into this repository as giant files.

Do not pad the IPA with fake assets just to reach 100-200 MB.
KRYONIX will naturally grow through real user media, thumbnails, video/audio and cache.

## Added in 2.0

### Launch / first run
- Animated KRYONIX splash
- 3-page onboarding
- Optional Face ID / device-passcode lock
- No empty white first screen

### Home
- Relationship counter
- Anniversary countdown
- Story tray
- On This Day
- Global search
- Quick navigation
- Life Hub card
- Stats and animated background

### Life Hub
- Shared diary
- Daily mood log
- Special dates + countdown
- Bucket list

### Album
- Create/rename/favorite/delete albums
- Multi-import photo/video
- Search
- Timeline
- Favorites
- Album cover
- Caption/title/date/location editing
- Recently Deleted + restore/permanent delete

### Chat
- Text
- Photo/video
- Voice notes
- Reply
- Reaction
- Pin
- Edit
- Unsend
- Sticker panel
- Search
- Wallpapers
- Bubble effects

### Story
- Photo/video
- Caption
- Local audio/music metadata
- Viewer
- View count/list
- Highlights
- Archive
- 24h expiry

### Map
- Real current-device location
- Real current-device battery level
- Saved places
- Map styles
- No fake partner location

### Us
- Profile/banner/avatar
- Badge
- Avatar effects
- Highlights
- Statistics
- Life Hub
- Settings

### Settings
- Theme
- Chat wallpaper/effect
- Haptic
- Face ID/device lock
- Reduce Motion preference
- Local notifications/test
- Pairing-ready UI
- Backup JSON export

## Online sync

Two-iPhone realtime still requires a real backend.
The project already contains the CoupleBackend abstraction and a Supabase schema blueprint.
Do not claim partner location, partner battery, story views or realtime chat until a backend is configured.

## GitHub unsigned build

Push this tree to `main` preserving `.github/workflows/build-ios.yml`.
Then run GitHub Actions -> `Build KRYONIX Unsigned IPA`.
