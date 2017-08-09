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

- (void)testCheckTimestampWithType {
    
    NSTimeInterval time = 15000;
    NITNetworkMockManger *networkManager = [[NITNetworkMockManger alloc] init];
    [self setNetworkMockForTimestampsWithTime:time networkManager:networkManager];
    
    NITTimestampsManager *timestampsManager = [[NITTimestampsManager alloc] initWithNetworkManager:networkManager configuration:self.configuration];
    
    XCTestExpectation *exp1 = [self expectationWithDescription:@"exp1"];
    [timestampsManager checkTimestampWithType:@"recipes" referenceTime:time - 10 completionHandler:^(BOOL needToSync) {
        XCTAssertTrue(needToSync);
        [exp1 fulfill];
    }];
    
    XCTestExpectation *exp2 = [self expectationWithDescription:@"exp2"];
    [timestampsManager checkTimestampWithType:@"recipes" referenceTime:time + 10 completionHandler:^(BOOL needToSync) {
        XCTAssertFalse(needToSync);
        [exp2 fulfill];
    }];
    
    XCTestExpectation *exp3 = [self expectationWithDescription:@"exp3"];
    [timestampsManager checkTimestampWithType:@"recipes" referenceTime:time completionHandler:^(BOOL needToSync) {
        XCTAssertFalse(needToSync);
        [exp3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
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
