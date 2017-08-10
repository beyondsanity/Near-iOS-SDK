//
//  NITRecipesApi.h
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITNetworkManaging.h"

@class NITConfiguration;
@class NITEvaluationBodyBuilder;
@class NITRecipe;

@interface NITRecipesApi : NSObject

- (instancetype _Nonnull)initWithNetworkManager:(id<NITNetworkManaging> _Nonnull)networkManager configuration:(NITConfiguration* _Nonnull)configuration evaluationBodyBuilder:(NITEvaluationBodyBuilder* _Nonnull)evaluationBodyBuilder;

- (void)processRecipesWithCompletionHandler:(void (^_Nonnull)(NSArray<NITRecipe*>* _Nullable,BOOL, NSError * _Nullable))completionHandler;
- (void)fetchRecipeWithId:(NSString* _Nonnull)recipeId completionHandler:(void (^_Nonnull)(NITRecipe* _Nullable recipe, NSError * _Nullable error))completionHandler;
- (void)evaluateRecipeWithId:(NSString* _Nonnull)recipeId completionHandler:(void (^_Nonnull)(NITRecipe* _Nullable recipe, NSError * _Nullable error))completionHandler;
- (void)onlinePulseEvaluationWithPlugin:(NSString* _Nonnull)plugin action:(NSString* _Nonnull)action bundle:(NSString* _Nonnull)bundle completionHandler:(void (^_Nonnull)(NITRecipe* _Nullable recipe, NSError * _Nullable error))completionHandler;

@end
