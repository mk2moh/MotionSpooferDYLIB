#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <objc/message.h>

#define MS_PREF_DOMAIN @"com.yourname.motionspoofer"
#define MS_PREF_CHANGED CFSTR("com.yourname.motionspoofer/prefsChanged")

@interface MSRootListController : PSListController
@end

static NSUserDefaults *MSPrefs(void) {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:MS_PREF_DOMAIN];
    return defaults ?: [NSUserDefaults standardUserDefaults];
}

static void MSPostPrefsChanged(void) {
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), MS_PREF_CHANGED, NULL, NULL, true);
}

static id MSCallObject0(id target, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (!target || ![target respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(target, selector);
}

static NSArray<NSDictionary *> *MSInstalledUserApps(void) {
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    id workspace = MSCallObject0(workspaceClass, @"defaultWorkspace");
    id result = MSCallObject0(workspace, @"allInstalledApplications");
    if (![result isKindOfClass:[NSArray class]]) result = MSCallObject0(workspace, @"installedApplications");
    if (![result isKindOfClass:[NSArray class]]) return @[];

    NSMutableArray *apps = [NSMutableArray array];
    for (id proxy in (NSArray *)result) {
        NSString *bundleID = MSCallObject0(proxy, @"bundleIdentifier");
        if (![bundleID isKindOfClass:[NSString class]] || bundleID.length == 0) continue;
        if ([bundleID isEqualToString:@"com.apple"] || [bundleID hasPrefix:@"com.apple."]) continue;

        NSString *name = MSCallObject0(proxy, @"localizedName");
        if (![name isKindOfClass:[NSString class]] || name.length == 0) name = bundleID;
        [apps addObject:@{@"name": name, @"bundleID": bundleID}];
    }
    [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    return apps;
}

@implementation MSRootListController

- (PSSpecifier *)specifierWithName:(NSString *)name cell:(PSCellType)cell key:(NSString *)key defaultValue:(id)defaultValue {
    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                                             target:self
                                                                set:@selector(setPreferenceValue:specifier:)
                                                                get:@selector(readPreferenceValue:)
                                                             detail:nil
                                                               cell:cell
                                                               edit:nil];
    if (key) [specifier setProperty:key forKey:@"key"];
    if (defaultValue) [specifier setProperty:defaultValue forKey:@"default"];
    [specifier setProperty:MS_PREF_DOMAIN forKey:@"defaults"];
    [specifier setProperty:@"com.yourname.motionspoofer/prefsChanged" forKey:@"PostNotification"];
    return specifier;
}

- (NSMutableArray *)specifiers {
    if (_specifiers) return _specifiers;

    NSMutableArray *specifiers = [NSMutableArray array];
    [specifiers addObject:[PSSpecifier groupSpecifierWithName:@"Global controls"]];

    [specifiers addObject:[self specifierWithName:@"Enabled" cell:PSSwitchCell key:@"enabled" defaultValue:@YES]];
    [specifiers addObject:[PSSpecifier groupSpecifierWithName:@"HealthKit (all hooked apps)"]];

    [specifiers addObject:[self specifierWithName:@"Scale step counts" cell:PSSwitchCell key:@"stepsEnabled" defaultValue:@YES]];
    PSSpecifier *stepsSlider = [self specifierWithName:@"Steps multiplier" cell:PSSliderCell key:@"steps" defaultValue:@1.0];
    [stepsSlider setProperty:@(-100.0) forKey:@"min"];
    [stepsSlider setProperty:@(100.0) forKey:@"max"];
    [stepsSlider setProperty:@YES forKey:@"showValue"];
    [specifiers addObject:stepsSlider];
    PSSpecifier *stepsExact = [self specifierWithName:@"Steps exact value (-1000 to 1000)" cell:PSEditTextCell key:@"steps" defaultValue:@1.0];
    [stepsExact setProperty:@YES forKey:@"numericText"];
    [stepsExact setProperty:@YES forKey:@"isDecimalPad"];
    [stepsExact setProperty:@YES forKey:@"noAutoCorrect"];
    [stepsExact setProperty:@"Multiplier" forKey:@"placeholder"];
    [specifiers addObject:stepsExact];

    [specifiers addObject:[self specifierWithName:@"Scale walking/running distance" cell:PSSwitchCell key:@"distanceEnabled" defaultValue:@YES]];
    PSSpecifier *distanceSlider = [self specifierWithName:@"Distance multiplier" cell:PSSliderCell key:@"distance" defaultValue:@1.0];
    [distanceSlider setProperty:@(-100.0) forKey:@"min"];
    [distanceSlider setProperty:@(100.0) forKey:@"max"];
    [distanceSlider setProperty:@YES forKey:@"showValue"];
    [specifiers addObject:distanceSlider];
    PSSpecifier *distanceExact = [self specifierWithName:@"Distance exact value (-1000 to 1000)" cell:PSEditTextCell key:@"distance" defaultValue:@1.0];
    [distanceExact setProperty:@YES forKey:@"numericText"];
    [distanceExact setProperty:@YES forKey:@"isDecimalPad"];
    [distanceExact setProperty:@YES forKey:@"noAutoCorrect"];
    [distanceExact setProperty:@"Multiplier" forKey:@"placeholder"];
    [specifiers addObject:distanceExact];

    PSSpecifier *appsGroup = [PSSpecifier groupSpecifierWithName:@"Apps that show the floating overlay"];
    [appsGroup setProperty:@"Choose installed third-party apps. CoreMotion settings are saved separately for each app." forKey:@"footerText"];
    [specifiers addObject:appsGroup];

    NSArray<NSDictionary *> *apps = MSInstalledUserApps();
    if (apps.count == 0) {
        PSSpecifier *empty = [PSSpecifier preferenceSpecifierNamed:@"No third-party apps found"
                                                             target:self set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil];
        [specifiers addObject:empty];
    } else {
        for (NSDictionary *app in apps) {
            NSString *bundleID = app[@"bundleID"];
            PSSpecifier *specifier = [self specifierWithName:app[@"name"] cell:PSSwitchCell key:nil defaultValue:@NO];
            [specifier setProperty:bundleID forKey:@"overlayBundleID"];
            specifier.identifier = bundleID;
            [specifiers addObject:specifier];
        }
    }

    _specifiers = specifiers;
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = MSPrefs();
    NSString *bundleID = [specifier propertyForKey:@"overlayBundleID"];
    if (bundleID) {
        NSArray *allowed = [defaults arrayForKey:@"overlayBundleIDs"] ?: @[];
        return @([allowed containsObject:bundleID]);
    }

    NSString *key = [specifier propertyForKey:@"key"];
    id value = key ? [defaults objectForKey:key] : nil;
    if (!value) value = [specifier propertyForKey:@"default"];
    if ([[specifier propertyForKey:@"numericText"] boolValue]) {
        return [NSString stringWithFormat:@"%.6g", [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 1.0];
    }
    return value ?: @NO;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSUserDefaults *defaults = MSPrefs();
    NSString *bundleID = [specifier propertyForKey:@"overlayBundleID"];
    if (bundleID) {
        NSMutableSet *allowed = [NSMutableSet setWithArray:[defaults arrayForKey:@"overlayBundleIDs"] ?: @[]];
        if ([value boolValue]) [allowed addObject:bundleID];
        else [allowed removeObject:bundleID];
        [defaults setObject:[[allowed allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] forKey:@"overlayBundleIDs"];
    } else {
        NSString *key = [specifier propertyForKey:@"key"];
        if (!key) return;
        if ([[specifier propertyForKey:@"numericText"] boolValue]) {
            double number = [value doubleValue];
            if (number < -1000) number = -1000;
            if (number > 1000) number = 1000;
            [defaults setDouble:number forKey:key];
        } else if ([key isEqualToString:@"steps"] || [key isEqualToString:@"distance"]) {
            double number = [value doubleValue];
            if (number < -100) number = -100;
            if (number > 100) number = 100;
            [defaults setDouble:number forKey:key];
        } else {
            [defaults setObject:value forKey:key];
        }
    }
    [defaults synchronize];
    MSPostPrefsChanged();
}

@end
