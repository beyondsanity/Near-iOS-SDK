//
//  NITManager.h
//  NearITSDK
//
//  Created by Francesco Leoni on 14/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITRecipesManager;
@class NITRecipe;
@class NITManager;
@class NITEvent;
@class NITCoupon;
@class UNNotificationResponse;
@class UILocalNotification;
@class NITTrackingInfo;

@protocol NITManaging <NSObject>

- (void)recipesManager:(NITRecipesManager* _Nonnull)recipesManager gotRecipe:(NITRecipe* _Nonnull)recipe trackingInfo:(NITTrackingInfo* _Nonnull)trackingInfo;

@end

@protocol NITManagerDelegate <NSObject>

- (void)manager:(NITManager* _Nonnull)manager eventWithContent:(id _Nonnull)content trackingInfo:(NITTrackingInfo* _Nonnull)trackingInfo;
- (void)manager:(NITManager* _Nonnull)manager eventFailureWithError:(NSError* _Nonnull)error;

@end

@interface NITManager : NSObject

@property (nonatomic, weak) id<NITManagerDelegate> _Nullable delegate;
@property (nonatomic) BOOL showBackgroundNotification;

+ (void)setupWithApiKey:(NSString* _Nonnull)apiKey;
+ (NITManager* _Nonnull)defaultManager;

- (void)start;
- (void)stop;
- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)setDeviceTokenWithData:(NSData* _Nonnull)token;
- (BOOL)processRecipeSimpleWithUserInfo:(NSDictionary<NSString*, id> * _Nullable)userInfo;
- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event;
- (void)setUserDataWithKey:(NSString* _Nonnull)key value:(NSString* _Nullable)value completionHandler:(void (^_Nullable)(NSError* _Nullable error))handler;
- (void)setBatchUserDataWithDictionary:(NSDictionary<NSString*, id>* _Nonnull)valuesDictiornary completionHandler:(void (^_Nullable)(NSError* _Nullable error))handler;
- (void)setDeferredUserDataWithKey:(NSString * _Nonnull)key value:(NSString * _Nonnull)value;
- (void)sendEventWithEvent:(NITEvent* _Nonnull)event completionHandler:(void (^_Nullable)(NSError* _Nullable error))handler;
- (void)couponsWithCompletionHandler:(void (^ _Nullable)(NSArray<NITCoupon*>* _Nullable, NSError* _Nullable))handler;
- (void)recipesWithCompletionHandler:(void (^_Nullable)(NSArray<NITRecipe*>* _Nullable recipes, NSError * _Nullable error))completionHandler;
- (void)processRecipeWithId:(NSString* _Nonnull)recipeId;
- (BOOL)processRecipeWithUserInfo:(NSDictionary<NSString *,id> * _Nonnull)userInfo completion:(void (^_Nullable)(id _Nullable object, NITRecipe* _Nullable recipe, NSError* _Nullable error))completionHandler;
- (void)resetProfile;
- (NSString* _Nullable)profileId;
- (void)setProfileId:(NSString * _Nonnull)profileId;

@end
