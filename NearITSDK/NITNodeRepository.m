//
//  NITNodeRepository.m
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITNodeRepository.h"
#import "NITCacheManager.h"
#import "NITTimestampsManager.h"
#import "NITNodeApi.h"
#import "NITNode.h"

@interface NITNodeRepository()

@property (nonatomic, strong) NSArray<NITNode*> *nodes;
@property (nonatomic, strong) NITCacheManager *cacheManager;
@property (nonatomic, strong) NITTimestampsManager *timestampsManager;
@property (nonatomic, strong) NITNodeApi *api;

@end

@implementation NITNodeRepository

- (instancetype)initWithCacheManager:(NITCacheManager*)cacheManager timestampsManager:(NITTimestampsManager*)timestampsManager api:(NITNodeApi*)api {
    self = [super init];
    if (self) {
        self.cacheManager = cacheManager;
        self.timestampsManager = timestampsManager;
        self.api = api;
    }
    return self;
}

- (void)syncWithCompletionHandler:(void (^)(NSError * _Nullable, BOOL))completionHandler {
    completionHandler(nil, YES);
}

@end
