//
//  NITNodeApi.m
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITNodeApi.h"
#import "NITNode.h"

@interface NITNodeApi()

@property (nonatomic, strong) id<NITNetworkManaging> networkManager;

@end

@implementation NITNodeApi

- (instancetype)initWithNetworkManager:(id<NITNetworkManaging>)networkManager {
    self = [super init];
    if (self) {
        self.networkManager = networkManager;
    }
    return self;
}

- (void)nodesWithCompletionHandler:(void (^)(NSArray<NITNode *> * _Nullable, NSError * _Nullable))completionHandler {
    completionHandler(nil, nil);
}

@end
