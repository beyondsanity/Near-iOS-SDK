//
//  NITNodeApi.h
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITNetworkManaging.h"

@class NITNode;

@interface NITNodeApi : NSObject

- (instancetype _Nonnull)initWithNetworkManager:(id<NITNetworkManaging> _Nonnull)networkManager;

- (void)nodesWithCompletionHandler:(void (^_Nonnull)(NSArray<NITNode *> * _Nullable, NSError * _Nullable))completionHandler;

@end
