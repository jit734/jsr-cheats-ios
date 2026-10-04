//
//  JSRCheatsDylibEngine.h
//  JSR CHEATS - Free Fire MAX ESP & Mod Menu Engine
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSRCheatsDylibEngine : NSObject

@property (nonatomic, assign) BOOL isESPLineEnabled;
@property (nonatomic, assign) BOOL isESPBoxEnabled;
@property (nonatomic, assign) BOOL isESPDistanceEnabled;
@property (nonatomic, assign) BOOL isAimLockEnabled;
@property (nonatomic, assign) BOOL isAimDragEnabled;
@property (nonatomic, assign) BOOL isMagicBulletEnabled;

+ (instancetype)sharedInstance;
- (void)initializeEngineForGame:(NSString *)bundleID;
- (void)toggleFeature:(NSString *)featureName state:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
