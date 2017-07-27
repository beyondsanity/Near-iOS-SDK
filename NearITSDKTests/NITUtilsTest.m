//
//  NITUtilsTest.m
//  NearITSDK
//
//  Created by Francesco Leoni on 14/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITUtils.h"

#define APIKEY @"eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiI3MDQ4MTU4NDcyZTU0NWU5ODJmYzk5NDcyYmI5MTMyNyIsImlhdCI6MTQ4OTQ5MDY5NCwiZXhwIjoxNjE1NzY2Mzk5LCJkYXRhIjp7ImFjY291bnQiOnsiaWQiOiJlMzRhN2Q5MC0xNGQyLTQ2YjgtODFmMC04MWEyYzkzZGQ0ZDAiLCJyb2xlX2tleSI6ImFwcCJ9fX0.2GvA499N8c1Vui9au7NzUWM8B10GWaha6ASCCgPPlR8"

@interface NITUtilsTest : XCTestCase

@end

@implementation NITUtilsTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testGrabAppId {
    NSString *appId = [NITUtils fetchAppIdFromApiKey:APIKEY];
    XCTAssertGreaterThan([appId length], 0, @"appId is empty");
}

- (void)testWrongAppId {
    NSString *appId = [NITUtils fetchAppIdFromApiKey:@"myApiKey"];
    XCTAssertTrue([appId isEqualToString:@""]);
}

- (void)testBundleIdenfitier {
    XCTAssertNotNil([NSBundle bundleWithIdentifier:@"com.nearit.NearITSDK"]);
}

@end
