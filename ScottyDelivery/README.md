# ScottyDelivery — iOS Application

> A Carnegie Mellon campus delivery companion for orders placed separately through Grubhub.
> ScottyDelivery does not place or modify meal orders.

---

## 🌟 Key Features

### Delivery flow
- Enter the 3-digit order number supplied by Grubhub.
- Select the campus restaurant/pickup location and a delivery destination.
- Review the request and its **$1.00 delivery fee**, then confirm.
- Track the request, confirm arrival, and view a delivery receipt in history.
- Manage delivery preferences, locations, and support information in Settings.

### Backend status
- Delivery submission, robot assignment, live tracking, payments, and push notifications are not yet connected to a server.
- Delivery history is held in memory and resets when the app is relaunched.
- A delivery API contract is needed before server integration can be implemented.

---

## 📱 Running & Testing on Physical iPhone 17

### Prerequisites
- A Mac with **Xcode 15+** installed.
- An **Apple Developer Account** (Free or Paid).
- An **iPhone 17** (or any device running iOS 17.0+).

### Step-by-Step Installation

1. **Open the Project in Xcode**:
   Double-click `ScottyDelivery.xcodeproj` to launch Xcode.
   ```bash
   open ScottyDelivery/ScottyDelivery.xcodeproj
   ```

2. **Select your Apple Developer Account**:
   - In Xcode's Project Navigator (left sidebar), click the top-level **ScottyDelivery** project icon.
   - Select the **ScottyDelivery** target under `Targets`.
   - Go to the **Signing & Capabilities** tab.
   - Check **Automatically manage signing**.
   - Under **Team**, select your Personal Team or Apple Developer Team from the dropdown.
   - If needed, adjust the **Bundle Identifier** (default is `org.scottylabs.ScottyDelivery`, e.g., append your name: `org.scottylabs.ScottyDelivery.yourname`).

3. **Connect Your Physical iPhone 17**:
   - Connect your iPhone 17 to your Mac via USB-C cable (or ensure wireless debugging is enabled).
   - Unlock your iPhone and tap **Trust This Computer** if prompted.
   - In Xcode's top destination toolbar, click the device selector and choose your connected **iPhone 17**.

4. **Enable Developer Mode on iPhone (iOS 16+)**:
   - On your iPhone, open **Settings > Privacy & Security**.
   - Scroll down to **Developer Mode** and toggle it **On**.
   - Follow the prompt to restart your iPhone and confirm enabling Developer Mode.

5. **Build and Run**:
   - Press `Cmd + R` (or click the **Play** button in Xcode).
   - Xcode will compile the SwiftUI views, sign the bundle, and install the app on your iPhone 17.
   - *First-time run note*: If iOS shows an "Untrusted Developer" alert, go to **Settings > General > VPN & Device Management** on your iPhone, select your Apple Developer certificate, and tap **Trust**.

---

## 🛠️ Project Structure

```
ScottyDelivery/
├── ScottyDelivery.xcodeproj/
│   └── project.pbxproj         # Xcode Project Configuration
├── Package.swift               # Swift Package Manager manifest
├── README.md                   # Documentation & Setup Guide
└── ScottyDelivery/
    ├── ScottyDeliveryApp.swift # App Entry Point
    ├── Info.plist              # Permissions, Bundle Config & Launch Screen
    ├── Assets.xcassets/        # Figma artwork, campus illustrations, and app assets
    ├── Models/
    │   └── Models.swift        # Shared and legacy ordering models
    ├── Services/
    │   └── APIClient.swift     # Existing meal-order API (not used by delivery requests)
    └── Views/
        ├── MainTabView.swift   # Root navigation wrapper
        ├── DeliveryFlowView.swift # Grubhub delivery request, tracking, history, receipt, settings
        └── Legacy ordering views          # Retained in project, not used by the app entry point
```
