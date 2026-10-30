# E-Cycle LK

An iOS app that helps people in Sri Lanka dispose of electronic waste responsibly. A person records an item, learns how to dispose of it safely, finds a suitable recycling centre, plans the drop-off, gets reminded, and keeps a record of what was recycled.

Coursework project for the **IOS** module, BSc (Hons) in Computing, Coventry University, delivered at NIBM.

| | |
|---|---|
| Student | W K A G Premachandra (NIBM COBSCOMP251P-019, Coventry ID 16602809) |
| Module lecturer | Mr. Fuzail |
| Platform | iPhone and iPad, iOS 26.2 |
| Tools | Xcode 26, Swift, SwiftUI |


## Features

| Feature | What the user can do | Key technology |
|---|---|---|
| Sign-in and onboarding | See a short introduction, create an account, sign in and out | Firebase Authentication |
| App lock | Lock the app with Face ID or the device passcode when it goes to the background | LocalAuthentication |
| My items | Add, edit, save and delete electronic items | Core Data |
| Smart scan | Take or choose a photo and get a suggested item category, which fills the form | Create ML, Vision, Core ML (on device) |
| Recycling plans | Plan a drop-off for an item and set a reminder | Core Data, UserNotifications |
| Home and history | See recycling impact and a history of recycled items | SwiftUI |
| Centres | Search and filter 30 recycling centres, view a list or a map, see details, call, get directions | MapKit, Core Location, bundled CSV |
| Centre alerts (geofencing) | Get a notification when near a centre that accepts your saved or planned items | Core Location region monitoring, local notifications |
| Community | Share and browse items posted by other users | Firestore |
| Accessibility | Dynamic Type, VoiceOver labels, a list alternative to the map, large touch targets | SwiftUI accessibility |

### Centre alerts in brief

The app monitors up to 20 centres (the iOS limit) that accept at least one item the user still has saved or planned, nearest first. Each centre has a 500 m circular region. Entering it sends a local notification. A centre can alert once every 12 hours. This needs "Always" location permission so alerts work when the app is closed. Location data stays on the device.

## Architecture

- **SwiftUI** with **MVVM**. View models are `@MainActor @Observable`.
- **Protocols and dependency injection**. Services (items, plans, centres, classifier, geofencing, notifications, authentication) sit behind protocols, so tests use fakes instead of real hardware or network.
- **Data**: Core Data for personal data on the device, Firestore for Community, and a bundled `centres.csv` for centre data.
- **Machine learning**: a Create ML image classifier (7 classes) runs on the device through Vision.

## Requirements

- macOS with **Xcode 26**
- **iOS 26.2** simulator (tested on iPhone 17 Pro) or an iOS device
- Internet access for the first Swift package download and for Firebase (sign-in and Community)

## Run the app

1. Clone the repository:
   ```
   git clone https://github.com/AnjanaSWdev/IOS_CW-E-Cycle-LK-.git
   ```
2. Open `ecyclelk/ecyclelk.xcodeproj` in Xcode.
3. Wait for Swift packages (Firebase) to finish resolving.
4. Choose the **iPhone 17 Pro** simulator and press **Run** (Cmd+R).
5. Create an account on the sign-in screen, or use the test account given in the submitted report.

`GoogleService-Info.plist` (Firebase configuration) is included in the project.

### Run on a physical device

Select your own team in **Signing & Capabilities** and use a unique bundle identifier. A free Apple ID limits how many devices you can register.

### Smart scan in the simulator

The simulator has no camera, so use **Choose photo**. Core ML runs on the CPU in the simulator, and the real device uses the normal compute units.

## Run the tests

Press **Cmd+U** in Xcode (Product → Test). There are 113 unit tests in 9 suites using Swift Testing:

| Suite | Tests |
|---|---|
| AppLock | 7 |
| Auth | 7 |
| Items | 7 |
| Plans | 10 |
| RecyclingStats | 5 |
| Centre | 19 |
| Scan | 15 |
| Geofence | 14 |
| Community | 29 |

## Try the centre alerts in the simulator

1. Save an item or add a plan (for example a mobile phone).
2. Pick a centre that accepts it in `centres.csv` and note its latitude and longitude.
3. In the simulator choose **Features → Location → Custom Location…** and set a point far from the centre.
4. Open the **Centres** tab, switch on **Alert me near centres**, and allow notifications and location (While Using, then Always).
5. Press Home, then set the custom location to the centre's coordinates.
6. The notification appears within a few seconds.

To repeat the demo at the same centre, reinstall the app or wait out the 12-hour cooldown.

## Firebase

- Authentication and Firestore are used for accounts and Community.
- Security rules are in `firebase/firestore.rules`. Publish them in the Firebase console if you use your own Firebase project.

## Project layout

```
ecyclelk/
  ecyclelk.xcodeproj
  ecyclelk/            App source (views, view models, services, models)
  ecyclelkTests/       Unit tests
firebase/
  firestore.rules      Firestore security rules
docs/                  Supporting evidence (see below)
```

## Data and model sources

- **Centres**: 30 recycling points (public eKunu drop-off points and licensed collectors approved by the Central Environmental Authority) in `centres.csv`.
- **Classifier**: Create ML model trained on an image dataset. 


## Known limitations

- Apple Maps directions are not available in the simulator. They work on a device.
- Region monitoring is most reliable on a physical device with "Always" location permission.
- Wi-Fi-only iPads have no GPS, so distances can be missing. The centre list still works.
- The app is locked to the Light appearance.

## Licence and credits

Coursework submission. Centre information comes from public sources listed above. Third-party libraries (Firebase) keep their own licences.
