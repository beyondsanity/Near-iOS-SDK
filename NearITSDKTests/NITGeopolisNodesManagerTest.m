//
//  NITGeopolisNodesManagerTest.m
//  NearITSDK
//
//  Created by Francesco Leoni on 01/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITGeopolisNodesManager.h"
#import "NITBeaconNode.h"
#import "NITGeofenceNode.h"

@interface NITGeopolisNodesManager (Tests)

- (void)setNodes:(NSArray<NITNode *> *)nodes;

@end

@interface NITGeopolisNodesManagerTest : NITTestCase

@property (nonatomic, strong) NITGeopolisNodesManager *nodesManager;

@end

@implementation NITGeopolisNodesManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.nodesManager = [[NITGeopolisNodesManager alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLateExitFromRootNotVisited {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NITNode *r1 = [self makeRootNodeWithId:@"R1"];
    NITNode *r2 = [self makeRootNodeWithId:@"R2"];
    NITNode *b1 = [self makeBeaconNodeWithId:@"B1" parent:r1];
    [self makeBeaconNodeWithId:@"B1son" parent:b1];
    
    NSArray<NITNode*> *nodes = [NSArray arrayWithObjects:r1, r2, nil];
    [self.nodesManager setNodes:nodes];
    
    NSArray<NITNode*> *enteredR1 = [self.nodesManager monitoredNodesOnEnterWithId:r1.ID];
    BOOL check = [self checkIfArrayOfNodesContainsIds:@[@"r1", @"r2", @"b1"] array:enteredR1];
    XCTAssertTrue(check);
    
    NSArray<NITNode*> *enteredB1 = [self.nodesManager monitoredNodesOnEnterWithId:b1.ID];
    check = [self checkIfArrayOfNodesContainsIds:@[@"b1", @"b1son"] array:enteredB1];
    XCTAssertTrue(check);
    
    XCTAssertFalse([[self.nodesManager currentNodes] containsObject:r2]);
    XCTAssertTrue([[self.nodesManager currentNodes] containsObject:b1]);
    
    NSArray<NITNode*> *exitedR2 = [self.nodesManager monitoredNodesOnExitWithId:r2.ID];
    check = [self checkIfArrayOfNodesContainsIds:@[@"b1", @"b1son"] array:exitedR2];
    XCTAssertTrue(check);
    check = [self checkIfArrayOfNodesContainsIds:@[@"r1", @"r2"] array:exitedR2];
    XCTAssertFalse(check);
}

// MARK: - Utils

- (NITNode*)makeRootNodeWithId:(NSString*)nodeId {
    NITNode *node = [[NITGeofenceNode alloc] init];
    node.ID = nodeId;
    return node;
}

- (NITBeaconNode*)makeBeaconNodeWithId:(NSString*)nodeId parent:(NITNode*)parent {
    NITBeaconNode *beaconNode = [[NITBeaconNode alloc] init];
    beaconNode.ID = nodeId;
    beaconNode.parent = parent;
    NSMutableArray *mutChildren = [parent.children mutableCopy];
    if (parent.children == nil) {
        mutChildren = [[NSMutableArray alloc] init];
    }
    [mutChildren addObject:beaconNode];
    parent.children = [NSArray arrayWithArray:mutChildren];
    return beaconNode;
}

- (BOOL)checkIfArrayOfNodesContainsIds:(NSArray<NSString*>*)ids array:(NSArray<NITNode*>*)nodes {
    NSInteger trueCount = 0;
    for (NITNode *node in nodes) {
        for(NSString *ID in ids) {
            if ([node.ID.lowercaseString isEqualToString:ID.lowercaseString]) {
                trueCount++;
                break;
            }
        }
    }
    return trueCount == [ids count];
}

@end
