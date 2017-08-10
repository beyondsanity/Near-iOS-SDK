//
//  NITTriggerRequest.m
//  NearITSDK
//
//  Created by francesco.leoni on 09/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTriggerRequest.h"
#import "NITUtils.h"

@interface NITTriggerRequest()

@property (nonatomic, strong) NSString *identifier;

@end

@implementation NITTriggerRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.identifier = [NITUtils generateUUID];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[NITTriggerRequest class]]) {
        NITTriggerRequest *request = (NITTriggerRequest*)object;
        if ([request.identifier isEqualToString:self.identifier]) {
            return YES;
        }
    }
    return NO;
}

@end
