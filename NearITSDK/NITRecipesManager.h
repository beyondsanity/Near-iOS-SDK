//
//  NITRecipesManager.h
//  NearITSDK
//
//  Created by Francesco Leoni on 20/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITManager.h"

@class NITJSONAPI;
@class NITRecipeValidationFilter;
@class NITRecipeRepository;
@class NITRecipeTrackSender;
@class NITTriggerRequest;
@class NITRecipesApi;
@class NITTriggerRequestQueue;

@protocol NITRecipesManaging <NSObject>

- (void)gotTriggerRequest:(NITTriggerRequest* _Nonnull)request;

@end

@interface NITRecipesManager : NSObject<NITRecipesManaging>

@property (nonatomic, strong) id<NITManaging> _Nullable manager;

- (instancetype _Nonnull)initWithRecipeValidationFilter:(NITRecipeValidationFilter* _Nonnull)recipeValidationFilter repository:(NITRecipeRepository* _Nonnull)repository trackSender:(NITRecipeTrackSender* _Nonnull)trackSender api:(NITRecipesApi* _Nonnull)api requestQueue:(NITTriggerRequestQueue* _Nonnull)requestQueue;

- (void)refreshConfigWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)recipesWithCompletionHandler:(void (^_Nullable)(NSArray<NITRecipe*>* _Nullable recipes, NSError * _Nullable error))completionHandler;
- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (void)processRecipe:(NSString* _Nonnull)recipeId;
- (void)processRecipe:(NSString* _Nonnull)recipeId completion:(void (^_Nullable)(NITRecipe * _Nullable recipe, NSError * _Nullable error))completionHandler;
- (void)sendTrackingWithRecipeId:(NSString * _Nonnull)recipeId event:(NSString* _Nonnull)event;
- (NSInteger)recipesCount;

@end
