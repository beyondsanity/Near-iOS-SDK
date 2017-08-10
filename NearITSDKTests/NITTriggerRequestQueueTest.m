//
//  NITTriggerRequestQueueTest.m
//  NearITSDK
//
//  Created by francesco.leoni on 10/08/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NITTestCase.h"
#import "NITTriggerRequestQueue.h"
#import "NITRecipeRepository.h"
#import "NITTriggerRequest.h"
#import <OCMockitoIOS/OCMockitoIOS.h>
#import <OCHamcrestIOS/OCHamcrestIOS.h>

typedef void (^RefreshRecipesBlock) (NSError*);

@interface NITTriggerRequestQueue (Tests)

- (BOOL)isBusy;
- (NSMutableArray<NITTriggerRequest *> *)requests;
- (void)processQueue;

@end

@interface NITTriggerRequestQueueTest : NITTestCase

@property (nonatomic, strong) id<NITTriggerRequestQueueDelegate> delegate;

@end

@implementation NITTriggerRequestQueueTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.delegate = mockProtocol(@protocol(NITTriggerRequestQueueDelegate));
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testQueue {
    NITRecipeRepository *repository = mock([NITRecipeRepository class]);
    __block RefreshRecipesBlock repoBlock;
    [givenVoid([repository refreshConfigCheckTimeWithCompletionHandler:anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
        repoBlock = [invocation mkt_arguments][0];
        return nil;
    }];
    
    NITTriggerRequestQueue *queue = [[NITTriggerRequestQueue alloc] initWithRepository:repository];
    queue.delegate = self.delegate;
    XCTAssertFalse(queue.isBusy);
    XCTAssertTrue(queue.requests.count == 0);
    
    [queue addRequest:[self makeRequest]];
    XCTAssertTrue(queue.isBusy);
    XCTAssertTrue(queue.requests.count == 1);
    
    [queue addRequest:[self makeRequest]];
    XCTAssertTrue(queue.isBusy);
    XCTAssertTrue(queue.requests.count == 2);
    
    repoBlock(nil);
    
    [verifyCount(self.delegate, times(2)) triggerRequestQueue:anything() didFinishWithRequest:anything()];
    XCTAssertFalse(queue.isBusy);
    XCTAssertTrue(queue.requests.count == 0);
    
    [queue processQueue];
    XCTAssertFalse(queue.isBusy);
    XCTAssertTrue(queue.requests.count == 0);
    [verifyCount(repository, times(1)) refreshConfigCheckTimeWithCompletionHandler:anything()];
}

// MARK - Utils

- (NITTriggerRequest*)makeRequest {
    NITTriggerRequest *request = [[NITTriggerRequest alloc] init];
    request.pulseAction = @"action";
    request.pulseBundle = @"bundle";
    request.pulsePlugin = @"plugin";
    return request;
}

@end
