//
//  NITTrackingInfo.m
//  NearITSDK
//
//  Created by francesco.leoni on 11/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTrackingInfo.h"

@interface NITTrackingInfo()

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *extras;
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

- (BOOL)addExtraWithObject:(NSString *)object key:(NSString *)key {
    NSString *savedObj = [self.extras objectForKey:key];
    if (savedObj) {
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

@end
