//
//  NITGeopolisManager.h
//  NearITSDK
//
//  Created by Francesco Leoni on 15/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITRecipesManager.h"
#import "NITNetworkManaging.h"

@class CLRegion;
@class NITNode;
@class NITGeopolisNodesManager;
@class NITCacheManager;
@class NITNetworkManager;
@class NITConfiguration;
@class CLLocationManager;
@class NITTrackManager;
@class NITDateManager;

extern NSString* _Nonnull const NodeLastEditedTimeCacheKey;
extern NSString* const NodeJSONCacheKey;

@interface NITGeopolisManager : NSObject

@property (nonatomic, weak) id<NITRecipesManaging> _Nullable recipesManager;

- (instancetype _Nonnull)initWithNodesManager:(NITGeopolisNodesManager* _Nonnull)nodesManager cachaManager:(NITCacheManager* _Nonnull)cacheManager networkManager:(id<NITNetworkManaging> _Nonnull)networkManager configuration:(NITConfiguration* _Nonnull)configuration trackManager:(NITTrackManager* _Nonnull)trackManager dateManager:(NITDateManager* _Nonnull)dateManager;

- (void)refreshConfigWithCompletionHandler:(void (^_Nonnull)(NSError * _Nullable error))completionHandler;
- (void)refreshConfigCheckTimeWithCompletionHandler:(void (^_Nullable)(NSError * _Nullable error))completionHandler;
- (BOOL)start;
- (void)stop;
- (BOOL)restart;
- (BOOL)hasCurrentNode;
- (NSArray<NITNode*>* _Nullable)nodes;

@end
