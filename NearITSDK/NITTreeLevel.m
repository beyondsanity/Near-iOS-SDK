//
//  NITTreeLevel.m
//  NearITSDK
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITTreeLevel.h"
#import "NITNode.h"

@interface NITTreeLevel()

@property (nonatomic, strong) NITNode *parent;
@property (nonatomic, strong) NSArray<NITNode*> *children;

@end

@implementation NITTreeLevel

- (instancetype)initWithParent:(NITNode *)parent children:(NSArray<NITNode *> *)children {
    self = [super init];
    if (self) {
        self.parent = parent;
        self.children = children;
    }
    return self;
}

- (BOOL)containsWithId:(NSString *)ID {
    if ([self fetchNodeWithId:ID]) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldConsiderEventWithId:(NSString*)ID event:(NITTreeLevelEvent)event {
    NITNode *node = [self fetchNodeWithId:ID];
    
    if (node == nil) {
        return NO;
    }
    
    if (node == self.parent && event == NITTreeLevelEventEnter) {
        return NO;
    }
    if ([self.children containsObject:node] && event == NITTreeLevelEventExit) {
        return NO;
    }
    
    return YES;
}

- (NITNode*)fetchNodeWithId:(NSString *)ID {
    if (ID == nil) {
        return nil;
    }
    
    if ([self.parent.ID isEqualToString:ID]) {
        return self.parent;
    }
    
    for(NITNode *child in self.children) {
        if ([child.ID isEqualToString:ID]) {
            return child;
        }
    }
    
    return nil;
}

@end
