//
//  NITTreeLevelTest.m
//  NearITSDKTests
//
//  Created by francesco.leoni on 06/09/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITTreeLevel.h"
#import "NITNode.h"

#define PARENT_ID @"parentId"
#define CHILD1_ID @"child1Id"
#define CHILD2_ID @"child2Id"
#define CHILD3_ID @"child3Id"

@interface NITTreeLevelTest : NITTestCase

@property (nonatomic, strong) NITNode *parent;
@property (nonatomic, strong) NSArray<NITNode*> *children;

@end

@implementation NITTreeLevelTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.parent = [[NITNode alloc] init];
    self.parent.ID = PARENT_ID;
    
    NITNode *node1 = [[NITNode alloc] init];
    node1.ID = CHILD1_ID;
    NITNode *node2 = [[NITNode alloc] init];
    node2.ID = CHILD2_ID;
    NITNode *node3 = [[NITNode alloc] init];
    node3.ID = CHILD3_ID;
    
    self.children = @[node1, node2, node3];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testContains {
    NITTreeLevel *level = [[NITTreeLevel alloc] initWithParent:self.parent children:self.children];
    
    XCTAssertFalse([level containsWithId:@"myId"]);
    XCTAssertTrue([level containsWithId:PARENT_ID]);
    XCTAssertTrue([level containsWithId:CHILD2_ID]);
    XCTAssertFalse([level containsWithId:nil]);
}

- (void)testShouldConsider {
    NITTreeLevel *level = [[NITTreeLevel alloc] initWithParent:self.parent children:self.children];
    
    XCTAssertFalse([level shouldConsiderEventWithId:nil event:NITTreeLevelEventExit]);
    XCTAssertFalse([level shouldConsiderEventWithId:PARENT_ID event:NITTreeLevelEventEnter]);
    XCTAssertTrue([level shouldConsiderEventWithId:PARENT_ID event:NITTreeLevelEventExit]);
    XCTAssertFalse([level shouldConsiderEventWithId:CHILD2_ID event:NITTreeLevelEventExit]);
    XCTAssertTrue([level shouldConsiderEventWithId:CHILD3_ID event:NITTreeLevelEventEnter]);
}

@end
