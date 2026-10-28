# MotionSpoofer V3

- Tap a sensor title to switch between all-axis and per-axis controls.
- Per-sensor ON/OFF switches and a master Enabled switch.
- Live sensor readouts and editable multiplier values.
- Slider values cover -100 to 100; typed multipliers can be set from -1000 to 1000.
- Button opacity and size settings persist.
- Two-window overlay keeps app touch input passing through when the panel is closed.
- HealthKit read-side scaling for step counts and walking/running distance. The Steps/Distance multipliers affect `HKQuantitySample` and `HKStatistics` values returned to hooked apps; HealthKit records are not rewritten.
- Magnetometer support includes `CMMagnetometerData`, calibrated `CMDeviceMotion` fields, and Core Location `CLHeading` fields/headings.

The HealthKit behavior is applied in processes where the tweak is injected and that have HealthKit read access.
