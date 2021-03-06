//
//  NITNodesManager.h
//  NearITSDK
//
//  Created by Francesco Leoni on 16/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <Foundation/Foundation.h>
@class NITNode;
@class NITJSONAPI;
@class NITBeaconNode;
@class CLBeacon;

@interface NITNodesManager : NSObject

- (NSArray<NITNode*>* _Nonnull)setNodesWithJsonApi:(NITJSONAPI* _Nullable)jsonApi;
- (NSArray<NITNode*>* _Nonnull)roots;
- (NITNode* _Nullable)nodeWithID:(NSString* _Nonnull)ID;
- (NSArray<NITNode*>* _Nonnull)siblingsWithNode:(NITNode* _Nonnull)node;
- (NSArray<NITNode*>* _Nonnull)nodes;
- (NITBeaconNode* _Nullable)beaconNodeWithBeacon:(CLBeacon* _Nonnull)beacon inChildren:(NSArray<NITNode*>* _Nullable)children;
- (NSInteger)countSiblingsAndChildrenBeaconNode:(NITNode* _Nonnull)node;
- (NSInteger)countIdentifierBeaconNodeWithNode:(NITNode* _Nonnull)node;

@end
