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
#import "NITConfiguration.h"
#import "NITNetworkMockManger.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@interface NITTimestampsManagerTest : NITTestCase

@property (nonatomic, strong) NITConfiguration *configuration;

@end

@implementation NITTimestampsManagerTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.configuration = mock([NITConfiguration class]);
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
    
    returnedTime = [manager timeForType:@"unknown-time"];
    XCTAssertTrue(returnedTime == TimestampInvalidTime);
}

- (void)testInvalidTime {
    NSTimeInterval time = 15000;
    NITJSONAPI *jsonApi = [self makeTimestampsResponseWithTimeInterval:time];
    NITTimestampsManager *manager = [[NITTimestampsManager alloc] initWithJsonApi:jsonApi];
    
    XCTAssertTrue([manager needsToUpdateForType:@"unknown-time" referenceTime:20000]);
}

- (void)testIsOlder {
    NSTimeInterval time = 15000;
    NITJSONAPI *jsonApi = [self makeTimestampsResponseWithTimeInterval:time];
    NITTimestampsManager *manager = [[NITTimestampsManager alloc] initWithJsonApi:jsonApi];
    
    XCTAssertFalse([manager needsToUpdateForType:@"geopolis" referenceTime:20000]);
}

- (void)testIsNewer {
    NSTimeInterval time = 15000;
    NITJSONAPI *jsonApi = [self makeTimestampsResponseWithTimeInterval:time];
    NITTimestampsManager *manager = [[NITTimestampsManager alloc] initWithJsonApi:jsonApi];
    
    XCTAssertTrue([manager needsToUpdateForType:@"geopolis" referenceTime:14000]);
}

- (void)testIsEqual {
    NSTimeInterval time = 15000;
    NITJSONAPI *jsonApi = [self makeTimestampsResponseWithTimeInterval:time];
    NITTimestampsManager *manager = [[NITTimestampsManager alloc] initWithJsonApi:jsonApi];
    
    XCTAssertFalse([manager needsToUpdateForType:@"geopolis" referenceTime:15000]);
}

- (void)testCheckTimestampWithType {
    NSTimeInterval time = 15000;
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [self setNetworkMockForTimestampsWithTime:time networkManager:networkManager];
    
    NITTimestampsManager *timestampsManager = [[NITTimestampsManager alloc] initWithNetworkManager:networkManager configuration:self.configuration];
    [timestampsManager checkTimestampWithType:@"recipes" referenceTime:time - 10 completionHandler:^(BOOL needToSync) {
        XCTAssertTrue(needToSync);
    }];
    
    [timestampsManager checkTimestampWithType:@"recipes" referenceTime:time + 10 completionHandler:^(BOOL needToSync) {
        XCTAssertFalse(needToSync);
    }];
}

// MARK: - Utils

- (void)setNetworkMockForTimestampsWithTime:(NSTimeInterval)time networkManager:(NITNetworkMockManger*)networkManager {
    [networkManager setMock:^NITJSONAPI *(NSURLRequest *request) {
        if ([request.URL.absoluteString containsString:@"/timestamps"]) {
            return [self makeTimestampsResponseWithTimeInterval:time];
        }
        return nil;
    } forKey:@"timestamps"];
}

@end
