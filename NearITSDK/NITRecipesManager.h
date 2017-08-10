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
@class NITRecipeValidationFilter;
@class NITRecipeRepository;
@class NITRecipeTrackSender;
@class NITEvaluationBodyBuilder;
@class NITTriggerRequest;
@class NITRecipesApi;

@protocol NITRecipesManaging <NSObject>

- (void)gotTriggerRequest:(NITTriggerRequest* _Nonnull)request;

@end

@interface NITRecipesManager : NSObject<NITRecipesManaging>

@property (nonatomic, strong) id<NITManaging> _Nullable manager;

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager* _Nonnull)cacheManager networkManager:(id<NITNetworkManaging> _Nonnull)networkManager recipeValidationFilter:(NITRecipeValidationFilter* _Nonnull)recipeValidationFilter repository:(NITRecipeRepository* _Nonnull)repository trackSender:(NITRecipeTrackSender* _Nonnull)trackSender evaluationBodyBuilder:(NITEvaluationBodyBuilder* _Nonnull)evaluationBodyBuilder api:(NITRecipesApi* _Nonnull)api;

- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)recipesWithCompletionHandler:(void (^_Nullable)(NSArray<NITRecipe*>* _Nullable recipes, NSError * _Nullable error))completionHandler;
- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)processRecipe:(NSString* _Nonnull)recipeId;
- (void)processRecipe:(NSString* _Nonnull)recipeId completion:(void (^_Nullable)(NITRecipe * _Nullable recipe, NSError * _Nullable error))completionHandler;
- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event;
- (NSInteger)recipesCount;

@end
