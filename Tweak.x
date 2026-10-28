#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

#define PREF_DOMAIN @"com.yourname.motionspoofer"
#define PREF_CHANGED "com.yourname.motionspoofer/prefsChanged"

enum { S_ACCEL, S_GYRO, S_MAG, S_USERACCEL, S_GRAVITY, S_ROTRATE, S_MAGCAL, S_ATT, S_COUNT };

static BOOL   gEnabled = YES, gAdv = NO;
static double gBase[S_COUNT];
static double gAxis[S_COUNT][3];
static double mSteps = 1, mDistance = 1, mPressure = 1, mRelAlt = 1;
static inline double M(int s, int a) { return gAdv ? gAxis[s][a] : gBase[s]; }

static NSArray *sensorKeys(){ return @[@"accel",@"gyro",@"mag",@"userAccel",@"gravity",@"rotRate",@"magCal",@"attitude"]; }
static NSArray *sensorLabels(){ return @[@"Accelerometer",@"Gyroscope",@"Magnetometer",@"User Acceleration",@"Gravity",@"Rotation Rate",@"Calibrated Mag",@"Attitude (roll/pitch/yaw)"]; }
static NSArray *axisLetters(){ return @[@"X",@"Y",@"Z"]; }
static NSArray *attitudeLetters(){ return @[@"Roll",@"Pitch",@"Yaw"]; }

static NSUserDefaults *prefsDB(){
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:PREF_DOMAIN];
    return d ?: [NSUserDefaults standardUserDefaults];
}
static double readD(NSUserDefaults *d, NSString *k, double def){ id v=[d objectForKey:k]; return v?[v doubleValue]:def; }
static void loadPrefs(void){
    NSUserDefaults *d=prefsDB(); NSArray *keys=sensorKeys(); NSArray *ax=axisLetters();
    gEnabled=[d objectForKey:@"enabled"]?[d boolForKey:@"enabled"]:YES;
    gAdv=[d boolForKey:@"advanced"];
    for(int s=0;s<S_COUNT;s++){ gBase[s]=readD(d,keys[s],1); for(int a=0;a<3;a++) gAxis[s][a]=readD(d,[keys[s] stringByAppendingString:ax[a]],1); }
    mSteps=readD(d,@"steps",1); mDistance=readD(d,@"distance",1); mPressure=readD(d,@"pressure",1); mRelAlt=readD(d,@"relAlt",1);
}
static void savePrefs(void){
    NSUserDefaults *d=prefsDB(); NSArray *keys=sensorKeys(); NSArray *ax=axisLetters();
    [d setBool:gEnabled forKey:@"enabled"]; [d setBool:gAdv forKey:@"advanced"];
    for(int s=0;s<S_COUNT;s++){ [d setDouble:gBase[s] forKey:keys[s]]; for(int a=0;a<3;a++) [d setDouble:gAxis[s][a] forKey:[keys[s] stringByAppendingString:ax[a]]]; }
    [d setDouble:mSteps forKey:@"steps"]; [d setDouble:mDistance forKey:@"distance"]; [d setDouble:mPressure forKey:@"pressure"]; [d setDouble:mRelAlt forKey:@"relAlt"];
    [d synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(PREF_CHANGED), NULL, NULL, true);
    NSString *doc=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if(doc){
        NSMutableDictionary *dict=[NSMutableDictionary dictionary]; NSArray *keys2=sensorKeys(); NSArray *ax2=axisLetters();
        dict[@"enabled"]=@(gEnabled); dict[@"advanced"]=@(gAdv);
        for(int s=0;s<S_COUNT;s++){ dict[keys2[s]]=@(gBase[s]); for(int a=0;a<3;a++) dict[[keys2[s] stringByAppendingString:ax2[a]]]=@(gAxis[s][a]); }
        dict[@"steps"]=@(mSteps); dict[@"distance"]=@(mDistance); dict[@"pressure"]=@(mPressure); dict[@"relAlt"]=@(mRelAlt);
        NSString *p=[doc stringByAppendingPathComponent:@"MotionSpoofer.json"];
        NSData *j=[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
        [j writeToFile:p atomically:YES];
    }
}
static void prefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u){ loadPrefs(); }

// ---- hooks ----
%hook CMAccelerometerData
- (CMAcceleration)acceleration{ CMAcceleration a=%orig; if(gEnabled){a.x*=M(S_ACCEL,0); a.y*=M(S_ACCEL,1); a.z*=M(S_ACCEL,2);} return a; }
%end
%hook CMGyroData
- (CMRotationRate)rotationRate{ CMRotationRate r=%orig; if(gEnabled){r.x*=M(S_GYRO,0); r.y*=M(S_GYRO,1); r.z*=M(S_GYRO,2);} return r; }
%end
%hook CMMagnetometerData
- (CMMagneticField)magneticField{ CMMagneticField m=%orig; if(gEnabled){m.x*=M(S_MAG,0); m.y*=M(S_MAG,1); m.z*=M(S_MAG,2);} return m; }
%end
%hook CMDeviceMotion
- (CMAcceleration)userAcceleration{ CMAcceleration a=%orig; if(gEnabled){a.x*=M(S_USERACCEL,0); a.y*=M(S_USERACCEL,1); a.z*=M(S_USERACCEL,2);} return a; }
- (CMAcceleration)gravity{ CMAcceleration a=%orig; if(gEnabled){a.x*=M(S_GRAVITY,0); a.y*=M(S_GRAVITY,1); a.z*=M(S_GRAVITY,2);} return a; }
- (CMRotationRate)rotationRate{ CMRotationRate r=%orig; if(gEnabled){r.x*=M(S_ROTRATE,0); r.y*=M(S_ROTRATE,1); r.z*=M(S_ROTRATE,2);} return r; }
- (CMCalibratedMagneticField)magneticField{ CMCalibratedMagneticField f=%orig; if(gEnabled){f.field.x*=M(S_MAGCAL,0); f.field.y*=M(S_MAGCAL,1); f.field.z*=M(S_MAGCAL,2);} return f; }
%end
%hook CMAttitude
- (double)roll{ double v=%orig; return gEnabled? v*M(S_ATT,0):v; }
- (double)pitch{ double v=%orig; return gEnabled? v*M(S_ATT,1):v; }
- (double)yaw{ double v=%orig; return gEnabled? v*M(S_ATT,2):v; }
%end
%hook CMPedometerData
- (NSNumber *)numberOfSteps{ NSNumber *n=%orig; return (gEnabled&&n)?@((long long)llround(n.doubleValue*mSteps)):n; }
- (NSNumber *)distance{ NSNumber *n=%orig; return (gEnabled&&n)?@(n.doubleValue*mDistance):n; }
%end
%hook CMAltitudeData
- (NSNumber *)relativeAltitude{ NSNumber *n=%orig; return (gEnabled&&n)?@(n.doubleValue*mRelAlt):n; }
- (NSNumber *)pressure{ NSNumber *n=%orig; return (gEnabled&&n)?@(n.doubleValue*mPressure):n; }
%end

// ---- overlay ----
@interface MSMotionOverlay : NSObject
+ (instancetype)shared; - (void)installIfNeeded; - (void)togglePanel;
@end

@implementation MSMotionOverlay {
    UIWindow *_overlayWindow; UIButton *_floatBtn; UIView *_panelBG; UIView *_card;
    UIScrollView *_scroll; UIStackView *_stack;
    NSMutableDictionary *_sliders; NSMutableDictionary *_valueLabels;
    UISwitch *_enabledSwitch; UISwitch *_advSwitch;
    UIView *_advContainer; // holds per-axis rows
    CGPoint _panStart;
}
+ (instancetype)shared{ static MSMotionOverlay *s; static dispatch_once_t t; dispatch_once(&t,^{s=[MSMotionOverlay new];}); return s; }
- (void)installIfNeeded{ if(_overlayWindow) return; dispatch_async(dispatch_get_main_queue(),^{ [self createWindow]; }); }
- (UIWindow*)findWindowScene{
    for(UIScene *sec in [UIApplication sharedApplication].connectedScenes){
        if([sec isKindOfClass:[UIWindowScene class]]){
            UIWindowScene *ws=(UIWindowScene*)sec;
            UIWindow *key=nil; for(UIWindow *w in ws.windows) if(w.isKeyWindow){key=w;break;}
            if(!key && ws.windows.count) key=ws.windows.firstObject;
            if(key) return [[UIWindow alloc] initWithWindowScene:ws];
        }
    }
    UIWindow *w=nil;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    w=[UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
    if(w) return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}
- (void)createWindow{
    _overlayWindow=[self findWindowScene];
    _overlayWindow.windowLevel=UIWindowLevelAlert+1000;
    _overlayWindow.backgroundColor=[UIColor clearColor];
    _overlayWindow.hidden=NO;
    UIViewController *vc=[UIViewController new]; vc.view.backgroundColor=[UIColor clearColor];
    _overlayWindow.rootViewController=vc; [_overlayWindow makeKeyAndVisible];

    _floatBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    _floatBtn.frame=CGRectMake(20,90,54,54); _floatBtn.layer.cornerRadius=27;
    _floatBtn.backgroundColor=[UIColor colorWithRed:0.12 green:0.65 blue:0.95 alpha:0.93];
    _floatBtn.layer.shadowColor=[UIColor blackColor].CGColor; _floatBtn.layer.shadowOpacity=0.3; _floatBtn.layer.shadowRadius=6; _floatBtn.layer.shadowOffset=CGSizeMake(0,3);
    [_floatBtn setTitle:@"MS" forState:UIControlStateNormal]; _floatBtn.titleLabel.font=[UIFont boldSystemFontOfSize:16];
    [_floatBtn addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_floatBtn addGestureRecognizer:pan];
    [vc.view addSubview:_floatBtn];

    _panelBG=[[UIView alloc] initWithFrame:vc.view.bounds];
    _panelBG.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _panelBG.backgroundColor=[UIColor colorWithWhite:0 alpha:0.48]; _panelBG.hidden=YES;
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePanel)];
    [_panelBG addGestureRecognizer:tap];
    [vc.view addSubview:_panelBG];

    _card=[[UIView alloc] init]; _card.backgroundColor=[UIColor systemBackgroundColor]; _card.layer.cornerRadius=18; _card.layer.masksToBounds=YES; _card.translatesAutoresizingMaskIntoConstraints=NO;
    [_panelBG addSubview:_card];
    [NSLayoutConstraint activateConstraints:@[
        [_card.centerXAnchor constraintEqualToAnchor:_panelBG.centerXAnchor],
        [_card.centerYAnchor constraintEqualToAnchor:_panelBG.centerYAnchor],
        [_card.widthAnchor constraintEqualToAnchor:_panelBG.widthAnchor multiplier:0.93],
        [_card.heightAnchor constraintEqualToAnchor:_panelBG.heightAnchor multiplier:0.86]
    ]];

    _scroll=[[UIScrollView alloc] init]; _scroll.translatesAutoresizingMaskIntoConstraints=NO; _scroll.showsVerticalScrollIndicator=YES; _scroll.alwaysBounceVertical=YES;
    [_card addSubview:_scroll];
    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:_card.topAnchor constant:14],
        [_scroll.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
        [_scroll.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-14],
        [_scroll.bottomAnchor constraintEqualToAnchor:_card.bottomAnchor constant:-14]
    ]];
    _stack=[[UIStackView alloc] init]; _stack.axis=UILayoutConstraintAxisVertical; _stack.spacing=10; _stack.translatesAutoresizingMaskIntoConstraints=NO;
    [_scroll addSubview:_stack];
    [NSLayoutConstraint activateConstraints:@[
        [_stack.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor],
        [_stack.leadingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.leadingAnchor],
        [_stack.trailingAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.trailingAnchor],
        [_stack.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor],
        [_stack.widthAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.widthAnchor]
    ]];
    _sliders=[NSMutableDictionary dictionary]; _valueLabels=[NSMutableDictionary dictionary];
    [self buildCardContent];
}
- (void)handlePan:(UIPanGestureRecognizer*)p{
    UIView *v=p.view; CGPoint t=[p translationInView:v.superview];
    if(p.state==UIGestureRecognizerStateBegan) _panStart=v.center;
    v.center=CGPointMake(_panStart.x+t.x,_panStart.y+t.y);
    if(p.state==UIGestureRecognizerStateEnded){
        CGFloat mid=CGRectGetMidX(v.superview.bounds);
        CGFloat tx= v.center.x < mid ? 34 : v.superview.bounds.size.width-34;
        [UIView animateWithDuration:0.25 animations:^{ v.center=CGPointMake(tx, v.center.y); }];
    }
}
- (void)togglePanel{ BOOL s=_panelBG.hidden; if(s) [self refreshUI]; _panelBG.hidden=!s; _floatBtn.alpha=s?0.2:1.0; }

- (UILabel*)section:(NSString*)t{
    UILabel *l=[UILabel new]; l.text=t; l.font=[UIFont boldSystemFontOfSize:12]; l.textColor=[UIColor secondaryLabelColor]; l.numberOfLines=0; return l;
}
- (UIView*)rowForKey:(NSString*)key label:(NSString*)lab min:(float)mn max:(float)mx{
    UIView *row=[UIView new];
    UILabel *ttl=[UILabel new]; ttl.text=lab; ttl.font=[UIFont systemFontOfSize:13.5 weight:UIFontWeightMedium]; ttl.translatesAutoresizingMaskIntoConstraints=NO; [ttl.widthAnchor constraintEqualToConstant:150].active=YES;
    UISlider *sl=[UISlider new]; sl.minimumValue=mn; sl.maximumValue=mx; sl.value=[self cur:key]; sl.accessibilityIdentifier=key; [sl addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
    UILabel *val=[UILabel new]; val.font=[UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium]; val.textColor=[UIColor systemBlueColor]; val.text=[NSString stringWithFormat:@"%.2f",sl.value]; val.translatesAutoresizingMaskIntoConstraints=NO; [val.widthAnchor constraintEqualToConstant:44].active=YES; val.textAlignment=NSTextAlignmentRight;
    _sliders[key]=sl; _valueLabels[key]=val;
    UIStackView *h=[[UIStackView alloc] initWithArrangedSubviews:@[ttl,sl,val]]; h.axis=UILayoutConstraintAxisHorizontal; h.spacing=8; h.alignment=UIStackViewAlignmentCenter; h.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:h];
    [NSLayoutConstraint activateConstraints:@[[h.topAnchor constraintEqualToAnchor:row.topAnchor],[h.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],[h.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],[h.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]]];
    return row;
}
- (UIView*)axisRowForSensorIdx:(int)idx axis:(int)axisIdx name:(NSString*)sensorName{
    NSArray *keys=sensorKeys(); NSString *base=keys[idx];
    NSArray *ax=axisLetters(); NSString *letter=ax[axisIdx];
    NSString *key=[base stringByAppendingString:letter];
    NSString *disp=[NSString stringWithFormat:@"%@  %@", sensorName, [sensorName isEqualToString:@"Attitude"] ? (@[@"Roll",@"Pitch",@"Yaw"][axisIdx]) : letter];
    // color dot
    UIView *row=[UIView new];
    UILabel *ttl=[UILabel new]; ttl.translatesAutoresizingMaskIntoConstraints=NO; [ttl.widthAnchor constraintEqualToConstant:150].active=YES;
    NSMutableAttributedString *at=[[NSMutableAttributedString alloc] initWithString:[sensorName uppercaseString] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:9], NSForegroundColorAttributeName:[UIColor secondaryLabelColor]}];
    UIColor *c = axisIdx==0?[UIColor systemRedColor]: axisIdx==1?[UIColor systemGreenColor]:[UIColor systemBlueColor];
    NSAttributedString *let=[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", disp] attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:13], NSForegroundColorAttributeName:c}];
    [at appendAttributedString:let]; ttl.attributedText=at;

    UISlider *sl=[UISlider new]; sl.minimumValue=0; sl.maximumValue=5; sl.value=(float)gAxis[idx][axisIdx]; sl.accessibilityIdentifier=key; [sl addTarget:self action:@selector(axisChanged:) forControlEvents:UIControlEventValueChanged];
    UILabel *val=[UILabel new]; val.font=[UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightMedium]; val.textColor=c; val.text=[NSString stringWithFormat:@"%.2f",sl.value]; val.translatesAutoresizingMaskIntoConstraints=NO; [val.widthAnchor constraintEqualToConstant:44].active=YES; val.textAlignment=NSTextAlignmentRight;
    _sliders[key]=sl; _valueLabels[key]=val;
    UIStackView *h=[[UIStackView alloc] initWithArrangedSubviews:@[ttl,sl,val]]; h.axis=UILayoutConstraintAxisHorizontal; h.spacing=8; h.alignment=UIStackViewAlignmentCenter; h.translatesAutoresizingMaskIntoConstraints=NO;
    [row addSubview:h];
    [NSLayoutConstraint activateConstraints:@[[h.topAnchor constraintEqualToAnchor:row.topAnchor],[h.leadingAnchor constraintEqualToAnchor:row.leadingAnchor],[h.trailingAnchor constraintEqualToAnchor:row.trailingAnchor],[h.bottomAnchor constraintEqualToAnchor:row.bottomAnchor]]];
    return row;
}
- (float)cur:(NSString*)k{
    if([k isEqualToString:@"accel"]) return gBase[S_ACCEL];
    if([k isEqualToString:@"gyro"]) return gBase[S_GYRO];
    if([k isEqualToString:@"mag"]) return gBase[S_MAG];
    if([k isEqualToString:@"userAccel"]) return gBase[S_USERACCEL];
    if([k isEqualToString:@"gravity"]) return gBase[S_GRAVITY];
    if([k isEqualToString:@"rotRate"]) return gBase[S_ROTRATE];
    if([k isEqualToString:@"magCal"]) return gBase[S_MAGCAL];
    if([k isEqualToString:@"attitude"]) return gBase[S_ATT];
    if([k isEqualToString:@"steps"]) return (float)mSteps;
    if([k isEqualToString:@"distance"]) return (float)mDistance;
    if([k isEqualToString:@"pressure"]) return (float)mPressure;
    if([k isEqualToString:@"relAlt"]) return (float)mRelAlt;
    // per-axis fallback
    NSArray *keys=sensorKeys(); NSArray *ax=axisLetters();
    for(int s=0;s<S_COUNT;s++) for(int a=0;a<3;a++) if([[keys[s] stringByAppendingString:ax[a]] isEqualToString:k]) return (float)gAxis[s][a];
    return 1;
}
- (void)setCur:(float)v key:(NSString*)k{
    if([k isEqualToString:@"accel"]) gBase[S_ACCEL]=v; else if([k isEqualToString:@"gyro"]) gBase[S_GYRO]=v; else if([k isEqualToString:@"mag"]) gBase[S_MAG]=v;
    else if([k isEqualToString:@"userAccel"]) gBase[S_USERACCEL]=v; else if([k isEqualToString:@"gravity"]) gBase[S_GRAVITY]=v; else if([k isEqualToString:@"rotRate"]) gBase[S_ROTRATE]=v;
    else if([k isEqualToString:@"magCal"]) gBase[S_MAGCAL]=v; else if([k isEqualToString:@"attitude"]) gBase[S_ATT]=v;
    else if([k isEqualToString:@"steps"]) mSteps=v; else if([k isEqualToString:@"distance"]) mDistance=v; else if([k isEqualToString:@"pressure"]) mPressure=v; else if([k isEqualToString:@"relAlt"]) mRelAlt=v;
}
- (void)changed:(UISlider*)s{ NSString *k=s.accessibilityIdentifier; ((UILabel *)_valueLabels[k]).text=[NSString stringWithFormat:@"%.2f",s.value]; [self setCur:s.value key:k]; }
- (void)axisChanged:(UISlider*)s{
    NSString *k=s.accessibilityIdentifier; ((UILabel *)_valueLabels[k]).text=[NSString stringWithFormat:@"%.2f",s.value];
    NSArray *keys=sensorKeys(); NSArray *ax=axisLetters();
    for(int si=0;si<S_COUNT;si++) for(int a=0;a<3;a++) if([[keys[si] stringByAppendingString:ax[a]] isEqualToString:k]){ gAxis[si][a]=s.value; return; }
}

- (void)buildCardContent{
    UILabel *t=[UILabel new]; t.text=@"MotionSpoofer • In-App"; t.font=[UIFont boldSystemFontOfSize:18]; t.textAlignment=NSTextAlignmentCenter; [_stack addArrangedSubview:t];
    UILabel *sub=[UILabel new]; sub.text=@"Drag blue MS. Tap to open. Save persists after kill/reboot. 1.0 = real."; sub.font=[UIFont systemFontOfSize:11]; sub.textColor=[UIColor secondaryLabelColor]; sub.numberOfLines=0; sub.textAlignment=NSTextAlignmentCenter; [_stack addArrangedSubview:sub];

    UIStackView *enRow=[UIStackView new]; enRow.axis=UILayoutConstraintAxisHorizontal; enRow.spacing=8;
    UILabel *enL=[UILabel new]; enL.text=@"Enabled"; enL.font=[UIFont boldSystemFontOfSize:15];
    _enabledSwitch=[UISwitch new]; _enabledSwitch.on=gEnabled; [_enabledSwitch addTarget:self action:@selector(enToggled:) forControlEvents:UIControlEventValueChanged];
    UIView *sp=[UIView new]; [sp setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [enRow addArrangedSubview:enL]; [enRow addArrangedSubview:sp]; [enRow addArrangedSubview:_enabledSwitch];
    [_stack addArrangedSubview:enRow];

    UIView *sep=[UIView new]; sep.backgroundColor=[UIColor separatorColor]; [sep.heightAnchor constraintEqualToConstant:1].active=YES; [_stack addArrangedSubview:sep];

    [_stack addArrangedSubview:[self section:@"RAW SENSORS"]];
    [_stack addArrangedSubview:[self rowForKey:@"accel" label:@"Accelerometer" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"gyro" label:@"Gyroscope" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"mag" label:@"Magnetometer" min:0 max:5]];

    [_stack addArrangedSubview:[self section:@"DEVICE MOTION"]];
    [_stack addArrangedSubview:[self rowForKey:@"userAccel" label:@"User Accel" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"gravity" label:@"Gravity" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"rotRate" label:@"Rotation Rate" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"magCal" label:@"Calib. Mag Field" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"attitude" label:@"Attitude (r/p/y)" min:0 max:5]];

    [_stack addArrangedSubview:[self section:@"ACTIVITY"]];
    [_stack addArrangedSubview:[self rowForKey:@"steps" label:@"Step Count" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"distance" label:@"Distance" min:0 max:5]];

    [_stack addArrangedSubview:[self section:@"BAROMETER"]];
    [_stack addArrangedSubview:[self rowForKey:@"pressure" label:@"Pressure" min:0 max:5]];
    [_stack addArrangedSubview:[self rowForKey:@"relAlt" label:@"Relative Alt" min:0 max:5]];

    // Advanced toggle
    UIStackView *advRow=[UIStackView new]; advRow.axis=UILayoutConstraintAxisHorizontal; advRow.spacing=8;
    UILabel *advL=[UILabel new]; advL.text=@"Per-axis Advanced Mode"; advL.font=[UIFont boldSystemFontOfSize:13]; advL.numberOfLines=0;
    _advSwitch=[UISwitch new]; _advSwitch.on=gAdv; [_advSwitch addTarget:self action:@selector(advToggled:) forControlEvents:UIControlEventValueChanged];
    UIView *sp2=[UIView new]; [sp2 setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [advRow addArrangedSubview:advL]; [advRow addArrangedSubview:sp2]; [advRow addArrangedSubview:_advSwitch];
    [_stack addArrangedSubview:advRow];
    UILabel *advHint=[UILabel new]; advHint.text=@"When ON, X/Y/Z sliders below OVERRIDE the single sliders above. Colours: X=red Y=green Z=blue."; advHint.font=[UIFont systemFontOfSize:10]; advHint.textColor=[UIColor secondaryLabelColor]; advHint.numberOfLines=0; [_stack addArrangedSubview:advHint];

    // Per-axis container
    _advContainer=[UIView new];
    UIStackView *advStack=[UIStackView new]; advStack.axis=UILayoutConstraintAxisVertical; advStack.spacing=8; advStack.translatesAutoresizingMaskIntoConstraints=NO;
    [_advContainer addSubview:advStack];
    [NSLayoutConstraint activateConstraints:@[[advStack.topAnchor constraintEqualToAnchor:_advContainer.topAnchor],[advStack.leadingAnchor constraintEqualToAnchor:_advContainer.leadingAnchor],[advStack.trailingAnchor constraintEqualToAnchor:_advContainer.trailingAnchor],[advStack.bottomAnchor constraintEqualToAnchor:_advContainer.bottomAnchor]]];
    NSArray *labs=sensorLabels();
    for(int s=0;s<S_COUNT;s++){
        UILabel *sec=[UILabel new]; sec.text=[NSString stringWithFormat:@"— %@ —", labs[s]]; sec.font=[UIFont systemFontOfSize:11 weight:UIFontWeightSemibold]; sec.textColor=[UIColor labelColor]; sec.textAlignment=NSTextAlignmentCenter;
        [advStack addArrangedSubview:sec];
        for(int a=0;a<3;a++) [advStack addArrangedSubview:[self axisRowForSensorIdx:s axis:a name:labs[s]]];
    }
    _advContainer.hidden=!gAdv;
    [_stack addArrangedSubview:_advContainer];

    // Save
    UIButton *save=[UIButton buttonWithType:UIButtonTypeSystem]; [save setTitle:@"💾 Save & Apply  (persists after restart)" forState:UIControlStateNormal]; save.titleLabel.font=[UIFont boldSystemFontOfSize:14]; save.backgroundColor=[UIColor systemBlueColor]; [save setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; save.layer.cornerRadius=11; [save.heightAnchor constraintEqualToConstant:46].active=YES; [save addTarget:self action:@selector(saveTap) forControlEvents:UIControlEventTouchUpInside]; [_stack addArrangedSubview:save];

    UIStackView *btns=[UIStackView new]; btns.axis=UILayoutConstraintAxisHorizontal; btns.spacing=8; btns.distribution=UIStackViewDistributionFillEqually;
    UIButton *rst=[UIButton buttonWithType:UIButtonTypeSystem]; [rst setTitle:@"Reset 1.0×" forState:UIControlStateNormal]; rst.backgroundColor=[UIColor secondarySystemFillColor]; rst.layer.cornerRadius=8; [rst.heightAnchor constraintEqualToConstant:40].active=YES; [rst addTarget:self action:@selector(resetTap) forControlEvents:UIControlEventTouchUpInside];
    UIButton *hide=[UIButton buttonWithType:UIButtonTypeSystem]; [hide setTitle:@"Close" forState:UIControlStateNormal]; hide.backgroundColor=[UIColor secondarySystemFillColor]; hide.layer.cornerRadius=8; [hide addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [btns addArrangedSubview:rst]; [btns addArrangedSubview:hide]; [_stack addArrangedSubview:btns];

    UIButton *rm=[UIButton buttonWithType:UIButtonTypeSystem]; [rm setTitle:@"Hide floating button until next launch" forState:UIControlStateNormal]; rm.titleLabel.font=[UIFont systemFontOfSize:11]; [rm setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateNormal]; [rm addTarget:self action:@selector(hideFloat) forControlEvents:UIControlEventTouchUpInside]; [_stack addArrangedSubview:rm];
}
- (void)enToggled:(UISwitch*)s{ gEnabled=s.isOn; }
- (void)advToggled:(UISwitch*)s{ gAdv=s.isOn; _advContainer.hidden=!s.isOn; }
- (void)saveTap{ savePrefs(); UIImpactFeedbackGenerator *g=[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium]; [g impactOccurred]; [self togglePanel]; }
- (void)resetTap{
    for(NSString *k in _sliders.allKeys){ UISlider *sl=(UISlider *)_sliders[k]; sl.value=1.0; ((UILabel *)_valueLabels[k]).text=@"1.00"; if([k containsString:@"X"]||[k containsString:@"Y"]||[k containsString:@"Z"]||[k isEqualToString:@"Roll"]||[k isEqualToString:@"Pitch"]||[k isEqualToString:@"Yaw"]) { /* per-axis handled via axisChanged path */ NSArray *keys=sensorKeys(); NSArray *ax=axisLetters(); for(int si=0;si<S_COUNT;si++) for(int a=0;a<3;a++) if([[keys[si] stringByAppendingString:ax[a]] isEqualToString:k]) gAxis[si][a]=1; } else [self setCur:1 key:k]; }
    gEnabled=YES; gAdv=NO; _enabledSwitch.on=YES; _advSwitch.on=NO; _advContainer.hidden=YES;
}
- (void)hideFloat{ _floatBtn.hidden=YES; _panelBG.hidden=YES; }
- (void)refreshUI{
    _enabledSwitch.on=gEnabled; _advSwitch.on=gAdv; _advContainer.hidden=!gAdv;
    for(NSString *k in _sliders.allKeys){ float v=[self cur:k]; // per-axis needs direct
        // per-axis keys not in cur's switch, fetch from gAxis
        NSArray *keys=sensorKeys(); NSArray *ax=axisLetters(); BOOL found=NO;
        for(int si=0;si<S_COUNT;si++) for(int a=0;a<3;a++) if([[keys[si] stringByAppendingString:ax[a]] isEqualToString:k]){ v=(float)gAxis[si][a]; found=YES; }
        UISlider *sl=(UISlider *)_sliders[k]; sl.value=v; ((UILabel *)_valueLabels[k]).text=[NSString stringWithFormat:@"%.2f",v];
    }
}
@end

%ctor{
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR(PREF_CHANGED), NULL, CFNotificationSuspensionBehaviorCoalesce);
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n){ dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.0*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ [[MSMotionOverlay shared] installIfNeeded]; }); }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ if([UIApplication sharedApplication].applicationState!=UIApplicationStateBackground) [[MSMotionOverlay shared] installIfNeeded]; });
}
