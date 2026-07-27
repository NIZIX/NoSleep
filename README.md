# NoSleep

A native macOS menu bar app that keeps the display on and prevents the Mac from going to sleep because of inactivity.

## Usage

### Install from a release

1. Download `NoSleep-1.0.0.dmg` from GitHub Releases.
2. Open the disk image.
3. Drag `NoSleep.app` onto the `Applications` shortcut.
4. Launch NoSleep from Applications.
5. Click the moon icon in the menu bar.
6. Enable **“Keep Display Awake”**.

The icon changes to a sun and the menu confirms that display and idle sleep are blocked. The selected state persists between launches.

### Build from source

Create the universal app and DMG:

```bash
./Scripts/build-dmg.sh
```

The build produces `dist/NoSleep.app` and the release artifact
`dist/NoSleep-1.0.0.dmg`. Set `NOSLEEP_SKIP_APP_BUILD=1` when running
`build-dmg.sh` if `NoSleep.app` has already been built.

## Localization

NoSleep automatically follows the preferred language configured in macOS. The app currently includes:

- English
- Russian
- German
- French
- Spanish
- Simplified Chinese

## How it works

The app creates two standard IOKit power assertions:

- `PreventUserIdleDisplaySleep` prevents macOS from automatically turning off the display.
- `PreventUserIdleSystemSleep` prevents the Mac from automatically sleeping because of inactivity.

Both assertions are released immediately when the toggle is disabled or the app exits. They do not override sleep initiated by the user, closing a MacBook lid, or protective shutdown caused by critical power or thermal conditions.

NoSleep requires no administrator privileges, does not appear in the Dock, supports both Apple Silicon and Intel Macs, and requires macOS 13 or later.

## Development

Run the verification utility and create a release build:

```bash
swift run NoSleepVerifier
swift build -c release
```

Run `swift run NoSleepVerifier --hold` to keep the test assertions active for 10 seconds so they can be inspected with `pmset -g assertions`.

The project can also be opened in Xcode through `Package.swift`.
