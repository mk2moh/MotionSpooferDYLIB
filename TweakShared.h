#import <Foundation/Foundation.h>

enum { E_STEPS, E_DISTANCE, E_PRESSURE, E_RELALT, E_COUNT };

// Shared with TweakHealthKit.x in the package build. The TrollFools target does
// not compile TweakHealthKit.x, so these values are unused in that dylib.
extern BOOL gEnabled;
extern BOOL gExtraEnabled[E_COUNT];
extern double mSteps;
extern double mDistance;
