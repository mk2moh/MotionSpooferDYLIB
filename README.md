# MotionSpoofer v1.5.1

The GitHub Actions workflow builds two separate outputs and packages both in `MotionSpoofer-v<version>.zip`. After pushing the source, download the versioned artifact from the **Build MotionSpoofer artifacts** workflow. Version 1.5.1 also fixes the standalone dependency audit: it ignores the dylib's own Theos install ID and checks only actual linked libraries.

- **Jailbreak `.deb`:** the normal tweak build, including the Settings pane, installed-app overlay selection, global HealthKit Steps/Distance multipliers, and global CoreMotion multipliers.
- **TrollFools `.dylib`:** a standalone build using Logos' internal Objective-C runtime generator. It does not link MobileSubstrate and omits the HealthKit/Pedometer hooks. Inject it into the app you want to test; its control panel opens when that app launches.

## Settings and modifier scope

Open **Settings → MotionSpoofer** to set the global master, HealthKit multipliers, global motion multipliers, and choose which installed third-party apps show the overlay in the `.deb` build. Turn on the target app in that list or the overlay stays hidden; selected apps open the overlay on launch. The app list is retained; the standalone TrollFools build instead shows the overlay in the app into which it was injected.

When **Override all per-app modifiers** is enabled, global scalar values replace each app's saved sensor multipliers. Each app can opt out with **Use Global Modifiers for This App** in its overlay. Per-sensor enable switches and per-app button styling remain app-specific.

CoreMotion controls include accelerometer, gyroscope, magnetometer/compass, user acceleration, gravity, rotation rate, calibrated magnetometer, attitude, pressure, and relative altitude. Per-app values are stored by bundle ID and persist across app restarts. HealthKit Steps/Distance and CMPedometer scaling are only in the `.deb`; values are scaled at read time and stored HealthKit samples are not rewritten.

Main sliders cover -100 to 100, per-axis sliders -5 to 5, and typed values -1000 to 1000. The popup auto-opens on app launch; close it to use the app and tap the floating MS button to reopen it.
