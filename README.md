# MotionSpoofer V3

Open **Settings → MotionSpoofer** to set global options and choose which installed apps show the floating overlay. In each enabled app, the overlay stores its sensor settings independently.

- The iOS Settings pane provides the global master switch, HealthKit step/distance multipliers, and a list of installed third-party apps where the floating overlay should appear.
- The overlay is hidden from Home Screen, Spotlight, Settings, and other Apple system apps. Sensor settings are stored separately for each app.
- Per-app CoreMotion controls cover accelerometer, gyroscope, magnetometer, device motion, attitude, pressure, and relative altitude.
- HealthKit step and walking/running-distance multipliers are global and configured only in Settings. They scale values returned to hooked apps; stored HealthKit samples are not rewritten.
- Core Location compass fields/headings are hooked alongside CoreMotion magnetometer fields.
- Main sensor sliders cover -100 to 100 (per-axis sliders cover -5 to 5); typed values can be set from -1000 to 1000.
- Button opacity/size persist per app. The two-window overlay passes app touches through while its panel is closed.

The tweak remains injected into UIKit apps so the global HealthKit read hooks can work in each client process. The overlay itself is shown only for apps enabled in Settings.
