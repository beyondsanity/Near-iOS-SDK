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
@property (nonatomic, strong) NSArray<NITNode*> *lastExitedNodes;

@end

@implementation NITGeopolisNodesManager

- (instancetype)init {
    self = [super init];
    if (self) {
        self.enteredNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSArray<NITNode*>*)currentNodes {
    return [NSArray arrayWithArray:self.enteredNodes];
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
        if (![self.enteredNodes containsObject:node] && self.lastEnteredNode) {
            return [self statelessMonitoredNodesOnEnterWithId:self.lastEnteredNode.ID];
        }
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
            } else if ([node.parent isEqual:self.lastEnteredNode]) {
                return [self statelessMonitoredNodesOnEnterWithId:self.lastEnteredNode.ID];
            }
        } else if (node && node.parent == nil) {
            NSArray<NITNode*> *rootsEntered = [self rootsEntered:node];
            if ([rootsEntered count] > 0) {
                return [self statelessMonitoredNodesOnEnterWithId:[rootsEntered lastObject].ID];
            } else {
                return [self statelessMonitoredNoesOnExitWithId:node.ID];
            }
        } else if ([node.parent isEqual:self.lastEnteredNode] && self.lastEnteredNode.parent == nil) {
            NSArray<NITNode*> *siblingsEntered = [self sibilingsAreEntered:node];
            if ([siblingsEntered count] > 0) {
                return [self statelessMonitoredNodesOnEnterWithId:[siblingsEntered lastObject].ID];
            } else {
                return [self statelessMonitoredNodesOnEnterWithId:self.lastEnteredNode.ID];
            }
        }
    }
    return [self statelessMonitoredNoesOnExitWithId:node.ID];
}

- (NSArray<NITNode*>*)rangedNodesOnEnterWithId:(NSString*)nodeId {
    NITNode *node = [self nodeWithID:nodeId];
    if (node && [node isKindOfClass:[NITBeaconNode class]]) {
        [self.enteredNodes addObject:node];
        NSMutableArray<NITNode*> *rangers = [[NSMutableArray alloc] init];
        NSArray<NITNode*> *siblings = [self sibilingsAreEntered:node];
        for(NITNode *sibling in siblings) {
            [rangers addObjectsFromArray:[self statelessRangedNodesOnEnterWithId:sibling.ID]];
        }
        [rangers addObjectsFromArray:[self statelessRangedNodesOnEnterWithId:nodeId]];
        return [NSArray arrayWithArray:rangers];
    }
    return [NSArray array];
}

- (NSArray<NITNode*>*)rangedNodesOnExitWithId:(NSString*)nodeId {
    NITNode *node = [self nodeWithID:nodeId];
    if (node && [node isKindOfClass:[NITBeaconNode class]]) {
        [self.enteredNodes removeObject:node];
        NSMutableArray<NITNode*> *rangers = [[NSMutableArray alloc] init];
        NSArray<NITNode*> *siblings = [self sibilingsAreEntered:node];
        for(NITNode *sibling in siblings) {
            [rangers addObjectsFromArray:[self statelessRangedNodesOnEnterWithId:sibling.ID]];
        }
        return [NSArray arrayWithArray:rangers];
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
    
- (NSArray<NITNode*>*)rootsEntered:(NITNode*)node {
    NSMutableArray<NITNode*> *rootsEntered = [[NSMutableArray alloc] init];
    for (NITNode *bro in self.enteredNodes) {
        if (bro.parent == nil && ![node isEqual:bro]) {
            [rootsEntered addObject:bro];
        }
    }
    return [NSArray arrayWithArray:rootsEntered];
}

- (NSArray<NITNode *> *)statelessMonitoredNodesOnEnterWithId:(NSString *)nodeId {
    NSMutableArray<NITNode*> *nodes = [[NSMutableArray alloc] init];
    
    NITNode *node = [self nodeWithID:nodeId];
    if (node != nil) {
        if (![node isKindOfClass:[NITBeaconNode class]] || ![node isLeaf]) {
            NSArray<NITNode*> *siblings = [self siblingsWithNode:node];
            [nodes addObjectsFromArray:siblings];
            if ([node isKindOfClass:[NITBeaconNode class]] && node.identifier) {
                [nodes addObject:node.parent];
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

- (void)clear {
    self.lastEnteredNode = nil;
    [self.enteredNodes removeAllObjects];
}

@end
