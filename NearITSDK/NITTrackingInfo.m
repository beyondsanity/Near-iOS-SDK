//
//  NITTrackingInfo.m
//  NearITSDK
//
//  Created by francesco.leoni on 11/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTrackingInfo.h"

@interface NITTrackingInfo()

@property (nonatomic, strong) NSMutableDictionary<NSString*, id> *extras;
@property (nonatomic, strong) NSString *recipeId;

@end

@implementation NITTrackingInfo

@synthesize recipeId = _recipeId;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.extras = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)addExtraWithObject:(id<NSCoding>)object key:(NSString *)key {
    if ([self existsExtraForKey:key]) {
        return NO;
    }
    [self.extras setObject:object forKey:key];
    return YES;
}

- (void)setRecipeId:(NSString *)recipeId {
    if (_recipeId == nil) {
        _recipeId = recipeId;
    }
}

- (NSDictionary *)extrasDictionary {
    return [NSDictionary dictionaryWithDictionary:self.extras];
}

- (BOOL)existsExtraForKey:(NSString *)key {
    id<NSCoding> savedObj = [self.extras objectForKey:key];
    if (savedObj) {
        return YES;
    }
    return NO;
}

+ (NITTrackingInfo *)trackingInfoFromRecipeId:(NSString *)recipeId {
    NITTrackingInfo *info = [[NITTrackingInfo alloc] init];
    info.recipeId = recipeId;
    return info;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.extras = [aDecoder decodeObjectForKey:@"extras"];
        self.recipeId = [aDecoder decodeObjectForKey:@"recipeId"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.extras forKey:@"extras"];
    [aCoder encodeObject:self.recipeId forKey:@"recipeId"];
}

@end
