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

- (void)testFromRecipeId {
    NSString *sampleRecipeId = @"recipe-id";
    NITTrackingInfo *info = [NITTrackingInfo trackingInfoFromRecipeId:sampleRecipeId];
    XCTAssertTrue([info.recipeId isEqualToString:sampleRecipeId]);
}

- (void)testNSCoding {
    NSString *recipeId = @"recipe-id";
    NITTrackingInfo *info = [[NITTrackingInfo alloc] init];
    info.recipeId = recipeId;
    [info addExtraWithObject:@"obj1" key:@"key1"];
    
    NSData *infoData = [NSKeyedArchiver archivedDataWithRootObject:info];
    NITTrackingInfo *loadedInfo = [NSKeyedUnarchiver unarchiveObjectWithData:infoData];
    
    XCTAssertTrue([loadedInfo.recipeId isEqualToString:info.recipeId]);
    XCTAssertTrue([loadedInfo existsExtraForKey:@"key1"]);
    
    [loadedInfo addExtraWithObject:@"obj2" key:@"key2"];
    XCTAssertTrue([loadedInfo existsExtraForKey:@"key2"]);
}

@end
