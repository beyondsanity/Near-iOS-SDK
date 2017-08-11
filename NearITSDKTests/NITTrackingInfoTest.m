//
//  NITTrackingInfoTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 11/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITTrackingInfo.h"

@interface NITTrackingInfoTest : NITTestCase

@end

@implementation NITTrackingInfoTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddExtra {
    NITTrackingInfo *info = [[NITTrackingInfo alloc] init];
    
    XCTAssertTrue([info addExtraWithObject:@"obj1" key:@"key1"]);
    XCTAssertFalse([info addExtraWithObject:@"obj2" key:@"key1"]);
    XCTAssertTrue([info addExtraWithObject:@"obj1" key:@"key2"]);
}

- (void)testSetRecipeId {
    NSString *sampleRecipeId = @"recipe-id";
    NSString *newSampleRecipeId = @"new-recipe-id";
    NITTrackingInfo *info = [[NITTrackingInfo alloc] init];
    
    XCTAssertNil(info.recipeId);
    info.recipeId = sampleRecipeId;
    XCTAssertTrue([info.recipeId isEqualToString:sampleRecipeId]);
    info.recipeId = newSampleRecipeId;
    XCTAssertFalse([info.recipeId isEqualToString:newSampleRecipeId]);
}

@end
