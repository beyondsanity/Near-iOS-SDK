//
//  NITTimestampsManager.h
//  NearITSDK
//
//  Created by francesco.leoni on 04/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NITNetworkManaging.h"

@class NITJSONAPI;
@class NITConfiguration;

extern NSTimeInterval const TimestampInvalidTime;

@interface NITTimestampsManager : NSObject

- (instancetype _Nonnull)initWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (instancetype _Nonnull)initWithNetworkManager:(id<NITNetworkManaging> _Nonnull)networkManager configuration:(NITConfiguration* _Nonnull)configuration;
- (void)checkTimestampWithType:(NSString* _Nonnull)type referenceTime:(NSTimeInterval)referenceTime completionHandler:(void (^_Nullable)(BOOL needToSync))completionHandler;
- (NSTimeInterval)timeForType:(NSString* _Nonnull)type;
- (BOOL)needsToUpdateForType:(NSString* _Nonnull)type referenceTime:(NSTimeInterval)referenceTime;

@end
