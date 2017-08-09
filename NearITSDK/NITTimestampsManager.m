//
//  NITTimestampsManager.m
//  NearITSDK
//
//  Created by francesco.leoni on 04/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTimestampsManager.h"
#import "NITTimestamp.h"
#import "NITJSONAPI.h"
#import "NITConfiguration.h"
#import "NITNetworkProvider.h"

NSTimeInterval const TimestampInvalidTime = -1;

@interface NITTimestampsManager()

@property (nonatomic, strong) NSArray<NITTimestamp*> *timestamps;
@property (nonatomic, strong) id<NITNetworkManaging> networkManager;
@property (nonatomic, strong) NITConfiguration *configuration;

@end

@implementation NITTimestampsManager

- (instancetype)initWithJsonApi:(NITJSONAPI *)jsonApi {
    self = [super init];
    if (self) {
        [jsonApi registerClass:[NITTimestamp class] forType:@"timestamps"];
        self.timestamps = [jsonApi parseToArrayOfObjects];
    }
    return self;
}

- (instancetype)initWithNetworkManager:(id<NITNetworkManaging>)networkManager configuration:(NITConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.networkManager = networkManager;
        self.configuration = configuration;
    }
    return self;
}

- (void)checkTimestampWithType:(NSString *)type referenceTime:(NSTimeInterval)referenceTime completionHandler:(void (^)(BOOL))completionHandler {
    [self.networkManager makeRequestWithURLRequest:[[NITNetworkProvider sharedInstance] timestamps] jsonApicompletionHandler:^(NITJSONAPI * _Nullable json, NSError * _Nullable error) {
        if (error) {
            if (completionHandler) {
                completionHandler(YES);
            }
        } else {
            [json registerClass:[NITTimestamp class] forType:@"timestamps"];
            self.timestamps = [json parseToArrayOfObjects];
            if (completionHandler) {
                completionHandler([self needsToUpdateForType:type referenceTime:referenceTime]);
            }
        }
    }];
}

- (NSTimeInterval)timeForType:(NSString *)type {
    for (NITTimestamp *timestamp in self.timestamps) {
        if ([timestamp.what.lowercaseString isEqualToString:type.lowercaseString]) {
            return (NSTimeInterval)timestamp.time.doubleValue;
        }
    }
    return TimestampInvalidTime;
}

- (BOOL)needsToUpdateForType:(NSString *)type referenceTime:(NSTimeInterval)referenceTime {
    NSTimeInterval time = [self timeForType:type];
    
    if (time == TimestampInvalidTime) {
        return YES;
    }
    
    if (referenceTime == TimestampInvalidTime || time > referenceTime) {
        return YES;
    } else {
        return NO;
    }
}

@end
