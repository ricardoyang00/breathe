<div align="center">
    <img src="assets/images/banner.svg" width=100%>
    </br></br>


  <a href="#installation"><img src="https://img.shields.io/badge/Download-Now-4b3baf" alt="Download"></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000000" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/License-MIT-28a745" alt="License MIT">
  <img src="https://img.shields.io/badge/SwiftUI-FA7343" alt="SwiftUI">
</div>

<br/>

Managing pollen and dust allergies requires constant awareness of outdoor air quality to prevent severe symptoms. **Breathe** provides a quick, glanceable way to check current environmental risk levels directly from the macOS menu bar, helping users make informed decisions before stepping outside or opening windows. 

## Features

- 🌿 **Menu Bar Integration:** Instantly view current air quality and pollen levels.
- 📊 **Split Metrics:** Separate risk evaluations for **Pollen** (Grass/Birch) and **Dust** (AQI/PM10/PM2.5).
- 💡 **Tips:** Contextual advice based on current conditions.
- 🔒 **Privacy:** No GPS tracking. You manually search and set your city.
- 🚀 **Autostart:** Easily toggle the app to launch automatically at login.

## Installation

### Option 1: Homebrew (Recommended)

You can quickly install Breathe using Homebrew:

```bash
brew install --cask ricardoyang00/tap/breathe
```

### Option 2: Direct Download

1. Go to the [Releases](https://github.com/ricardoyang00/breathe/releases) page.
2. Download the latest `Breathe.dmg`.
3. Drag the `Breathe.app` into your `Applications` folder.

> [!TIP]
> **Gatekeeper:**
> Because Breathe is an indie open-source app, macOS might show an *"App is damaged and can't be opened"* error. To fix this, open your Terminal and run the following command to remove the quarantine flag:
> ```bash
> xattr -cr /Applications/Breathe.app
> ```

## Usage

1. Open **Breathe** from your Applications folder, or from the Launchpad. You will see a new icon appear in your Mac's menu bar at the top of your screen.
2. Click the menu bar icon and select **Settings**.
3. Under the **Location** section, type your city name into the search box and select the correct location from the dropdown list.
4. Under the **Preferences** section, toggle which metrics you want to track (Pollen, Dust, or both).
5. The menu bar icon will now automatically update to reflect the overall risk level for your selected location!

## License

MIT License - see LICENSE file for details
