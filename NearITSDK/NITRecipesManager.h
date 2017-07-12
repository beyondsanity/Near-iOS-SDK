//
//  NITRecipesManager.h
//  NearITSDK
//
//  Created by Francesco Leoni on 20/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITManager.h"
#import "NITNetworkManaging.h"

@class NITJSONAPI;
@class NITCacheManager;
@class NITConfiguration;
@class NITTrackManager;
@class NITRecipeHistory;
@class NITRecipeValidationFilter;

extern NSString* _Nonnull const RecipesCacheKey;

@protocol NITRecipesManaging <NSObject>

- (void)setRecipesWithJsonApi:(NITJSONAPI* _Nullable)json;
- (BOOL)gotPulseWithPulsePlugin:(NSString* _Nonnull)pulsePlugin pulseAction:(NSString* _Nonnull)pulseAction pulseBundle:(NSString* _Nullable)pulseBundle;
- (BOOL)gotPulseWithPulsePlugin:(NSString* _Nonnull)pulsePlugin pulseAction:(NSString* _Nonnull)pulseAction tags:(NSArray<NSString*>* _Nullable)tags;
- (void)gotPulseOnlineWithPulsePlugin:(NSString* _Nonnull)pulsePlugin pulseAction:(NSString* _Nonnull)pulseAction pulseBundle:(NSString* _Nullable)pulseBundle;

@end

@interface NITRecipesManager : NSObject<NITRecipesManaging>

@property (nonatomic, strong) id<NITManaging> _Nullable manager;

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager* _Nonnull)cacheManager networkManager:(id<NITNetworkManaging> _Nonnull)networkManager configuration:(NITConfiguration* _Nonnull)configuration trackManager:(NITTrackManager* _Nonnull)trackManager recipeHistory:(NITRecipeHistory* _Nonnull)recipeHistory recipeValidationFilter:(NITRecipeValidationFilter* _Nonnull)recipeValidationFilter;

- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)processRecipe:(NSString* _Nonnull)recipeId;
- (void)processRecipe:(NSString* _Nonnull)recipeId completion:(void (^_Nullable)(NITRecipe * _Nullable recipe, NSError * _Nullable error))completionHandler;
- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event;
- (NSInteger)recipesCount;
- (NSArray<NITRecipe *> * _Nullable)recipes;

@end
