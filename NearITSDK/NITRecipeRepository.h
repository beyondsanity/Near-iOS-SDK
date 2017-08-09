//
//  NITRecipeRepository.h
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITNetworkManaging.h"

@class NITCacheManager;
@class NITTimestampsManager;
@class NITDateManager;
@class NITConfiguration;
@class NITRecipeHistory;
@class NITRecipe;
@class NITEvaluationBodyBuilder;
@class NITTimestampsManager;

extern NSString* _Nonnull const RecipesCacheKey;
extern NSString* _Nonnull const RecipesLastEditedTimeCacheKey;

@interface NITRecipeRepository : NSObject

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager* _Nonnull)cacheManager networkManager:(id<NITNetworkManaging> _Nonnull)networkManager dateManager:(NITDateManager* _Nonnull)dateManager configuration:(NITConfiguration* _Nonnull)configuration recipeHistory:(NITRecipeHistory* _Nonnull)recipeHistory evaluationBodyBuilder:(NITEvaluationBodyBuilder* _Nonnull)evaluationBodyBuilder timestampsManager:(NITTimestampsManager* _Nonnull)timestampsManager;

- (NSArray<NITRecipe *> * _Nullable)recipes;
- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable))completionHandler;
- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable))completionHandler;
- (void)recipesWithCompletionHandler:(void (^_Nullable)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler;
- (NSInteger)recipesCount;
- (BOOL)isPulseOnlineEvaluationAvaialble;

@end
