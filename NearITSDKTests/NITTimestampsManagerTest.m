//
//  NITTimestampsManagerTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 04/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITTimestampsManager.h"
#import "NITTimestamp.h"

@interface NITTimestampsManagerTest : NITTestCase

@end

@implementation NITTimestampsManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTimestampsManager {
    NSTimeInterval time = 15000;
    NITJSONAPI *jsonApi = [self makeTimestampsResponseWithTimeInterval:time];
    NITTimestampsManager *manager = [[NITTimestampsManager alloc] initWithJsonApi:jsonApi];
    NSTimeInterval returnedTime = [manager timeForType:@"recipes"];
    XCTAssertTrue(returnedTime == time);
    
    returnedTime = [manager timeForType:@"my-type"];
    XCTAssertTrue(returnedTime == TimestampInvalidTime);
}

@end
