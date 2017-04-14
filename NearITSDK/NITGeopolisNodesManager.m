//
//  NITGeopolisNodesManager.m
//  NearITSDK
//
//  Created by Francesco Leoni on 14/04/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITGeopolisNodesManager.h"
#import "NITNode.h"
#import "NITBeaconNode.h"

@interface NITGeopolisNodesManager()

@property (nonatomic, strong) NSMutableArray<NITNode*> *enteredNodes;
@property (nonatomic, strong) NITNode *lastEnteredNode;

@end

@implementation NITGeopolisNodesManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.enteredNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray<NITNode *> *)monitoredNodesOnEnterWithId:(NSString *)nodeId {
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        if ([node isLeaf] && [node isKindOfClass:[NITBeaconNode class]] && node.identifier == nil) { // Is a beacon
            self.lastEnteredNode = node;
            [self.enteredNodes addObject:node.parent];
            return [self statelessMonitoredNodesOnEnterWithId:node.parent.ID];
        } else {
            [self.enteredNodes addObject:node];
            self.lastEnteredNode = node;
        }
    }
    return [self statelessMonitoredNodesOnEnterWithId:nodeId];
}

- (NSArray<NITNode *> *)monitoredNodesOnExitWithId:(NSString *)nodeId {
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        [self.enteredNodes removeObject:node];
        if ([node isLeaf] && [node isKindOfClass:[NITBeaconNode class]] && node.identifier == nil) { // Is a beacon
            return [self statelessMonitoredNodesOnEnterWithId:node.parent.ID];
        } else if (self.lastEnteredNode && self.lastEnteredNode.parent) {
            if ([node isEqual:self.lastEnteredNode]) {
                NSArray<NITNode*> *siblingsEntered = [self sibilingsAreEntered:node];
                if ([siblingsEntered count] > 0) {
                    return [self statelessMonitoredNodesOnEnterWithId:[siblingsEntered lastObject].ID];
                } else {
                    return [self statelessMonitoredNoesOnExitWithId:node.ID];
                }
            } else if ([node isEqual:self.lastEnteredNode.parent] ) {
                [self.enteredNodes removeObjectsInArray:node.children];
                return [self statelessMonitoredNoesOnExitWithId:nodeId];
            } else if ([node.parent isEqual:self.lastEnteredNode.parent]) {
                NSArray<NITNode*> *siblingsEntered = [self sibilingsAreEntered:node];
                if ([siblingsEntered count] > 0) {
                    return [self statelessMonitoredNodesOnEnterWithId:[siblingsEntered lastObject].ID];
                } else {
                    return [self statelessMonitoredNoesOnExitWithId:node.ID];
                }
            }
        } else if (node && node.parent == nil) {
            return [self statelessMonitoredNoesOnExitWithId:node.ID];
        }
    }
    return [NSArray array];
}

- (NSArray<NITNode*>*)sibilingsAreEntered:(NITNode*)node {
    NSMutableArray<NITNode*> *siblings = [[NSMutableArray alloc] init];
    for (NITNode *bro in self.enteredNodes) {
        if ([node.parent isEqual:bro.parent] && ![node isEqual:bro]) {
            [siblings addObject:bro];
        }
    }
    return [NSArray arrayWithArray:siblings];
}

- (NSArray<NITNode *> *)statelessMonitoredNodesOnEnterWithId:(NSString *)nodeId {
    NSMutableArray<NITNode*> *nodes = [[NSMutableArray alloc] init];
    
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        if (![node isKindOfClass:[NITBeaconNode class]] || ![node isLeaf]) {
            NSArray<NITNode*> *siblings = [self siblingsWithNode:node];
            [nodes addObjectsFromArray:siblings];
            if ([node isKindOfClass:[NITBeaconNode class]] && node.identifier) {
                // The child must not be monitored
            } else if (node.children != nil && [node.children count] > 0) {
                [nodes addObjectsFromArray:node.children];
            }
        }
    }
    
    return [NSArray arrayWithArray:nodes];
}

- (NSArray<NITNode*> *)statelessMonitoredNoesOnExitWithId:(NSString*)nodeId {
    NSMutableArray<NITNode*> *nodes = [[NSMutableArray alloc] init];
    
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        if (![node isKindOfClass:[NITBeaconNode class]] || ![node isLeaf]) {
            if (node.parent) {
                NSArray<NITNode*> *siblings = [self siblingsWithNode:node.parent];
                [nodes addObjectsFromArray:siblings];
                [nodes addObjectsFromArray:node.parent.children];
            } else {
                [nodes addObjectsFromArray:[self roots]];
            }
        }
    }
    
    return [NSArray arrayWithArray:nodes];
}

- (NSArray<NITNode *> *)statelessRangedNodesOnEnterWithId:(NSString *)nodeId {
    NSMutableArray<NITNode*> *nodes = [[NSMutableArray alloc] init];
    
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        if (node.identifier && [node isKindOfClass:[NITBeaconNode class]]) {
            [nodes addObject:node];
        }
    }
    
    return [NSArray arrayWithArray:nodes];
}

@end