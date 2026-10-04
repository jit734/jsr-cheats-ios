//
//  JSRCheatsDylibEngine.m
//  JSR CHEATS - Free Fire MAX ESP & Mod Menu Engine
//

#import "JSRCheatsDylibEngine.h"
#import <objc/runtime.h>
#import <mach-o/dyld.h>

@implementation JSRCheatsDylibEngine

+ (instancetype)sharedInstance {
    static JSRCheatsDylibEngine *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JSRCheatsDylibEngine alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isESPLineEnabled = YES;
        _isESPBoxEnabled = YES;
        _isESPDistanceEnabled = YES;
        _isAimLockEnabled = YES;
        _isAimDragEnabled = YES;
        _isMagicBulletEnabled = YES;
    }
    return self;
}

- (void)initializeEngineForGame:(NSString *)bundleID {
    NSLog(@"[JSR CHEATS Engine] Initialized for bundle: %@", bundleID);
    [self setupFloatingMenuOverlay];
}

- (void)setupFloatingMenuOverlay {
    dispatch_async(dispatch_get_main_actor(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) return;

        UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingBtn.frame = CGRectMake(20, 120, 50, 50);
        floatingBtn.layer.cornerRadius = 25;
        floatingBtn.backgroundColor = [UIColor colorWithRed:0.90 green:0.22 blue:0.21 alpha:0.9];
        [floatingBtn setTitle:@"JSR" forState:UIControlStateNormal];
        floatingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        [floatingBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [floatingBtn addGestureRecognizer:pan];

        [keyWindow addSubview:floatingBtn];
        NSLog(@"[JSR CHEATS Engine] Floating overlay injected successfully!");
    });
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    CGPoint translation = [pan translationInView:btn.superview];
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:btn.superview];
}

- (void)toggleFeature:(NSString *)featureName state:(BOOL)enabled {
    NSLog(@"[JSR CHEATS Engine] Feature '%@' set to %@", featureName, enabled ? @"ON" : @"OFF");
}

@end

__attribute__((constructor)) static void ctor(void) {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        NSLog(@"[JSR CHEATS] Constructor triggered in process: %@", bundleID);
        if ([bundleID isEqualToString:@"com.dts.freefiremax"] || [bundleID isEqualToString:@"com.dts.freefireth"]) {
            [[JSRCheatsDylibEngine sharedInstance] initializeEngineForGame:bundleID];
        }
    }
}
