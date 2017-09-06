//
//  NITNodeRepository.h
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITNode;
@class NITCacheManager;
@class NITTimestampsManager;
@class NITNodeApi;

@interface NITNodeRepository : NSObject

- (instancetype _Nonnull)initWithCacheManager:(NITCacheManager * _Nonnull)cacheManager timestampsManager:(NITTimestampsManager * _Nonnull)timestampsManager api:(NITNodeApi * _Nonnull)api;

- (void)syncWithCompletionHandler:(void (^_Nonnull)(NSError * _Nullable, BOOL))completionHandler;
- (NSArray<NITRecipe *> * _Nullable)nodes;

@end
