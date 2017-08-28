//
//  NITRecipeRepository.h
//  NearITSDK
//
//  Created by francesco.leoni on 08/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITCacheManager;
@class NITTimestampsManager;
@class NITDateManager;
@class NITConfiguration;
@class NITRecipeHistory;
@class NITRecipe;
@class NITTimestampsManager;
@class NITRecipesApi;

extern NSString* _Nonnull const RecipesCacheKey;
extern NSString* _Nonnull const RecipesLastEditedTimeCacheKey;

@interface NITRecipeRepository : NSObject

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager* _Nonnull)cacheManager dateManager:(NITDateManager* _Nonnull)dateManager configuration:(NITConfiguration* _Nonnull)configuration recipeHistory:(NITRecipeHistory* _Nonnull)recipeHistory timestampsManager:(NITTimestampsManager* _Nonnull)timestampsManager api:(NITRecipesApi* _Nonnull)api;

- (NSArray<NITRecipe *> * _Nullable)recipes;
- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable))completionHandler;
- (void)syncWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable, BOOL))completionHandler;
- (void)recipesWithCompletionHandler:(void (^_Nullable)(NSArray<NITRecipe *> * _Nullable, NSError * _Nullable))completionHandler;
- (NSInteger)recipesCount;
- (BOOL)isPulseOnlineEvaluationAvaialble;
- (void)addRecipe:(NITRecipe* _Nonnull)recipe;
- (NSArray<NITRecipe*>* _Nonnull)matchingRecipesWithPulsePlugin:(NSString* _Nonnull)pulsePlugin pulseAction:(NSString * _Nonnull)pulseAction pulseBundle:(NSString * _Nonnull)pulseBundle;
- (NSArray<NITRecipe*>* _Nonnull)matchingRecipesWithPulsePlugin:(NSString* _Nonnull)pulsePlugin pulseAction:(NSString * _Nonnull)pulseAction tags:(NSArray<NSString *>* _Nullable)tags;

@end
