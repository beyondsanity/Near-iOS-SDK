//
//  NITReaction.h
//  NearITSDK
//
//  Created by Francesco Leoni on 24/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITCacheManager.h"
#import "NITNetworkManaging.h"

@class NITManager;
@class NITRecipe;

@interface NITReaction : NSObject

@property (nonatomic, strong) NITCacheManager * _Nonnull cacheManager;
@property (nonatomic, strong) id<NITNetworkManaging> _Nonnull networkManager;

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager* _Nonnull)cacheManager networkManager:(id<NITNetworkManaging> _Nonnull)networkManager;

- (NSString* _Nonnull)pluginName;
- (void)contentWithRecipe:(NITRecipe* _Nonnull)recipe completionHandler:(void (^_Nullable)(id _Nullable content, NSError * _Nullable error))handler;
- (void)contentWithReactionBundleId:(NSString* _Nonnull)reactionBundleId recipeId:(NSString* _Nonnull)recipeId completionHandler:(void (^_Nullable)(id _Nullable content, NSError * _Nullable error))handler;
- (id _Nullable)contentWithJsonReactionBundle:(NSDictionary<NSString*, id>* _Nonnull)jsonReactionBundle recipeId:(NSString* _Nonnull)recipeId;
- (void)refreshConfigWithCompletionHandler:(void(^ _Nullable)(NSError * _Nullable error))handler;

@end
