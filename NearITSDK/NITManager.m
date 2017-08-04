//
//  NITManager.m
//  NearITSDK
//
//  Created by Francesco Leoni on 14/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITManager.h"
#import "NITConfiguration.h"
#import "NITUserProfile.h"
#import "NITUtils.h"
#import "NITGeopolisManager.h"
#import "NITReaction.h"
#import "NITSimpleNotificationReaction.h"
#import "NITRecipe.h"
#import "NITContentReaction.h"
#import "NITCouponReaction.h"
#import "NITFeedbackReaction.h"
#import "NITCustomJSONReaction.h"
#import "NITInstallation.h"
#import "NITEvent.h"
#import "NITConstants.h"
#import "NITGeopolisNodesManager.h"
#import "NITNetworkManager.h"
#import "NITNetworkProvider.h"
#import "NITTrackManager.h"
#import "NITDateManager.h"
#import "NITRecipeHistory.h"
#import "NITCooldownValidator.h"
#import "NITScheduleValidator.h"
#import "NITRecipeValidationFilter.h"
#import "NITReachability.h"
#import "NSData+Zip.h"
#import "NITJSONAPI.h"
#import "NITReaction.h"
#import "NITNotificationProcessor.h"
#import "NITUserDataBackoff.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <UserNotifications/UserNotifications.h>

#define LOGTAG @"Manager"

static NSString *const defaultManagerLock = @"manager.lock";
static NITManager *defaultManager;

@interface NITManager()<NITManaging, CBCentralManagerDelegate, NITUserProfileDelegate>

@property (nonatomic, strong) NITGeopolisManager *geopolisManager;
@property (nonatomic, strong) NITRecipesManager *recipesManager;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NITReaction*> *reactions;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITConfiguration *configuration;
@property (nonatomic, strong) NITUserProfile *profile;
@property (nonatomic, strong) NITTrackManager *trackManager;
@property (nonatomic, strong) CBCentralManager *bluetoothManager;
@property (nonatomic, strong) NITNotificationProcessor *notificationProcessor;
@property (nonatomic, strong) UIApplication *application;
@property (nonatomic, strong) UNUserNotificationCenter *userNotificationCenter;
@property (nonatomic) CBManagerState lastBluetoothState;
@property (nonatomic) BOOL started;

@end

@implementation NITManager

+ (void)setupWithApiKey:(NSString*)apiKey {
    NITConfiguration *configuration = [NITConfiguration defaultConfiguration];
    [configuration setApiKey:apiKey];
    NITManager *manager = [NITManager defaultManager];
    [manager firstRun];
}

+ (NITManager*)defaultManager {
    @synchronized (defaultManagerLock) {
        if (!defaultManager) {
            defaultManager = [[NITManager alloc] initManager];
        }
    }
    return defaultManager;
}

- (instancetype _Nonnull)initManager {
    NITConfiguration *configuration = [NITConfiguration defaultConfiguration];
    id<NITNetworkManaging> networkManager = [[NITNetworkManager alloc] init];
    NITCacheManager *cacheManager = [[NITCacheManager alloc] initWithAppId:self.configuration.appId];
    CBCentralManager *bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey : [NSNumber numberWithBool:NO]}];
    
    NITReachability *internetReachability =  [NITReachability reachabilityForInternetConnection];
    NITInstallation *installation = [[NITInstallation alloc] initWithConfiguration:configuration networkManager:networkManager reachability:internetReachability];
    NITUserDataBackoff *userDataBackoff = [[NITUserDataBackoff alloc] initWithConfiguration:configuration networkManager:networkManager cacheManager:cacheManager];
    NITUserProfile *profile = [[NITUserProfile alloc] initWithConfiguration:configuration networkManager:networkManager installation:installation userDataBackoff:userDataBackoff];
    
    NITDateManager *dateManager = [[NITDateManager alloc] init];
    NITTrackManager *trackManager = [[NITTrackManager alloc] initWithNetworkManager:networkManager cacheManager:cacheManager reachability:internetReachability notificationCenter:[NSNotificationCenter defaultCenter] dateManager:dateManager];
    
    NITRecipesManager *recipesManager = [self makeRecipesManagerWithNetworkManager:networkManager cacheManager:cacheManager configuration:configuration trackManager:trackManager];
    NITGeopolisManager *geopolisManager = [NITManager makeGeopolisManagerWithNetworkManager:networkManager cacheManager:cacheManager configuration:configuration trackManager:trackManager];
    
    NSMutableDictionary<NSString*, NITReaction*> *reactions = [NITManager makeReactionsWithConfiguration:configuration cacheManager:cacheManager networkManager:networkManager];
    
    self = [self initWithConfiguration:configuration application:[UIApplication sharedApplication] networkManager:networkManager cacheManager:cacheManager bluetoothManager:bluetoothManager profile:profile trackManager:trackManager recipesManager:recipesManager geopolisManager:geopolisManager reactions:reactions];
    if (NSClassFromString(@"UNUserNotificationCenter")) {
        self.userNotificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    }
    return self;
}

- (instancetype _Nonnull)initWithConfiguration:(NITConfiguration*)configuration application:(UIApplication*)application networkManager:(id<NITNetworkManaging>)networkManager cacheManager:(NITCacheManager*)cacheManager bluetoothManager:(CBCentralManager*)bluetoothManager profile:(NITUserProfile*)profile trackManager:(NITTrackManager*)trackManager recipesManager:(NITRecipesManager*)recipesManager geopolisManager:(NITGeopolisManager*)geopolisManager reactions:(NSMutableDictionary<NSString*, NITReaction*>*)reactions {
    self = [super init];
    if (self) {
        self.showBackgroundNotification = YES;
        self.application = application;
        
        self.configuration = configuration;
        self.networkManager = networkManager;
        self.cacheManager = cacheManager;
        self.bluetoothManager = bluetoothManager;
        self.lastBluetoothState = self.bluetoothManager.state;
        self.recipesManager = recipesManager;
        self.recipesManager.manager = self;
        self.geopolisManager = geopolisManager;
        self.geopolisManager.recipesManager = self.recipesManager;
        self.reactions = reactions;
        
        [[NITNetworkProvider sharedInstance] setConfiguration:self.configuration];
        
        self.profile = profile;
        self.profile.delegate = self;
        
        self.trackManager = trackManager;
        
        [self.cacheManager setAppId:[self.configuration appId]];
        self.started = NO;
        self.notificationProcessor = [[NITNotificationProcessor alloc] initWithRecipesManager:self.recipesManager reactions:self.reactions];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBeacomActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)firstRun {
    [self.profile createNewProfileWithCompletionHandler:^(NSString * _Nullable profileId, NSError * _Nullable error) {
        if(error == nil) {
            NITLogD(LOGTAG, @"Profile creation successful: %@", profileId);
            [self refreshConfigWithCompletionHandler:nil];
        } else {
            NITLogE(LOGTAG, @"Profile creation error");
        }
    }];
}

- (void)start {
    self.started = YES;
    [self.geopolisManager start];
}

- (void)stop {
    self.started = NO;
    [self.geopolisManager stop];
}

- (NITRecipesManager*)makeRecipesManagerWithNetworkManager:(id<NITNetworkManaging>)networkManager cacheManager:(NITCacheManager*)cacheManager configuration:(NITConfiguration*)configuration trackManager:(NITTrackManager*)trackManager {
    NITDateManager *dateManager = [[NITDateManager alloc] init];
    NITRecipeHistory *recipeHistory = [[NITRecipeHistory alloc] initWithCacheManager:cacheManager dateManager:dateManager];
    NITCooldownValidator *cooldownValidator = [[NITCooldownValidator alloc] initWithRecipeHistory:recipeHistory dateManager:dateManager];
    NITScheduleValidator *scheduleValidator = [[NITScheduleValidator alloc] initWithDateManager:dateManager];
    NITRecipeValidationFilter *recipeValidationFilter = [[NITRecipeValidationFilter alloc] initWithValidators:@[cooldownValidator, scheduleValidator]];
    return [[NITRecipesManager alloc] initWithCacheManager:cacheManager networkManager:networkManager configuration:configuration trackManager:trackManager recipeHistory:recipeHistory recipeValidationFilter:recipeValidationFilter dateManager:dateManager];
}

+ (NITGeopolisManager*)makeGeopolisManagerWithNetworkManager:(id<NITNetworkManaging>)networkManager cacheManager:(NITCacheManager*)cacheManager configuration:(NITConfiguration*)configuration trackManager:(NITTrackManager*)trackManager {
    NITGeopolisNodesManager *nodesManager = [[NITGeopolisNodesManager alloc] init];
    NITGeopolisManager *geopolisManager = [[NITGeopolisManager alloc] initWithNodesManager:nodesManager cachaManager:cacheManager networkManager:networkManager configuration:configuration trackManager:trackManager];
    return geopolisManager;
}

+ (NSMutableDictionary<NSString*, NITReaction*>*)makeReactionsWithConfiguration:(NITConfiguration*)configuration cacheManager:(NITCacheManager*)cacheManager networkManager:(id<NITNetworkManaging>)networkManager {
    NSMutableDictionary<NSString*, NITReaction*> *reactions = [[NSMutableDictionary alloc] init];
    
    [reactions setObject:[[NITSimpleNotificationReaction alloc] initWithCacheManager:cacheManager networkManager:networkManager] forKey:NITSimpleNotificationPluginName];
    [reactions setObject:[[NITContentReaction alloc] initWithCacheManager:cacheManager networkManager:networkManager] forKey:NITContentPluginName];
    [reactions setObject:[[NITCouponReaction alloc] initWithCacheManager:cacheManager configuration:configuration networkManager:networkManager] forKey:NITCouponPluginName];
    [reactions setObject:[[NITFeedbackReaction alloc] initWithCacheManager:cacheManager configuration:configuration networkManager:networkManager] forKey:NITFeedbackPluginName];
    [reactions setObject:[[NITCustomJSONReaction alloc] initWithCacheManager:cacheManager networkManager:networkManager] forKey:NITCustomJSONPluginName];
    
    return reactions;
}

- (void)refreshConfigWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler {
    NSMutableArray *errors = [[NSMutableArray alloc] init];
    
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    [self.geopolisManager refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            [errors addObject:error];
        } else {
            if(self.started) {
                [self.geopolisManager restart];
            }
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_enter(group);
    [self.recipesManager refreshConfigCheckTimeWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            [errors addObject:error];
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (completionHandler) {
            if ([errors count] > 0) {
                NITLogE(LOGTAG, @"Config download error");
                NSError *anError = [NSError errorWithDomain:NITManagerErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey:@"Refresh config failed for some reason, check the 'errors' key for more detail", @"errors" : errors}];
                completionHandler(anError);
            } else {
                NITLogD(LOGTAG, @"Config downloaded");
                completionHandler(nil);
            }
        }
    });
    
    for(NSString *reactionKey in self.reactions) {
        NITReaction *reaction = [self.reactions objectForKey:reactionKey];
        [reaction refreshConfigWithCompletionHandler:nil];
    }
}

/**
 * Set the APN token for push.
 * @param token The token received from Apple
 */
- (void)setDeviceTokenWithData:(NSData *)token {
    NSString *tokenString = [[[[token description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    [self.configuration setDeviceToken:tokenString];
    [self.profile.installation registerInstallation];
}

/**
 * Process a recipe from a remote notification.
 * @param userInfo The remote notification userInfo dictionary
 */
- (BOOL)processRecipeSimpleWithUserInfo:(NSDictionary<NSString *,id> *)userInfo {
    if ([self.notificationProcessor isRemoteNotificationWithUserInfo:userInfo]) {
        return [self.notificationProcessor processNotificationWithUserInfo:userInfo completion:^(id  _Nullable content, NSString * _Nullable recipeId, NSError * _Nullable error) {
            NITRecipe *recipe = [[NITRecipe alloc] init];
            recipe.ID = recipeId;
            if([self.delegate respondsToSelector:@selector(manager:eventFailureWithError:recipe:)] && error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate manager:self eventFailureWithError:error recipe:recipe];
                }];
            } else if ([self.delegate respondsToSelector:@selector(manager:eventWithContent:recipe:)]) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate manager:self eventWithContent:content recipe:recipe];
                }];
            }
        }];
    } else {
        return [self handleLocalUserInfo:userInfo completionHandler:^(id _Nullable content, NITRecipe * _Nullable recipe, NSError * _Nullable error) {
            if([self.delegate respondsToSelector:@selector(manager:eventFailureWithError:recipe:)] && error) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate manager:self eventFailureWithError:error recipe:recipe];
                }];
            } else if ([self.delegate respondsToSelector:@selector(manager:eventWithContent:recipe:)]) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.delegate manager:self eventWithContent:content recipe:recipe];
                }];
            }
        }];
    }
}

- (BOOL)processRecipeWithUserInfo:(NSDictionary<NSString *,id> *)userInfo completion:(void (^)(id _Nullable, NITRecipe * _Nullable, NSError * _Nullable))completionHandler {
    if ([self.notificationProcessor isRemoteNotificationWithUserInfo:userInfo]) {
        return [self.notificationProcessor processNotificationWithUserInfo:userInfo completion:^(id  _Nullable content, NSString * _Nullable recipeId, NSError * _Nullable error) {
            if (completionHandler) {
                NITRecipe *recipe = [[NITRecipe alloc] init];
                recipe.ID = recipeId;
                completionHandler(content, recipe, error);
            }
        }];
    } else {
        return [self handleLocalUserInfo:userInfo completionHandler:^(id _Nullable content, NITRecipe * _Nullable recipe, NSError * _Nullable error) {
            completionHandler(content, recipe, error);
        }];
    }
}

- (void)sendTrackingWithRecipeId:(NSString *)recipeId event:(NSString *)event {
    [self.recipesManager sendTrackingWithRecipeId:recipeId event:event];
}

- (void)setUserDataWithKey:(NSString *)key value:(NSString *)value completionHandler:(void (^)(NSError * _Nullable))handler {
    NITRecipesManager *recipesManager = self.recipesManager;
    [self.profile setUserDataWithKey:key value:value completionHandler:^(NSError * _Nullable error) {
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler(error);
            }];
        }
        [recipesManager refreshConfigWithCompletionHandler:nil];
    }];
}

- (void)setBatchUserDataWithDictionary:(NSDictionary<NSString *,id> *)valuesDictiornary completionHandler:(void (^)(NSError * _Nullable))handler {
    NITRecipesManager *recipesManager = self.recipesManager;
    [self.profile setBatchUserDataWithDictionary:valuesDictiornary completionHandler:^(NSError * _Nullable error) {
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler(error);
            }];
        }
        [recipesManager refreshConfigWithCompletionHandler:nil];
    }];
}

- (void)setDeferredUserDataWithKey:(NSString *)key value:(NSString *)value {
    [self.profile setDeferredUserDataWithKey:key value:value];
}

- (void)sendEventWithEvent:(NITEvent *)event completionHandler:(void (^)(NSError * _Nullable))handler {
    if ([[event pluginName] isEqualToString:NITFeedbackPluginName]) {
        NITFeedbackReaction *feedbackReaction = (NITFeedbackReaction*)[self.reactions objectForKey:NITFeedbackPluginName];
        [feedbackReaction sendEventWithFeedbackEvent:(NITFeedbackEvent*)event completionHandler:^(NSError * _Nullable error) {
            if (handler) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    handler(error);
                }];
            }
        }];
    } else if (handler) {
        NSError *newError = [NSError errorWithDomain:NITReactionErrorDomain code:201 userInfo:@{NSLocalizedDescriptionKey:@"Unrecognized event action"}];
        if (handler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler(newError);
            }];
        }
    }
}

- (void)couponsWithCompletionHandler:(void (^)(NSArray<NITCoupon*>*, NSError*))handler {
    NITCouponReaction *couponReaction = (NITCouponReaction*)[self.reactions objectForKey:NITCouponPluginName];
    [couponReaction couponsWithCompletionHandler:^(NSArray<NITCoupon *> * coupons, NSError * error) {
        if (handler) {
            handler(coupons, error);
        }
    }];
}

- (void)recipesWithCompletionHandler:(void (^)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler {
    [self.recipesManager recipesWithCompletionHandler:^(NSArray<NITRecipe *> * _Nullable recipes, NSError * _Nullable error) {
        if(completionHandler) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionHandler(recipes, error);
            }];
        }
    }];
}

- (void)processRecipeWithId:(NSString *)recipeId  {
    [self.recipesManager processRecipe:recipeId];
}

- (void)resetProfile {
    [self.profile resetProfile];
    [self.profile createNewProfileWithCompletionHandler:^(NSString * _Nullable profileId, NSError * _Nullable error) {
        if(error == nil) {
            NITLogD(LOGTAG, @"Profile creation successful (reset): %@", profileId);
            [self refreshConfigWithCompletionHandler:nil];
        } else {
            NITLogE(LOGTAG, @"Profile creation error (reset)");
        }
    }];
}

- (NSString *)profileId {
    return self.configuration.profileId;
}

- (void)setProfileId:(NSString *)profileId {
    [self.profile setProfileId:profileId];
}

- (BOOL)handleLocalUserInfo:(NSDictionary* _Nonnull)userInfo completionHandler:(void (^)(id _Nullable, NITRecipe * _Nullable, NSError * _Nullable))completionHandler {
    NSString *owner = [userInfo objectForKey:@"owner"];
    NSString *type = [userInfo objectForKey:@"type"];
    NSData *recipeData = [userInfo objectForKey:@"recipe"];
    NSData *contentData = [userInfo objectForKey:@"content"];
    if (owner == nil || ![owner isEqualToString:@"NearIT"] || recipeData == nil || contentData == nil || type == nil || ![type isEqualToString:@"local"]) {
        NITLogW(LOGTAG, @"Invalid NearIT local notification");
        NSError *anError = [NSError errorWithDomain:NITManagerErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey:@"The notification response has invalid fields for a NearIT notification"}];
        if (completionHandler) {
            completionHandler(nil, nil, anError);
        }
        return NO;
    }
    
    NITRecipe *recipe = [NSKeyedUnarchiver unarchiveObjectWithData:recipeData];
    id content = [NSKeyedUnarchiver unarchiveObjectWithData:contentData];
    if (completionHandler) {
        completionHandler(content, recipe, nil);
    }
    
    return YES;
}

// MARK: - NITManaging

- (void)recipesManager:(NITRecipesManager *)recipesManager gotRecipe:(NITRecipe *)recipe {
    //Handle reaction
    NITReaction *reaction = [self.reactions objectForKey:recipe.reactionPluginId];
    if(reaction) {
        [reaction contentWithRecipe:recipe completionHandler:^(id _Nonnull content, NSError * _Nullable error) {
            if(error) {
                if([self.delegate respondsToSelector:@selector(manager:eventFailureWithError:recipe:)]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.delegate manager:self eventFailureWithError:error recipe:recipe];
                    }];
                }
            } else {
                //Notify the delegate
                if (self.application.applicationState != UIApplicationStateActive && self.showBackgroundNotification) {
                    [self sendTrackingWithRecipeId:recipe.ID event:NITRecipeNotified];
                    if (NSClassFromString(@"UNMutableNotificationContent")) {
                        UNMutableNotificationContent *notification = [[UNMutableNotificationContent alloc] init];
                        notification.body = recipe.notificationBody;
                        notification.sound = [UNNotificationSound defaultSound];
                        NSData *contentData = [NSKeyedArchiver archivedDataWithRootObject:content];
                        NSData *recipeData = [NSKeyedArchiver archivedDataWithRootObject:recipe];
                        if ([content conformsToProtocol:@protocol(NSCoding)]) {
                            notification.userInfo = @{@"owner" : @"NearIT", @"content" : contentData, @"recipe" : recipeData, @"type" : @"local"};
                        } else {
                            notification.userInfo = @{@"owner" : @"NearIT", @"recipeId" : recipe.ID, @"type" : @"local"};
                        }
                        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:recipe.ID content:notification trigger:trigger];
                        [self.userNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                            if (error) {
                                NITLogE(LOGTAG, @"Background notification scheduling failed: %@", error);
                            }
                        }];
                    } else {
                        UILocalNotification *notification = [[UILocalNotification alloc] init];
                        notification.alertBody = recipe.notificationBody;
                        notification.soundName = UILocalNotificationDefaultSoundName;
                        NSData *contentData = [NSKeyedArchiver archivedDataWithRootObject:content];
                        NSData *recipeData = [NSKeyedArchiver archivedDataWithRootObject:recipe];
                        if ([content conformsToProtocol:@protocol(NSCoding)]) {
                            notification.userInfo = @{@"owner" : @"NearIT", @"content" : contentData, @"recipe" : recipeData, @"type" : @"local"};
                        } else {
                            notification.userInfo = @{@"owner" : @"NearIT", @"recipeId" : recipe.ID, @"type" : @"local"};
                        }
                        notification.fireDate = [NSDate date];
                        [self.application scheduleLocalNotification:notification];
                    }
                } else if ([self.delegate respondsToSelector:@selector(manager:eventWithContent:recipe:)]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.delegate manager:self eventWithContent:content recipe:recipe];
                    }];
                }
            }
        }];
    }
}

// MARK: - Application state

- (void)applicationDidBeacomActive:(NSNotification*)notification {
    [self.profile.installation shouldRegisterInstallation];
    [self.profile shouldSendUserData];
    if (self.lastBluetoothState != self.bluetoothManager.state) {
        self.profile.installation.bluetoothState = self.lastBluetoothState;
        [self.profile.installation registerInstallation];
    }
}

// MARK: - Profile delegate

- (void)profileUserDataBackoffDidComplete:(NITUserProfile *)profile {
    [self.recipesManager refreshConfigWithCompletionHandler:^(NSError * _Nullable error) {
        NITLogI(LOGTAG, @"Recipes updated due to user data backoff completion");
    }];
}

// MARK: - Bluetooth manager delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NITLogD(LOGTAG, @"Bluetooth state change: %@", [NITUtils stringFromBluetoothState:central.state]);
    if ([self.application applicationState] == UIApplicationStateActive || [self.application applicationState] == UIApplicationStateInactive) {
        self.lastBluetoothState = central.state;
        self.profile.installation.bluetoothState = self.lastBluetoothState;
        [self.profile.installation registerInstallation];
    }
}

@end
