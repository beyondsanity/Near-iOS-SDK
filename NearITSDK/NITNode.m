//
//  NITNode.m
//  NearITSDK
//
//  Created by Francesco Leoni on 16/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITNode.h"
#import "NITBeaconNode.h"

@implementation NITNode

- (CLRegion *)createRegion {
    return nil;
}

- (BOOL)isLeaf {
    if (self.children == nil || [self.children count] == 0) {
        return YES;
    }
    return NO;
}

- (NSInteger)parentsCount {
    NSInteger count = 0;
    
    NITNode *parent = self.parent;
    while (parent != nil) {
        count++;
        parent = parent.parent;
    }
    
    return count;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Node ID: %@", self.ID];
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[NITNode class]]) {
        NITNode *otherNode = (NITNode*)object;
        if ([self.ID.lowercaseString isEqual:otherNode.ID.lowercaseString]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)typeName {
    return @"Node";
}

@end
