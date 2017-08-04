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

NSTimeInterval const TimestampInvalidTime = -1;

@interface NITTimestampsManager()

@property (nonatomic, strong) NSArray<NITTimestamp*> *timestamps;

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

- (NSTimeInterval)timeForType:(NSString *)type {
    for (NITTimestamp *timestamp in self.timestamps) {
        if ([timestamp.what.lowercaseString isEqualToString:type.lowercaseString]) {
            return (NSTimeInterval)timestamp.time.doubleValue;
        }
    }
    return TimestampInvalidTime;
}

@end
