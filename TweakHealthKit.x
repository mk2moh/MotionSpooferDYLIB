#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <HealthKit/HealthKit.h>
#import <math.h>
#import "TweakShared.h"

// HealthKit/Pedometer values are scaled at read time. Stored samples are not rewritten.
static HKQuantity *MSSpoofHealthQuantity(HKQuantity *quantity, HKQuantityType *type){
    if(!quantity || !type || !gEnabled) return quantity;
    NSString *identifier=type.identifier;
    HKUnit *unit=nil;
    double multiplier=1.0;
    if([identifier isEqualToString:HKQuantityTypeIdentifierStepCount]){
        if(!gExtraEnabled[E_STEPS]) return quantity;
        unit=[HKUnit countUnit]; multiplier=mSteps;
    } else if([identifier isEqualToString:HKQuantityTypeIdentifierDistanceWalkingRunning]){
        if(!gExtraEnabled[E_DISTANCE]) return quantity;
        unit=[HKUnit meterUnit]; multiplier=mDistance;
    } else {
        return quantity;
    }
    if(!isfinite(multiplier)) return quantity;
    double raw=[quantity doubleValueForUnit:unit];
    double scaled=raw*multiplier;
    if(!isfinite(raw) || !isfinite(scaled)) return quantity;
    return [HKQuantity quantityWithUnit:unit doubleValue:scaled];
}

%hook CMPedometerData
- (NSNumber *)numberOfSteps{ NSNumber *n=%orig; if(gEnabled && gExtraEnabled[E_STEPS] && n) return @((long long)llround(n.doubleValue*mSteps)); return n; }
- (NSNumber *)distance{ NSNumber *n=%orig; if(gEnabled && gExtraEnabled[E_DISTANCE] && n) return @(n.doubleValue*mDistance); return n; }
%end

%hook HKQuantitySample
- (HKQuantity *)quantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
%end

%hook HKStatistics
- (HKQuantity *)sumQuantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)sumQuantityForSource:(HKSource *)source{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)averageQuantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)averageQuantityForSource:(HKSource *)source{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)minimumQuantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)minimumQuantityForSource:(HKSource *)source{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)maximumQuantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)maximumQuantityForSource:(HKSource *)source{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)mostRecentQuantity{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
- (HKQuantity *)mostRecentQuantityForSource:(HKSource *)source{ HKQuantity *q=%orig; return MSSpoofHealthQuantity(q,self.quantityType); }
%end
