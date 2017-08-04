//
//  NITTimestampsManager.h
//  NearITSDK
//
//  Created by francesco.leoni on 04/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NITJSONAPI;

extern NSTimeInterval const TimestampInvalidTime;

@interface NITTimestampsManager : NSObject

- (instancetype _Nonnull)initWithJsonApi:(NITJSONAPI* _Nonnull)jsonApi;
- (NSTimeInterval)timeForType:(NSString* _Nonnull)type;

@end
