# DreamLoop Home Widget Setup (iOS)

This repo now contains the Flutter bridge and a WidgetKit scaffold at `ios/DreamLoopWidget/`.

## 1. Add Widget Extension Target in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File -> New -> Target -> Widget Extension.
3. Name it `DreamLoopWidget`.
4. Replace generated widget files with the files from `ios/DreamLoopWidget/`:
   - `DreamLoopWidget.swift`
   - `Info.plist`
   - `DreamLoopWidget.entitlements`

## 2. Configure App Group

Use the same App Group on both Runner and DreamLoopWidget targets:
- `group.com.dreamloop.shared`

In Xcode:
1. Select `Runner` target -> Signing & Capabilities -> add `App Groups`.
2. Select `DreamLoopWidget` target -> Signing & Capabilities -> add `App Groups`.
3. Enable `group.com.dreamloop.shared` for both.
4. Set `Runner` target Build Settings -> Code Signing Entitlements to:
   - `Runner/Runner.entitlements`

## 3. URL Scheme for Tap-to-Open

Runner `Info.plist` already includes:
- URL scheme: `dreamloop`

Widget uses links like:
- `dreamloop://story`

Tapping widget opens the app and routes to story/history via Flutter `WidgetSyncService`.

## 4. Build and Test

1. `flutter pub get`
2. Run app on iPhone simulator/device.
3. Start story flow to generate an event.
4. Add DreamLoop widget from home screen.
5. Verify widget shows event text and tapping it opens app to story.

## 5. Android (later)

Flutter bridge is already prepared (`home_widget`), but Android provider UI is not yet added in this phase.
