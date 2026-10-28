# MotionSpoofer Full - Packed with features

Draggable **in-app** overlay, no Settings app needed. Works on Dopamine roothide 3.0 (iOS 16.6.1, iPhone 11 Pro Max) **and** via TrollFools dylib injection.

## ✅ Packed features
- **Enabled** toggle
- **12 main sliders** (1.0 = real, 0 = frozen, 5 = 5×):
  - Raw: Accelerometer / Gyroscope / Magnetometer
  - DeviceMotion: UserAccel / Gravity / RotationRate / Calibrated Mag / Attitude
  - Activity: Steps / Distance
  - Barometer: Pressure / Relative Altitude
- **Advanced per-axis mode** (switch): when ON, 24 extra X/Y/Z sliders OVERRIDE the main ones:
  - Each sensor has X=red, Y=green, Z=blue
  - e.g. `accelX`, `accelY`, `accelZ` etc. Attitude shows Roll/Pitch/Yaw
- **Persistent** between kills/reboots: saves to `NSUserDefaults` suite `com.yourname.motionspoofer` + `Documents/MotionSpoofer.json` backup
- **Floating MS button**: drag anywhere, snap to edge, tap to open panel

## 🚀 Build via GitHub Actions (no computer tools needed)
1. Create **new empty** repo on GitHub
2. Upload **all files from this folder** (`Add file > Upload files`) - must include hidden `.github` folder. If browser skips it, create file `.github/workflows/build.yml` manually and paste contents.
3. Go to `Actions` tab - workflow `Build deb` auto-runs (or hit `Run workflow`)
4. Wait 3-5 min > open run > download artifact `MotionSpoofer-deb` > unzip to get `.deb`
5. Install `.deb` with Sileo/Filza/TrollStore > Respring

## 📲 Use

**Jailbreak (Dopamine roothide 3.0):**
- Install deb, respring, open your motion test app - MS button appears

**TrollFools:**
1. Decrypt target app first (TrollDecrypt)
2. Extract dylib from deb: `var/jb/usr/lib/tweaks/MotionSpoofer.dylib` (open deb with Filza or `dpkg-deb -x`)
3. TrollFools > select target app > Inject > pick that dylib > launch app

Configure: drag MS > set values > **Save & Apply** > instantly scales `CMAccelerometerData`, `CMDeviceMotion`, `CMPedometerData` etc. Kill & reopen app to verify persistence.

## ⚙️ Customize
- To limit to one app, edit `MotionSpoofer.plist`: `Filter = { Bundles = ("com.example.app") }`
- To increase max from 5× to 10×, edit `Tweak.x` slider max values
